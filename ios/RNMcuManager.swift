import os
import CoreBluetooth


@objc(RNMcuManager)
class RNMcuManager: RCTEventEmitter {

    override init() {
    }

    @objc override func supportedEvents() -> [String] {
        return [
            "uploadProgress",
            "uploadStateChanged"
        ]
    }

    @objc
    func updateDevice(_ macAddress: String, updateFileUriString: String, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        guard let uuid = UUID(uuidString: macAddress) else {
            let error = NSError(domain: "", code: 200, userInfo: nil)
            return reject("sad1", "failed to parse uuid", error);
        }
        guard let url = URL(string: updateFileUriString) else {
            let error = NSError(domain: "", code: 200, userInfo: nil)
            return reject("sad1", "failed to parse file uri as url", error);
        }
        do {
            let updater = try DeviceUpdate(deviceUUID: uuid, fileURI: url, resolver: resolve, rejecter: reject, eventEmitter: self)
            updater.startUpdate()
        } catch is Error {
            let error = NSError(domain: "", code: 200, userInfo: nil)
            reject("sad3", "failed to open file", error);
            return
        }
    }
}
