import McuManager

class DeviceUpdate{
    let resolve: RCTPromiseResolveBlock
    let reject: RCTPromiseRejectBlock
    let deviceUUID: UUID
    let file : Data
    let eventEmitter : RCTEventEmitter

    init(deviceUUID: UUID, fileURI: URL, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock, eventEmitter: RCTEventEmitter) throws {
        self.resolve = resolve
        self.reject = reject
        self.deviceUUID = deviceUUID
        self.eventEmitter = eventEmitter
        try self.file = Data(contentsOf: fileURI)
    }

    func startUpdate() {
        // Initialize the BLE transporter using a scanned peripheral
        let bleTransport = McuMgrBleTransport(self.deviceUUID)

        // Initialize the FirmwareUpgradeManager using the transport and a delegate
        let dfuManager = FirmwareUpgradeManager(transporter: bleTransport, delegate: self)

        // Start the firmware upgrade with the image data
        do {
            try dfuManager.start(data: self.file as Data)
        } catch is Error {
            let error = NSError(domain: "", code: 200, userInfo: nil)
            self.reject("sad5", "failed to start upgrade", error);
        }
    }
}


extension DeviceUpdate: FirmwareUpgradeDelegate {
    /// Called when the upgrade has started.
    ///
    /// - parameter controller: The controller that may be used to pause,
    ///   resume or cancel the upgrade.
    func upgradeDidStart(controller: FirmwareUpgradeController) {

    }

    /// Called when the firmware upgrade state has changed.
    ///
    /// - parameter previousState: The state before the change.
    /// - parameter newState: The new state.
    func upgradeStateDidChange(from previousState: FirmwareUpgradeState, to newState: FirmwareUpgradeState){

    }

    /// Called when the firmware upgrade has succeeded.
    func upgradeDidComplete(){
        self.resolve(true)
    }

    /// Called when the firmware upgrade has failed.
    ///
    /// - parameter state: The state in which the upgrade has failed.
    /// - parameter error: The error.
    func upgradeDidFail(inState state: FirmwareUpgradeState, with error: Error){

            //let error = NSError(domain: "", code: 200, userInfo: nil)
            self.reject("sad7", "upgrade failed", error);
    }

    /// Called when the firmware upgrade has been cancelled using cancel()
    /// method. The upgrade may be cancelled only during uploading the image.
    /// When the image is uploaded, the test and/or confirm commands will be
    /// sent depending on the mode.
    func upgradeDidCancel(state: FirmwareUpgradeState){

            let error = NSError(domain: "", code: 200, userInfo: nil)
            self.reject("sad9", "upgrade canceled", error);
    }

    /// Called whnen the upload progress has changed.
    ///
    /// - parameter bytesSent: Number of bytes sent so far.
    /// - parameter imageSize: Total number of bytes to be sent.
    /// - parameter timestamp: The time that the successful response packet for
    ///   the progress was received.
    func uploadProgressDidChange(bytesSent: Int, imageSize: Int, timestamp: Date){
        if(self.eventEmitter.bridge != nil) {
            self.eventEmitter.sendEvent(
                withName: "uploadProgress", body: bytesSent/imageSize
            )
        }
    }
}
