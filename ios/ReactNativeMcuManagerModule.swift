import CoreBluetooth
import ExpoModulesCore
import iOSMcuManagerLibrary
import os

private let MODULE_NAME = "ReactNativeMcuManager"
private let TAG = "McuManagerModule"
private let UPGRADE_STATE_EVENTS = "upgradeStateChanged"
private let UPLOAD_PROGRESS_EVENTS = "uploadProgress"

public class ReactNativeMcuManagerModule: Module {
    private var upgrades: [String: DeviceUpgrade] = [:]

    public func definition() -> ModuleDefinition {
        Name(MODULE_NAME)

        // Defines event names that the module can send to JavaScript.
        Events(UPGRADE_STATE_EVENTS, UPLOAD_PROGRESS_EVENTS)

        AsyncFunction("eraseImage") { (bleId: String, promise: Promise) in
            guard let bleUuid = UUID(uuidString: bleId) else {
                promise.reject(Exception(name: "UUIDParseError", description: "Failed to parse UUID"))
                return
            }

            let bleTransport = McuMgrBleTransport(bleUuid)
            let imageManager = ImageManager(transporter: bleTransport)

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
                id: String, bleId: String, updateFileUriString: String,
                updateOptions: UpdateOptions
            ) in
            upgrades[id] = DeviceUpgrade(
                id: id, bleId: bleId, fileURI: updateFileUriString, options: updateOptions,
                manager: self
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
    }

    func updateProgress(progress: [String: Any?]) {
        sendEvent(UPLOAD_PROGRESS_EVENTS, progress)
    }

    func updateState(state: [String: Any?]) {
        sendEvent(UPGRADE_STATE_EVENTS, state)
    }
}
