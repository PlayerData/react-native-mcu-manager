import ExpoModulesCore
import iOSMcuManagerLibrary

enum JSUpgradeMode: Int {
  case TEST_AND_CONFIRM = 1
  case CONFIRM_ONLY = 2
  case TEST_ONLY = 3
}

class DeviceUpgrade {
  private let id: String

  private let bleId: String
  private let fileURI: String
  private let options: UpdateOptions
  private let manager: ReactNativeMcuManagerModule

  private var lastProgress: Int
  private let logDelegate: McuMgrLogDelegate

  private var dfuManager: FirmwareUpgradeManager?
  private var bleTransport: McuMgrBleTransport?
  private var promise: Promise?

  init(
    id: String, bleId: String, fileURI: String, options: UpdateOptions,
    manager: ReactNativeMcuManagerModule
  ) {
    self.id = id
    self.bleId = bleId
    self.fileURI = fileURI
    self.options = options

    self.lastProgress = -1
    self.manager = manager
    self.logDelegate = UpdateLogDelegate()
  }

  func extractImageFrom(from url: URL) throws -> [ImageManager.Image] {
    switch url.pathExtension.lowercased() {
    case "bin":
      return try extractImageFromBinFile(from: url)
    case "zip":
      return try extractImageFromZipFile(from: url)
    default:
      throw Exception(name: "UnsupportedFileType", description: "File must be .bin or .zip")
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

    try unzippedURLs.forEach { url in
      try fileManager.removeItem(at: url)
    }

    return images
  }

  func startUpgrade(_ promise: Promise) {
    self.promise = promise

    guard let bleUuid = UUID(uuidString: self.bleId) else {
      return promise.reject(Exception(name: "UUIDParseError", description: "Failed to parse UUID"))
    }

    guard let fileUrl = URL(string: self.fileURI) else {
      return promise.reject(
        Exception(name: "URIParseError", description: "Failed to parse file URI"))
    }

    do {
      let images = try extractImageFrom(from: fileUrl)

      self.bleTransport = McuMgrBleTransport(bleUuid)
      self.dfuManager = FirmwareUpgradeManager(transport: self.bleTransport!, delegate: self)
      let config = FirmwareUpgradeConfiguration(
        estimatedSwapTime: self.options.estimatedSwapTime,
        upgradeMode: self.getMode()
      )

      self.dfuManager!.logDelegate = self.logDelegate

      DispatchQueue.main.async {
        do {
          try self.dfuManager!.start(images: images, using: config)
        } catch {
          promise.reject(UnexpectedException(error))
        }
      }
    } catch {
      promise.reject(UnexpectedException(error))
    }
  }

  func cancel() {
    if let dfuManager = self.dfuManager {
      DispatchQueue.main.async {
        dfuManager.cancel()
      }
    }

    if let transport = self.bleTransport {
      transport.close()
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
    }
  }
}

class UpdateLogDelegate: McuMgrLogDelegate {
  func log(_ msg: String, ofCategory category: McuMgrLogCategory, atLevel level: McuMgrLogLevel) {
    if level.rawValue < McuMgrLogLevel.info.rawValue {
      return
    }

    print(msg)
  }
}

extension DeviceUpgrade: FirmwareUpgradeDelegate {

  /// Called when the upgrade has started.
  ///
  /// - parameter controller: The controller that may be used to pause,
  ///   resume or cancel the upgrade.
  func upgradeDidStart(controller: FirmwareUpgradeController) {
    self.manager.updateState(
      state: [
        "id": self.id,
        "state": "STARTED",
      ]
    )
  }

  /// Called when the firmware upgrade state has changed.
  ///
  /// - parameter previousState: The state before the change.
  /// - parameter newState: The new state.
  func upgradeStateDidChange(
    from previousState: FirmwareUpgradeState, to newState: FirmwareUpgradeState
  ) {
    self.manager.updateState(
      state: [
        "id": self.id,
        "state": firmwareEnumToString(e: newState),
      ]
    )
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
    default:
      return "UNKNOWN"
    }
  }

  /// Called when the firmware upgrade has succeeded.
  func upgradeDidComplete() {
    self.promise!.resolve(nil)
  }

  /// Called when the firmware upgrade has failed.
  ///
  /// - parameter state: The state in which the upgrade has failed.
  /// - parameter error: The error.
  func upgradeDidFail(inState state: FirmwareUpgradeState, with error: Error) {
    self.promise!.reject(getFirmwareUpgradeException(error))
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
    self.promise!.reject(Exception(name: "UpgradeCancelled", description: "Upgrade cancelled"))
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
    self.manager.updateProgress(
      progress: [
        "id": self.id,
        "progress": progress,
      ]
    )
  }
}
