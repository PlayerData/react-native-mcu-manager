import CoreBluetooth
import ExpoModulesCore
import iOSMcuManagerLibrary
import os

private let MODULE_NAME = "ReactNativeMcuManager"
private let TAG = "McuManagerModule"

class DisconnectionObserver: ConnectionObserver {
  private struct State {
    var disconnected = false
    var pendingContinuations: [CheckedContinuation<Void, Never>] = []
  }

  private let state = Mutex(State())

  func transport(_ transport: any iOSMcuManagerLibrary.McuMgrTransport, didChangeStateTo newState: iOSMcuManagerLibrary.McuMgrTransportState) {
    guard newState == .disconnected else { return }

    let continuations = state.withLock { state -> [CheckedContinuation<Void, Never>] in
      guard !state.disconnected else { return [] }
      state.disconnected = true
      let pending = state.pendingContinuations
      state.pendingContinuations = []
      return pending
    }

    for continuation in continuations {
      continuation.resume()
    }
  }

  func awaitDisconnect() async {
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      let resumeNow = state.withLock { state -> Bool in
        if state.disconnected {
          return true
        }
        state.pendingContinuations.append(continuation)
        return false
      }

      if resumeNow {
        continuation.resume()
      }
    }
  }
}

// `@ExpoModule` ignores `@JS` members inside `#if`, so each path declares its own class body.
#if MCU_MANAGER_JS_CLOSURE_ARGS
@ExpoModule("ReactNativeMcuManager")
public class ReactNativeMcuManagerModule: Module {
  private var upgrades: [String: DeviceUpgrade] = [:]

  @JS
  func createUpgrade(
    id: String,
    bleId: String,
    updateFileUriString: String,
    updateOptions: UpdateOptions,
    progressCallback: @escaping @Sendable (String, Int) -> Void,
    stateCallback: @escaping @Sendable (String, String) -> Void
  ) {
    registerUpgrade(
      id: id,
      bleId: bleId,
      fileURI: updateFileUriString,
      options: updateOptions,
      progressHandler: { @Sendable progress in progressCallback(id, progress) },
      stateHandler: { @Sendable state in stateCallback(id, state) }
    )
  }
}
#else
public class ReactNativeMcuManagerModule: Module {
  private var upgrades: [String: DeviceUpgrade] = [:]
}
#endif

extension ReactNativeMcuManagerModule {
  private static let logger = Logger(subsystem: MODULE_NAME, category: TAG)

  // `ExpoModulesJSI` exists from Expo SDK 56, where callbacks arrive as `JavaScriptValue`.
  #if !MCU_MANAGER_JS_CLOSURE_ARGS && canImport(ExpoModulesJSI)
  private typealias UpgradeCallback = JavaScriptValue

  private func invokeUpgradeCallback(
    _ callback: UpgradeCallback, _ first: some JavaScriptRepresentable, _ second: some JavaScriptRepresentable
  ) throws {
    try callback.getFunction().call(arguments: first, second)
  }
  #elseif !MCU_MANAGER_JS_CLOSURE_ARGS
  private typealias UpgradeCallback = JavaScriptFunction<ExpressibleByNilLiteral>

  private func invokeUpgradeCallback(_ callback: UpgradeCallback, _ first: Any, _ second: Any) throws {
    _ = try callback.call(first, second)
  }
  #endif

  private func registerUpgrade(
    id: String,
    bleId: String,
    fileURI: String,
    options: UpdateOptions,
    progressHandler: @escaping (Int) -> Void,
    stateHandler: @escaping (String) -> Void
  ) {
    upgrades[id] = DeviceUpgrade(
      id: id,
      bleId: bleId,
      fileURI: fileURI,
      options: options,
      progressHandler: progressHandler,
      stateHandler: stateHandler
    )
  }

  private func getTransport(bleId: String) throws -> McuMgrBleTransport {
    guard let bleUuid = UUID(uuidString: bleId) else {
      throw Exception(name: "UUIDParseError", description: "Failed to parse UUID")
    }

    let transport = McuMgrBleTransport(bleUuid)

    let logDelegate = RNMcuMgrLogDelegate()
    transport.logDelegate = logDelegate

    return transport
  }

