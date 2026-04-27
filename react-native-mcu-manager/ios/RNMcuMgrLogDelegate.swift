import iOSMcuManagerLibrary
import os

class RNMcuMgrLogDelegate: McuMgrLogDelegate {
  private let logger = Logger(subsystem: "ReactNativeMcuManager", category: "McuMgr")

  func log(_ msg: String, ofCategory category: McuMgrLogCategory, atLevel level: McuMgrLogLevel) {
    if level.rawValue < McuMgrLogLevel.info.rawValue {
      return
    }

    logger.log("\(msg, privacy: .public)")
  }
}
