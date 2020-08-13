import os
import CoreBluetooth


@objc(RNMcuManager)
class RNMcuManager: NSObject {

    override init() {
    }

    @objc
    func updateDevice(macAddress: String, updateFileUriString: String, _ resolve: @escaping RCTPromiseResolveBlock, _ reject: @escaping RCTPromiseRejectBlock) -> Void {
        guard let uuid = UUID(uuidString: macAddress) else {
            let error = NSError(domain: "", code: 200, userInfo: nil)
            return reject("sad", "sad", error);
        }
        do {
            let updater = try DeviceUpdate(deviceUUID: uuid, fileURI: updateFileUriString, resolver: resolve, rejecter: reject)
            updater.startUpdate()
        } catch is Error {
            let error = NSError(domain: "", code: 200, userInfo: nil)
            reject("sad", "sad", error);
            return
        }
    }
}