  private func withTransport<T>(bleId: String, _ block: (McuMgrBleTransport) async throws -> T) async throws -> T {
    let transport = try getTransport(bleId: bleId)

    let disconnectObserver = DisconnectionObserver()
    transport.addObserver(disconnectObserver)

    do {
      let result = try await block(transport)

      transport.close()
      await disconnectObserver.awaitDisconnect()

      return result
    } catch let error {
      transport.close()
      await disconnectObserver.awaitDisconnect()

      throw error
    }
  }

  @ModuleDefinitionBuilder
  public func definition() -> ModuleDefinition {
    Name(MODULE_NAME)

    AsyncFunction("bootloaderInfo") { (bleId: String) in
      try await withTransport(bleId: bleId) { (transport: McuMgrBleTransport) in
        let manager = DefaultManager(transport: transport)

        let info = BootloaderInfo()

        let nameResponse: BootloaderInfoResponse = try await withCheckedThrowingContinuation { continuation in
          manager.bootloaderInfo(query: DefaultManager.BootloaderInfoQuery.name) { (nameResponse: BootloaderInfoResponse?, err: Error?) in
            if err != nil {
              continuation.resume(throwing: Exception(name: "BootloaderInfoError", description: err!.localizedDescription))
              return
            }

            guard let nameResponse = nameResponse else {
              continuation.resume(throwing: Exception(name: "BootloaderInfoError", description: "Bootloader name response null, but no error occurred?"))
              return
            }

            continuation.resume(returning: nameResponse)
          }
        }

        info.bootloader = nameResponse.bootloader?.description

        if nameResponse.bootloader != BootloaderInfoResponse.Bootloader.mcuboot {
          info.mode = nameResponse.mode?.rawValue
          info.noDowngrade = nameResponse.noDowngrade

          return info
        }

        let mcubootResponse: BootloaderInfoResponse = try await withCheckedThrowingContinuation { continuation in
          manager.bootloaderInfo(query: DefaultManager.BootloaderInfoQuery.mode) { (mcubootResponse: BootloaderInfoResponse?, err: Error?) in
            if err != nil {
              continuation.resume(throwing: Exception(name: "BootloaderInfoError", description: err!.localizedDescription))
              return
            }

            guard let mcubootResponse = mcubootResponse else {
              continuation.resume(throwing: Exception(name: "BootloaderInfoError", description: "MCUboot response null, but no error occurred?"))
              return
            }

            continuation.resume(returning: mcubootResponse)
          }
        }

        info.mode = mcubootResponse.mode?.rawValue
        info.noDowngrade = mcubootResponse.noDowngrade

        let mcubootParams: McuMgrParametersResponse = try await withCheckedThrowingContinuation { continuation in
          manager.params { (mcubootParams: McuMgrParametersResponse?, err: Error?) in
            if err != nil {
              continuation.resume(throwing: Exception(name: "BootloaderInfoError", description: err!.localizedDescription))
              return
            }

            guard let mcubootParams = mcubootParams else {
              continuation.resume(throwing: Exception(name: "BootloaderInfoError", description: "MCUboot params null, but no error occurred?"))
              return
            }

            continuation.resume(returning: mcubootParams)
          }
        }

        info.bufferCount = mcubootParams.bufferCount
        info.bufferSize = mcubootParams.bufferSize

        return info
      }
    }

    AsyncFunction("readImageState") { (bleId: String) in
      try await withTransport(bleId: bleId) { (transport: McuMgrBleTransport) in
        let imageManager = ImageManager(transport: transport)

        let response: McuMgrImageStateResponse = try await withCheckedThrowingContinuation { continuation in
          imageManager.list { (response: McuMgrImageStateResponse?, err: Error?) in
            if err != nil {
              continuation.resume(throwing: Exception(name: "ReadImageStateError", description: err!.localizedDescription))
              return
            }

            let smpErr = response?.getError()
            if smpErr != nil {
              continuation.resume(throwing: Exception(name: "ReadImageStateError", description: smpErr!.localizedDescription))
              return
            }

            guard let response = response else {
              continuation.resume(throwing: Exception(name: "ReadImageStateError", description: "Image state response null, but no error occurred?"))
              return
            }

            continuation.resume(returning: response)
          }
        }

        return (response.images ?? []).map { slot -> ImageSlotState in
          let state = ImageSlotState()
          state.image = slot.image
          state.slot = slot.slot
          state.version = slot.version
          state.hash = slot.hash.map { String(format: "%02x", $0) }.joined()
          state.bootable = slot.bootable
          state.pending = slot.pending
          state.confirmed = slot.confirmed
          state.active = slot.active
          state.permanent = slot.permanent
          return state
        }
      }
    }

    AsyncFunction("eraseImage") { (bleId: String) in
      try await withTransport(bleId: bleId) { (transport: McuMgrBleTransport) in
        let imageManager = ImageManager(transport: transport)

        let _: Void = try await withCheckedThrowingContinuation { continuation in
          imageManager.erase { (response: McuMgrResponse?, err: Error?) in
            if err != nil {
              continuation.resume(throwing: Exception(name: "EraseError", description: err!.localizedDescription))
              return
            }

            let smpErr = response?.getError()
            if smpErr != nil {
              continuation.resume(throwing: Exception(name: "EraseError", description: smpErr!.localizedDescription))
              return
            }

            continuation.resume()
          }
        }
      }
    }

    #if !MCU_MANAGER_JS_CLOSURE_ARGS
    Function("createUpgrade") {
      (
        id: String,
        bleId: String,
        updateFileUriString: String,
        updateOptions: UpdateOptions,
        progressCallback: UpgradeCallback,
        stateCallback: UpgradeCallback
      ) in
      self.registerUpgrade(
        id: id,
        bleId: bleId,
        fileURI: updateFileUriString,
        options: updateOptions,
        progressHandler: { progress in
          self.appContext?.executeOnJavaScriptThread {
            do {
              try self.invokeUpgradeCallback(progressCallback, id, progress)
            } catch let err {
              Self.logger.error("Failed to call progress callback: \(err.localizedDescription, privacy: .public)")
            }
          }
        },
        stateHandler: { state in
          self.appContext?.executeOnJavaScriptThread {
            do {
              try self.invokeUpgradeCallback(stateCallback, id, state)
            } catch let err {
              Self.logger.error("Failed to call state callback: \(err.localizedDescription, privacy: .public)")
            }
          }
        }
      )
    }
    #endif

    AsyncFunction("runUpgrade") { (id: String, promise: Promise) in
      guard let upgrade = self.upgrades[id] else {
        promise.reject(Exception(name: "UpgradeNotFound", description: "Upgrade object not found"))
        return
      }

      upgrade.startUpgrade(promise)
    }

    Function("cancelUpgrade") { (id: String) in
      guard let upgrade = self.upgrades[id] else {
        return
      }

      upgrade.cancel()
    }

    Function("destroyUpgrade") { (id: String) in
      guard let upgrade = self.upgrades[id] else {
        return
      }

      upgrade.cancel()
      self.upgrades[id] = nil
    }

    AsyncFunction("resetDevice") { (bleId: String) in
      try await withTransport(bleId: bleId) { (transport: McuMgrBleTransport) in
        let manager = DefaultManager(transport: transport)

        let _: Void = try await withCheckedThrowingContinuation { continuation in
          manager.reset { (response: McuMgrResponse?, err: Error?) in
            if err != nil {
              continuation.resume(throwing: Exception(name: "ResetError", description: err!.localizedDescription))
              return
            }

            let smpErr = response?.getError()
            if (smpErr != nil) {
              continuation.resume(throwing: Exception(name: "ResetError", description: smpErr!.localizedDescription))
              return
            }

            continuation.resume()
          }
        }
      }
    }
  }
}
