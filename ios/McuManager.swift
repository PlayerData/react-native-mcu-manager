import os
import CoreBluetooth


@objc(RNMcuManager)
class RNMcuManager: RCTEventEmitter {
    var resolver: RCTPromiseResolveBlock?
    var rejecter: RCTPromiseRejectBlock?
    var updater : DeviceUpdate?
    override init() {
    }

    @objc override func supportedEvents() -> [String] {
        return [
            "uploadProgress",
            "uploadStateChanged"
        ]
    }

    @objc
    func updateDevice(_ macAddress: String, updateFileUriString: String, updateOptions: Dictionary<String, Any>, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        if self.updater != nil {
            let error = NSError(domain: "", code: 200, userInfo: nil)
            return reject("error", "an update is already running", error);
        }
        self.resolver = resolve;
        self.rejecter = reject;
        guard let uuid = UUID(uuidString: macAddress) else {
            self.updater = nil;
            let error = NSError(domain: "", code: 200, userInfo: nil)
            return reject("error", "failed to parse uuid", error);
        }
        guard let url = URL(string: updateFileUriString) else {
            self.updater = nil;
            let error = NSError(domain: "", code: 200, userInfo: nil)
            return reject("error", "failed to parse file uri as url", error);
        }
        do {
            self.updater = try DeviceUpdate(deviceUUID: uuid, fileURI: url, options: updateOptions, eventEmitter: self, manager: self)
            self.updater!.startUpdate()
        } catch {
            self.updater = nil;
            reject("error", "failed to open file", error);
            return
        }
    }

    @objc
    func cancel() {
        if let unwrappedUpdater = self.updater {
            unwrappedUpdater.cancel();
        }
        self.updater = nil;
    }

    func reject(_ code: String, _ message: String, _ error: NSError) {
        self.updater!.releaseFileAndConnection();
        self.updater = nil;
        self.rejecter!(code, message, error);
    }

    func resolve(_ outcome: Bool) {
        self.updater!.releaseFileAndConnection();
        self.updater = nil;
        self.resolver!(outcome);
    }
}
