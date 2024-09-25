package uk.co.playerdata.reactnativemcumanager

import android.bluetooth.BluetoothDevice
import android.content.Context
import android.net.Uri
import android.util.Log
import expo.modules.kotlin.Promise
import expo.modules.kotlin.exception.CodedException
import io.runtime.mcumgr.ble.McuMgrBleTransport
import io.runtime.mcumgr.dfu.FirmwareUpgradeCallback
import io.runtime.mcumgr.dfu.FirmwareUpgradeController
import io.runtime.mcumgr.dfu.mcuboot.FirmwareUpgradeManager
import io.runtime.mcumgr.dfu.mcuboot.FirmwareUpgradeManager.Settings
import io.runtime.mcumgr.exception.McuMgrException
import java.io.IOException

val UpgradeModes =
        mapOf(
                1 to FirmwareUpgradeManager.Mode.TEST_AND_CONFIRM,
                2 to FirmwareUpgradeManager.Mode.CONFIRM_ONLY,
                3 to FirmwareUpgradeManager.Mode.TEST_ONLY
        )

class DeviceUpgrade(
        private val id: String,
        device: BluetoothDevice,
        private val context: Context,
        private val updateFileUri: Uri,
        private val updateOptions: UpdateOptions,
        private val manager: ReactNativeMcuManagerModule
) : FirmwareUpgradeCallback<FirmwareUpgradeManager.State> {
    private val TAG = "DeviceUpdate"
    private var lastNotification = -1
    private var transport = McuMgrBleTransport(context, device)
    private var dfuManager = FirmwareUpgradeManager(transport, this)
    private var unsafePromise: Promise? = null
    private var promiseComplete = false

    fun startUpgrade(promise: Promise) {
        unsafePromise = promise
        doUpdate(updateFileUri)
    }

    @Synchronized
    fun withSafePromise(block: (promise: Promise) -> Unit) {
        val promise = unsafePromise
        if (promise != null && !promiseComplete) {
            promiseComplete = true
            block(promise)
        }
    }

    fun cancel() {
        dfuManager.cancel()
        disconnectDevice()
        Log.v(this.TAG, "Cancel")
        withSafePromise { promise ->
            promise.reject(CodedException("UPGRADE_CANCELLED", "Upgrade cancelled", null))
        }
    }

    private fun disconnectDevice() {
        transport.release()
    }

    private fun doUpdate(updateBundleUri: Uri) {
        val estimatedSwapTime = updateOptions.estimatedSwapTime * 1000
        val modeInt = updateOptions.upgradeMode ?: 1
        val upgradeMode = UpgradeModes[modeInt] ?: FirmwareUpgradeManager.Mode.TEST_AND_CONFIRM

        val settings = Settings.Builder().setEstimatedSwapTime(estimatedSwapTime).build()

        try {
            val stream = context.contentResolver.openInputStream(updateBundleUri)
            val imageData = ByteArray(stream!!.available())

            stream.read(imageData)

            dfuManager.setMode(upgradeMode)
            dfuManager.start(imageData, settings)
        } catch (e: IOException) {
            e.printStackTrace()
            disconnectDevice()
            Log.v(this.TAG, "IOException")
            withSafePromise { promise -> promise.reject(CodedException(e)) }
        } catch (e: McuMgrException) {
            e.printStackTrace()
            disconnectDevice()
            Log.v(this.TAG, "mcu exception")
            withSafePromise { promise ->
                promise.reject(ReactNativeMcuMgrException.fromMcuMgrException(e))
            }
        }
    }

    override fun onUpgradeStarted(controller: FirmwareUpgradeController) {}

    override fun onStateChanged(
            prevState: FirmwareUpgradeManager.State,
            newState: FirmwareUpgradeManager.State
    ) {
        val stateMap: Map<String, Any?> = mapOf("id" to id, "state" to newState.name)
        manager.upgradeStateCB(stateMap)
    }

    override fun onUpgradeCompleted() {
        disconnectDevice()
        withSafePromise { promise -> promise.resolve(null) }
    }

    override fun onUpgradeFailed(state: FirmwareUpgradeManager.State, error: McuMgrException) {
        disconnectDevice()
        withSafePromise { promise ->
            promise.reject(ReactNativeMcuMgrException.fromMcuMgrException(error))
        }
    }

    override fun onUpgradeCanceled(state: FirmwareUpgradeManager.State) {
        disconnectDevice()
        withSafePromise { promise ->
            promise.reject(CodedException("UPGRADE_CANCELLED", "Upgrade cancelled", null))
        }
    }

    override fun onUploadProgressChanged(bytesSent: Int, imageSize: Int, timestamp: Long) {
        val progressPercent = bytesSent * 100 / imageSize
        if (progressPercent != lastNotification) {
            lastNotification = progressPercent
            val progressMap: Map<String, Any?> = mapOf("id" to id, "progress" to progressPercent)
            manager.updateProgressCB(progressMap)
        }
    }
}
