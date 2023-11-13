package uk.co.playerdata.reactnativemcumanager

import expo.modules.kotlin.exception.CodedException
import io.runtime.mcumgr.ble.exception.McuMgrBluetoothDisabledException
import io.runtime.mcumgr.ble.exception.McuMgrDisconnectedException
import io.runtime.mcumgr.ble.exception.McuMgrNotSupportedException
import io.runtime.mcumgr.exception.InsufficientMtuException
import io.runtime.mcumgr.exception.McuMgrCoapException
import io.runtime.mcumgr.exception.McuMgrErrorException
import io.runtime.mcumgr.exception.McuMgrException
import io.runtime.mcumgr.exception.McuMgrTimeoutException

class ReactNativeMcuMgrException
private constructor(code: String, message: String?, cause: Throwable?) :
        CodedException(code, message, cause) {

    companion object {
        private fun getCode(e: McuMgrException): String {
            return when (e) {
                is McuMgrBluetoothDisabledException -> return "MCU_MGR_BLUETOOTH_DISABLED"
                is McuMgrDisconnectedException -> return "MCU_MGR_DISCONNECTED"
                is McuMgrNotSupportedException -> return "MCU_MGR_NOT_SUPPORTED"
                is InsufficientMtuException -> return "MCU_MGR_INSUFFICIENT_MTU"
                is McuMgrCoapException -> return "MCU_MGR_COAP"
                is McuMgrErrorException -> return "MCU_MGR_ERROR_${e.code}"
                is McuMgrTimeoutException -> return "MCU_MGR_TIMEOUT"
                else -> "UNEXPECTED_MCU_MGR_EXCEPTION"
            }
        }

        private fun getMessage(e: McuMgrException): String {
            return when (e) {
                is McuMgrBluetoothDisabledException -> return "Bluetooth disabled"
                is McuMgrDisconnectedException -> return "Device disconnected"
                is McuMgrNotSupportedException -> return "Device not supported by MCUMgr"
                is McuMgrTimeoutException -> return "MCUMgr timeout"
                else -> {
                    if (e.localizedMessage != null) {
                        return e.localizedMessage
                    } else if (e.message != null) {
                        return e.message!!
                    } else {
                        return e.toString()
                    }
                }
            }
        }

        fun fromMcuMgrException(e: McuMgrException): ReactNativeMcuMgrException {
            return ReactNativeMcuMgrException(this.getCode(e), this.getMessage(e), e)
        }
    }
}
