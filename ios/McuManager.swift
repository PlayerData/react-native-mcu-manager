import os
import CoreBluetooth
import iOSMcuManagerLibrary


@objc(RNMcuManager)
class RNMcuManager: RCTEventEmitter {
    var upgrades: Dictionary<String, DeviceUpgrade>

    override init() {
        self.upgrades = [:]

        super.init()
    }

    @objc override func supportedEvents() -> [String] {
        return [
            "uploadProgress",
            "upgradeStateChanged"
        ]
    }

    @objc
    func eraseImage(_ bleId: String, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        guard let bleUuid = UUID(uuidString: bleId) else {
            let error = NSError(domain: "", code: 200, userInfo: nil)
            return reject("error", "failed to parse uuid", error);
        }

        let bleTransport = McuMgrBleTransport(bleUuid)
        let imageManager = ImageManager(transporter: bleTransport)

        imageManager.erase { (response: McuMgrResponse?, err: Error?) in
            bleTransport.close()

            if (err != nil) {
                reject("ERASE_ERR", err?.localizedDescription, err)
                return
            }

            resolve(nil)
            return
        }
    }

    @objc
    func createUpgrade(_ id: String, bleId: String, updateFileUriString: String, updateOptions: Dictionary<String, Any>) -> Void {
        upgrades[id] = DeviceUpgrade(id: id, bleId: bleId, fileURI: updateFileUriString, options: updateOptions, eventEmitter: self)
    }

    @objc
    func runUpgrade(_ id: String, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        guard let upgrade = self.upgrades[id] else {
            reject("ID_NOT_FOUND", "Upgrade object not found", nil)
            return
        }

        upgrade.startUpgrade(resolver: resolve, rejecter: reject)
    }

    @objc
    func cancelUpgrade(_ id: String) -> Void {
        guard let upgrade = self.upgrades[id] else {
            return
        }

        upgrade.cancel();
    }

    @objc
    func destroyUpgrade(_ id: String) -> Void {
        guard let upgrade = self.upgrades[id] else {
            return
        }

        upgrade.cancel();
        self.upgrades[id] = nil
    }
}
