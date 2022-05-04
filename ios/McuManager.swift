import os
import CoreBluetooth


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
