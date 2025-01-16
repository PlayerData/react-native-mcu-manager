import CoreBluetooth
import ExpoModulesCore
import iOSMcuManagerLibrary
import os

private let MODULE_NAME = "ReactNativeMcuManager"
private let TAG = "McuManagerModule"

public class ReactNativeMcuManagerModule: Module {
  private var upgrades: [String: DeviceUpgrade] = [:]

  public func definition() -> ModuleDefinition {
    Name(MODULE_NAME)

    AsyncFunction("eraseImage") { (bleId: String, promise: Promise) in
      guard let bleUuid = UUID(uuidString: bleId) else {
        promise.reject(Exception(name: "UUIDParseError", description: "Failed to parse UUID"))
        return
      }

      let bleTransport = McuMgrBleTransport(bleUuid)
      let imageManager = ImageManager(transport: bleTransport)

      imageManager.erase { (response: McuMgrResponse?, err: Error?) in
        bleTransport.close()

        if err != nil {
          promise.reject(Exception(name: "EraseError", description: err!.localizedDescription))
          return
        }

        promise.resolve(nil)
        return
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

    AsyncFunction("resetDevice") { (bleId: String, promise: Promise) in
      guard let bleUuid = UUID(uuidString: bleId) else {
        promise.reject(Exception(name: "UUIDParseError", description: "Failed to parse UUID"))
        return
      }

      let bleTransport = McuMgrBleTransport(bleUuid)
      let manager = DefaultManager(transport: bleTransport)

      manager.reset { (response: McuMgrResponse?, err: Error?) in
        bleTransport.close()

        if err != nil {
          promise.reject(Exception(name: "ResetError", description: err!.localizedDescription))
          return
        }

        let smpErr = response?.getError()
        if (smpErr != nil) {
          promise.reject(Exception(name: "ResetError", description: smpErr!.localizedDescription))
          return
        }

        promise.resolve()
      }
    }
  }
}
