import ExpoModulesCore
import Foundation
import iOSMcuManagerLibrary
import os

enum JSUpgradeMode: Int {
  case TEST_AND_CONFIRM = 1
  case CONFIRM_ONLY = 2
  case TEST_ONLY = 3
  case UPLOAD_ONLY = 4
}

enum UpgradeFileType: Int {
  case BIN = 0
  case ZIP = 1
}

class DeviceUpgrade {
  private let id: String

  private let bleId: String
  private let fileURI: String
  private let options: UpdateOptions
  private let progressHandler: (Int) -> Void
  private let stateHandler: (String) -> Void

  private var lastProgress: Int
  private let logDelegate: McuMgrLogDelegate

  private struct State {
    var dfuManager: FirmwareUpgradeManager?
    var bleTransport: McuMgrBleTransport?
    var promise: Promise?
  }

  private let state = Mutex(State())

  private enum UpgradeResult {
    case success
    case failure(Exception)
  }

  private func finish(_ result: UpgradeResult) {
    let (promise, transport) = state.withLock { state -> (Promise?, McuMgrBleTransport?) in
      let promise = state.promise.take()
      let transport = state.bleTransport.take()
      state.dfuManager = nil
      return (promise, transport)
    }

    transport?.close()

    guard let promise = promise else { return }

    switch result {
    case .success:
      promise.resolve(nil)
    case .failure(let exception):
      promise.reject(exception)
    }
  }

  init(
    id: String, bleId: String, fileURI: String, options: UpdateOptions,
    progressHandler: @escaping (Int) -> Void,
    stateHandler: @escaping (String) -> Void
  ) {
    self.id = id
    self.bleId = bleId
    self.fileURI = fileURI
    self.options = options
    self.progressHandler = progressHandler
    self.stateHandler = stateHandler

    self.lastProgress = -1
    self.logDelegate = RNMcuMgrLogDelegate()
  }

  func extractImageFrom(from url: URL, upgradeFileType: UpgradeFileType) throws -> [ImageManager.Image] {
    switch upgradeFileType {
    case UpgradeFileType.BIN:
      return try extractImageFromBinFile(from: url)
    case UpgradeFileType.ZIP:
      return try extractImageFromZipFile(from: url)
    }
  }

  func extractImageFromBinFile(from url: URL) throws -> [ImageManager.Image] {
    let binData = try Data(contentsOf: url)
    let binHash = try McuMgrImage(data: binData).hash
    return [ImageManager.Image(image: 0, hash: binHash, data: binData)]
  }

  func extractImageFromZipFile(from url: URL) throws -> [ImageManager.Image] {
    let fileManager = FileManager.default
    let tempDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)

    try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true, attributes: nil)

    defer {
      try? fileManager.removeItem(at: tempDirectory)
    }

    try fileManager.unzipItem(at: url, to: tempDirectory)
    let unzippedURLs = try fileManager.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil, options: [])

    guard let dfuManifestURL = unzippedURLs.first(where: { $0.pathExtension == "json" }) else {
      throw McuMgrPackage.Error.manifestFileNotFound
    }
    let manifest = try McuMgrManifest(from: dfuManifestURL)
    let images = try manifest.files.compactMap { manifestFile -> ImageManager.Image in
      guard let imageURL = unzippedURLs.first(where: { $0.absoluteString.contains(manifestFile.file) }) else {
        throw McuMgrPackage.Error.manifestImageNotFound
      }
      let imageData = try Data(contentsOf: imageURL)
      let imageHash = try McuMgrImage(data: imageData).hash
      return ImageManager.Image(manifestFile, hash: imageHash, data: imageData)
    }

    return images
  }

  func startUpgrade(_ promise: Promise) {
    state.withLock { $0.promise = promise }

    guard let bleUuid = UUID(uuidString: self.bleId) else {
      return promise.reject(Exception(name: "UUIDParseError", description: "Failed to parse UUID"))
    }

    let fileUrl: URL
    if let parsed = URL(string: self.fileURI), parsed.scheme != nil {
      fileUrl = parsed
    } else {
      fileUrl = URL(fileURLWithPath: self.fileURI)
    }

    guard let fileType = UpgradeFileType(rawValue: self.options.upgradeFileType) else {
      return promise.reject(
        Exception(
          name: "InvalidUpgradeFileType",
          description: "Unknown upgradeFileType: \(self.options.upgradeFileType)"))
    }

    do {
      let images = try extractImageFrom(from: fileUrl, upgradeFileType: fileType)

      let transport = McuMgrBleTransport(bleUuid)
      let manager = FirmwareUpgradeManager(transport: transport, delegate: self)
      let stillActive = state.withLock { state -> Bool in
        guard state.promise != nil else { return false }
        state.bleTransport = transport
        state.dfuManager = manager
        return true
      }

      guard stillActive else {
        transport.close()
        return
      }

      let config = FirmwareUpgradeConfiguration(
        estimatedSwapTime: self.options.estimatedSwapTime,
        eraseAppSettings: self.options.eraseAppSettings,
        pipelineDepth: self.options.mcubootBufferCount,
        upgradeMode: self.getMode()
      )

      manager.logDelegate = self.logDelegate

      DispatchQueue.main.async {
        do {
          try manager.start(images: images, using: config)
        } catch {
          self.finish(.failure(UnexpectedException(error)))
        }
      }
    } catch {
      self.finish(.failure(UnexpectedException(error)))
    }
  }

  func cancel() {
    let dfuManager = state.withLock { $0.dfuManager }

    guard let dfuManager = dfuManager else {
      finish(.failure(Exception(name: "UpgradeCancelled", description: "Upgrade cancelled")))
      return
    }

    DispatchQueue.main.async {
      dfuManager.cancel()
    }
  }

  private func getMode() -> FirmwareUpgradeMode {
    if self.options.upgradeMode == nil {
      return FirmwareUpgradeMode.testAndConfirm
    }

    guard let jsMode = JSUpgradeMode(rawValue: self.options.upgradeMode!) else {
      return FirmwareUpgradeMode.testAndConfirm
    }

    switch jsMode {
    case .TEST_AND_CONFIRM:
      return FirmwareUpgradeMode.testAndConfirm
    case .TEST_ONLY:
      return FirmwareUpgradeMode.testOnly
    case .CONFIRM_ONLY:
      return FirmwareUpgradeMode.confirmOnly
    case .UPLOAD_ONLY:
      return FirmwareUpgradeMode.uploadOnly
    }
  }
}

