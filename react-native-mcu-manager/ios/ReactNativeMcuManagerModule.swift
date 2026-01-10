import Combine
import CoreBluetooth
import ExpoModulesCore
import iOSMcuManagerLibrary
import os

private let MODULE_NAME = "ReactNativeMcuManager"
private let TAG = "McuManagerModule"

class DisconnectionObserver: ConnectionObserver {
  private let connectionState = CurrentValueSubject<iOSMcuManagerLibrary.McuMgrTransportState, Never>(iOSMcuManagerLibrary.McuMgrTransportState.disconnected)

  func transport(_ transport: any iOSMcuManagerLibrary.McuMgrTransport, didChangeStateTo state: iOSMcuManagerLibrary.McuMgrTransportState) {
    connectionState.send(state)
  }

  func awaitDisconnect() async throws {
    var stateSink: AnyCancellable?

    defer {
      stateSink?.cancel()
    }

    try await withCheckedThrowingContinuation { continuation in
      stateSink = connectionState.sink { state in
        if state == .disconnected {
          continuation.resume()
        }
      }
    }
  }
}

public class ReactNativeMcuManagerModule: Module {
  private var upgrades: [String: DeviceUpgrade] = [:]

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
      try await disconnectObserver.awaitDisconnect()

      return result
    } catch let error {
      transport.close()
      try await disconnectObserver.awaitDisconnect()

      throw error
    }
  }

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

        return info
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

            continuation.resume()
          }
        }
      }
    }

    Function("createUpgrade") {
      (
        id: String,
        bleId: String,
        updateFileUriString: String,
        updateOptions: UpdateOptions,
        progressCallback: JavaScriptFunction<ExpressibleByNilLiteral>,
        stateCallback: JavaScriptFunction<ExpressibleByNilLiteral>
      ) in
      upgrades[id] = DeviceUpgrade(
        id: id,
        bleId: bleId,
        fileURI: updateFileUriString,
        options: updateOptions,
        progressHandler: { progress in
          self.appContext?.executeOnJavaScriptThread {
            do {
              let _ = try progressCallback.call(id, progress)
            } catch let err {
              print("Failed to call progress callback: \(err.localizedDescription)")
            }
          }
        },
        stateHandler: { state in
          self.appContext?.executeOnJavaScriptThread {
            do {
              let _ = try stateCallback.call(id, state)
            } catch let err {
              print("Failed to call state callback: \(err.localizedDescription)")
            }
          }
        }
      )
    }

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
