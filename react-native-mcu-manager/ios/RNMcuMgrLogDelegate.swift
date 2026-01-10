import iOSMcuManagerLibrary

class RNMcuMgrLogDelegate: McuMgrLogDelegate {
  func log(_ msg: String, ofCategory category: McuMgrLogCategory, atLevel level: McuMgrLogLevel) {
    if level.rawValue < McuMgrLogLevel.info.rawValue {
      return
    }

    print(msg)
  }
}
