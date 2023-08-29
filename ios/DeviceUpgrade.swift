import iOSMcuManagerLibrary

enum JSUpgradeMode: Int {
    case TEST_AND_CONFIRM = 1
    case CONFIRM_ONLY = 2
    case TEST_ONLY = 3
}

class DeviceUpgrade {
    private let id: String

    private let bleId: String
    private let fileURI: String
    private let options: Dictionary<String, Any>
    private let eventEmitter : RCTEventEmitter

    private var lastProgress : Int
    private let logDelegate : McuMgrLogDelegate

    private var dfuManager: FirmwareUpgradeManager?
    private var bleTransport: McuMgrBleTransport?

    var upgradeResolver: RCTPromiseResolveBlock?
    var upgradeRejecter: RCTPromiseRejectBlock?

    init(id: String, bleId: String, fileURI: String, options: Dictionary<String, Any>, eventEmitter: RCTEventEmitter) {
        self.id = id
        self.bleId = bleId
        self.fileURI = fileURI
        self.options = options

        self.lastProgress = -1
        self.eventEmitter = eventEmitter;
        self.logDelegate = UpdateLogDelegate();
    }

    func startUpgrade(resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            self.upgradeResolver = resolve
            self.upgradeRejecter = reject

            guard let bleUuid = UUID(uuidString: bleId) else {
                let error = NSError(domain: "", code: 200, userInfo: nil)
                return reject("error", "failed to parse uuid", error);
            }

            guard let fileUrl = URL(string: fileURI) else {
                let error = NSError(domain: "", code: 200, userInfo: nil)
                return reject("error", "failed to parse file uri as url", error);
            }

            do {
                let filehandle = try FileHandle(forReadingFrom: fileUrl)
                let file = Data(filehandle.availableData)
                filehandle.closeFile()

                self.bleTransport = McuMgrBleTransport(bleUuid)
                self.dfuManager = FirmwareUpgradeManager(transporter: self.bleTransport!, delegate: self)

                let estimatedSwapTime: TimeInterval = options["estimatedSwapTime"] as! TimeInterval
                let config = FirmwareUpgradeConfiguration(
                    estimatedSwapTime: estimatedSwapTime
                )

                self.dfuManager!.logDelegate = self.logDelegate
                self.dfuManager!.mode = self.getMode();

                try self.dfuManager!.start(data: file as Data, using: config)
            } catch {
                reject(error.localizedDescription, error.localizedDescription, error)
            }
        }
    }

    func cancel() {
        if let dfuManager = self.dfuManager {
            dfuManager.cancel()
        }

        if let transport = self.bleTransport {
            transport.close()
        }
    }

    private func getMode() -> FirmwareUpgradeMode {
        if self.options["upgradeMode"] == nil {
            return FirmwareUpgradeMode.testAndConfirm
        }

        guard let jsMode = JSUpgradeMode(rawValue: self.options["upgradeMode"] as! Int) else {
            return FirmwareUpgradeMode.testAndConfirm
        }

        switch jsMode {
        case .TEST_AND_CONFIRM:
            return FirmwareUpgradeMode.testAndConfirm
        case .TEST_ONLY:
            return FirmwareUpgradeMode.testOnly
        case .CONFIRM_ONLY:
            return FirmwareUpgradeMode.confirmOnly
        }
    }
}

class UpdateLogDelegate : McuMgrLogDelegate {
    func log(_ msg: String, ofCategory category: McuMgrLogCategory, atLevel level: McuMgrLogLevel) {
        if(level.rawValue < McuMgrLogLevel.info.rawValue) {
            return
        }

        print(msg);
    }
}

extension DeviceUpgrade: FirmwareUpgradeDelegate {

    /// Called when the upgrade has started.
    ///
    /// - parameter controller: The controller that may be used to pause,
    ///   resume or cancel the upgrade.
    func upgradeDidStart(controller: FirmwareUpgradeController) {
        if(self.eventEmitter.bridge != nil) {
            self.eventEmitter.sendEvent(
                withName: "upgradeStateChanged", body: [
                    "id": self.id,
                    "state": "STARTED"
                ]
            )
        }
    }

    /// Called when the firmware upgrade state has changed.
    ///
    /// - parameter previousState: The state before the change.
    /// - parameter newState: The new state.
    func upgradeStateDidChange(from previousState: FirmwareUpgradeState, to newState: FirmwareUpgradeState){
        if(self.eventEmitter.bridge != nil) {
            self.eventEmitter.sendEvent(
                withName: "upgradeStateChanged", body: [
                    "id": self.id,
                    "state": firmwareEnumToString(e: newState)
                ]
            )
        }
    }

    func firmwareEnumToString(e: FirmwareUpgradeState) -> String{
        switch e {
        case .none:
            return "NONE"
        case .validate:
            return "VALIDATE"
        case .upload:
            return "UPLOAD"
        case .test:
            return "TEST"
        case .reset:
            return "RESET"
        case .confirm:
            return "CONFIRM"
        case .success:
            return "SUCCESS"
        case .requestMcuMgrParameters:
            return "REQUEST_MCU_MGR_PARAMETERS"
        default:
            return "UNKNOWN"
        }
    }

    /// Called when the firmware upgrade has succeeded.
    func upgradeDidComplete(){
        self.upgradeResolver!(nil)
    }

    /// Called when the firmware upgrade has failed.
    ///
    /// - parameter state: The state in which the upgrade has failed.
    /// - parameter error: The error.
    func upgradeDidFail(inState state: FirmwareUpgradeState, with error: Error){
        self.upgradeRejecter!("error", error.localizedDescription, error);
    }

    /// Called when the firmware upgrade has been cancelled using cancel()
    /// method. The upgrade may be cancelled only during uploading the image.
    /// When the image is uploaded, the test and/or confirm commands will be
    /// sent depending on the mode.
    func upgradeDidCancel(state: FirmwareUpgradeState){
        let error = NSError(domain: "", code: 200, userInfo: nil)
        self.upgradeRejecter!("error", "upgrade cancelled", error);
    }

    /// Called when the upload progress has changed.
    ///
    /// - parameter bytesSent: Number of bytes sent so far.
    /// - parameter imageSize: Total number of bytes to be sent.
    /// - parameter timestamp: The time that the successful response packet for
    ///   the progress was received.
    func uploadProgressDidChange(bytesSent: Int, imageSize: Int, timestamp: Date){
        if(self.eventEmitter.bridge == nil) {
            return
        }

        let progress = bytesSent * 100 / imageSize;

        if (self.lastProgress == progress) {
            return
        }

        self.lastProgress = progress;
        self.eventEmitter.sendEvent(
            withName: "uploadProgress", body: [
                "id": self.id,
                "progress": progress
            ]
        )
    }
}