extension DeviceUpgrade: FirmwareUpgradeDelegate {

  /// Called when the upgrade has started.
  ///
  /// - parameter controller: The controller that may be used to pause,
  ///   resume or cancel the upgrade.
  func upgradeDidStart(controller: FirmwareUpgradeController) {
    self.stateHandler("STARTED")
  }

  /// Called when the firmware upgrade state has changed.
  ///
  /// - parameter previousState: The state before the change.
  /// - parameter newState: The new state.
  func upgradeStateDidChange(
    from previousState: FirmwareUpgradeState, to newState: FirmwareUpgradeState
  ) {
    self.stateHandler(firmwareEnumToString(e: newState))
  }

  func firmwareEnumToString(e: FirmwareUpgradeState) -> String {
    switch e {
    case .none:
      return "NONE"
    case .validate:
      return "VALIDATE"
    case .upload:
      return "UPLOAD"
    case .test:
      return "TEST"
    case .reset:
      return "RESET"
    case .confirm:
      return "CONFIRM"
    case .success:
      return "SUCCESS"
    case .requestMcuMgrParameters:
      return "REQUEST_MCU_MGR_PARAMETERS"
    @unknown default:
      return "UNKNOWN"
    }
  }

  /// Called when the firmware upgrade has succeeded.
  func upgradeDidComplete() {
    self.finish(.success)
  }

  /// Called when the firmware upgrade has failed.
  ///
  /// - parameter state: The state in which the upgrade has failed.
  /// - parameter error: The error.
  func upgradeDidFail(inState state: FirmwareUpgradeState, with error: Error) {
    self.finish(.failure(getFirmwareUpgradeException(error)))
  }

  private func getFirmwareUpgradeException(_ error: Error) -> Exception {
    return Exception(
      name: "McuMgr_\(String(describing: error.self))", description: error.localizedDescription)
  }

  /// Called when the firmware upgrade has been cancelled using cancel()
  /// method. The upgrade may be cancelled only during uploading the image.
  /// When the image is uploaded, the test and/or confirm commands will be
  /// sent depending on the mode.
  func upgradeDidCancel(state: FirmwareUpgradeState) {
    self.finish(.failure(Exception(name: "UpgradeCancelled", description: "Upgrade cancelled")))
  }

  /// Called when the upload progress has changed.
  ///
  /// - parameter bytesSent: Number of bytes sent so far.
  /// - parameter imageSize: Total number of bytes to be sent.
  /// - parameter timestamp: The time that the successful response packet for
  ///   the progress was received.
  func uploadProgressDidChange(bytesSent: Int, imageSize: Int, timestamp: Date) {
    let progress = bytesSent * 100 / imageSize

    if self.lastProgress == progress {
      return
    }

    self.lastProgress = progress
    self.progressHandler(progress)
  }
}
