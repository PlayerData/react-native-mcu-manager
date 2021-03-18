import McuManager

class DeviceUpdate{
    let deviceUUID: UUID
    var file : Data?
    var lastNotification : Int
    let logDelegate : McuMgrLogDelegate
    let eventEmitter : RCTEventEmitter
    let manager: RNMcuManager
    var dfuManager: FirmwareUpgradeManager?
    var bleTransport: McuMgrBleTransport?
    var noFailures = true
    var state: FirmwareUpgradeState = FirmwareUpgradeState.none

    init(deviceUUID: UUID, fileURI: URL, eventEmitter: RCTEventEmitter, manager: RNMcuManager) throws {
        self.deviceUUID = deviceUUID
        self.lastNotification = -1
        self.eventEmitter = eventEmitter;
        self.manager = manager;
        let filehandle: FileHandle? = try FileHandle(forReadingFrom: fileURI)
            if filehandle == nil {
                throw NSError(domain: "", code: 200, userInfo: nil)
            } else {
                self.file = Data(filehandle!.availableData)
                filehandle?.closeFile()
        }
        self.logDelegate = UpdateLogDelegate();
    }

    func startUpdate() {
        // Initialize the BLE transporter using a scanned peripheral
        self.bleTransport = McuMgrBleTransport(self.deviceUUID)

        // Initialize the FirmwareUpgradeManager using the transport and a delegate
        self.dfuManager = FirmwareUpgradeManager(transporter: self.bleTransport!, delegate: self)

        self.dfuManager!.logDelegate = self.logDelegate;
        self.dfuManager!.estimatedSwapTime = 20.0;
        // Start the firmware upgrade with the image data
        do {
            try self.dfuManager!.start(data: self.file! as Data)
        } catch {
            let error = NSError(domain: "", code: 200, userInfo: nil)
            self.manager.reject("error", "failed to start upgrade", error);
        }
    }

    func cancel() {
        self.dfuManager!.cancel()
    }

    func releaseFileAndConnection() {
        self.file = nil;
        releaseTransport();
    }

    func releaseTransport(){
        if let transport = self.bleTransport {
            transport.close();
        }
    }
}

class UpdateLogDelegate : McuMgrLogDelegate {
    func log(_ msg: String, ofCategory category: McuMgrLogCategory, atLevel level: McuMgrLogLevel) {
        print(msg);
    }
}

extension DeviceUpdate: FirmwareUpgradeDelegate {

    /// Called when the upgrade has started.
    ///
    /// - parameter controller: The controller that may be used to pause,
    ///   resume or cancel the upgrade.
    func upgradeDidStart(controller: FirmwareUpgradeController) {
        if(self.eventEmitter.bridge != nil) {
            self.eventEmitter.sendEvent(
                withName: "uploadStateChanged", body: [
                    "bleId": self.deviceUUID.description,
                    "state": "started"
                ]
            )
        }
    }

    /// Called when the firmware upgrade state has changed.
    ///
    /// - parameter previousState: The state before the change.
    /// - parameter newState: The new state.
    func upgradeStateDidChange(from previousState: FirmwareUpgradeState, to newState: FirmwareUpgradeState){
        self.state = newState;
        if(self.eventEmitter.bridge != nil) {
            self.eventEmitter.sendEvent(
                withName: "uploadStateChanged", body: [
                    "bleId": self.deviceUUID.description,
                    "state": firmwareEnumToString(e: newState)
                ]
            )
        }
    }

    func firmwareEnumToString(e: FirmwareUpgradeState) -> String{
            switch e {
            case .none:
                return "none"
            case .validate:
                return "validate"
            case .upload:
                return "upload"
            case .test:
                return "test"
            case .reset:
                return "resetting"
            case .confirm:
                return "confirming"
            case .success:
                return "success"
        }
    }

    /// Called when the firmware upgrade has succeeded.
    func upgradeDidComplete(){
       self.manager.resolve(true)
    }
//
//    /// Called when the firmware upgrade has failed.
//    ///
//    /// - parameter state: The state in which the upgrade has failed.
//    /// - parameter error: The error.
    func upgradeDidFail(inState state: FirmwareUpgradeState, with error: Error){
        if (self.state == FirmwareUpgradeState.reset && noFailures) {
            //assume the device has taken slightly longer to come back up and has dropped bluetooth connection the first time this happens
            noFailures = false;
            releaseTransport();
            sleep(4);
            startUpdate();
            return;
        }
        let error = NSError(domain: "", code: 200, userInfo: nil)
        self.manager.reject("error", "upgrade failed",  error);
    }
//
//    /// Called when the firmware upgrade has been cancelled using cancel()
//    /// method. The upgrade may be cancelled only during uploading the image.
//    /// When the image is uploaded, the test and/or confirm commands will be
//    /// sent depending on the mode.
    func upgradeDidCancel(state: FirmwareUpgradeState){
        let error = NSError(domain: "", code: 200, userInfo: nil)
        self.manager.reject("error", "upgrade cancelled", error);
    }

    /// Called when the upload progress has changed.
    ///
    /// - parameter bytesSent: Number of bytes sent so far.
    /// - parameter imageSize: Total number of bytes to be sent.
    /// - parameter timestamp: The time that the successful response packet for
    ///   the progress was received.
    func uploadProgressDidChange(bytesSent: Int, imageSize: Int, timestamp: Date){
        if(self.eventEmitter.bridge != nil) {
            let progress = bytesSent*100/imageSize;
            if (self.lastNotification != progress) {
                self.lastNotification = progress;
                self.eventEmitter.sendEvent(
                    withName: "uploadProgress", body: [
                        "bleId": self.deviceUUID.description,
                        "progress": progress
                    ]
                )
            }
        }
    }
}
