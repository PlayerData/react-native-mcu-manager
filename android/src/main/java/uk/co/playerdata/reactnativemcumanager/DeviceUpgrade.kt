package uk.co.playerdata.reactnativemcumanager

import android.bluetooth.BluetoothDevice
import android.net.Uri
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap
import io.runtime.mcumgr.ble.McuMgrBleTransport
import io.runtime.mcumgr.dfu.FirmwareUpgradeCallback
import io.runtime.mcumgr.dfu.FirmwareUpgradeController
import io.runtime.mcumgr.dfu.FirmwareUpgradeManager
import io.runtime.mcumgr.exception.McuMgrException
import java.io.IOException

val UpgradeModes = mapOf(
    1 to FirmwareUpgradeManager.Mode.TEST_AND_CONFIRM,
    2 to FirmwareUpgradeManager.Mode.CONFIRM_ONLY,
    3 to FirmwareUpgradeManager.Mode.TEST_ONLY
)

class DeviceUpgrade(
    private val id: String,
    device: BluetoothDevice,
    private val context: ReactApplicationContext,
    private val updateFileUri: Uri,
    private val updateOptions: ReadableMap,
    private val manager: McuManagerModule
) : FirmwareUpgradeCallback {

    private var lastNotification = -1
    private var transport = McuMgrBleTransport(context, device)
    private var dfuManager = FirmwareUpgradeManager(transport, this)
    private var promise: Promise? = null

    fun startUpgrade(promise: Promise) {
        this.promise = promise
        doUpdate(updateFileUri)
    }

    fun cancel() {
        dfuManager.cancel()
        disconnectDevice()
        promise?.reject(InterruptedException("Update cancelled"))
    }

    private fun disconnectDevice() {
        transport.release()
    }

    private fun doUpdate(updateBundleUri: Uri) {
        val estimatedSwapTime = updateOptions.getInt("estimatedSwapTime") * 1000
        val modeInt = if (updateOptions.hasKey("upgradeMode"))  updateOptions.getInt("upgradeMode") else 1
        val upgradeMode = UpgradeModes[modeInt] ?: FirmwareUpgradeManager.Mode.TEST_AND_CONFIRM

        dfuManager.setEstimatedSwapTime(estimatedSwapTime)

        try {
            val stream = context.contentResolver.openInputStream(updateBundleUri)
            val imageData = ByteArray(stream!!.available())

            stream.read(imageData)

            dfuManager.setMode(upgradeMode)
            dfuManager.start(imageData)
        } catch (e: IOException) {
            e.printStackTrace()
            disconnectDevice()
            promise?.reject(e)
        } catch (e: McuMgrException) {
            e.printStackTrace()
            disconnectDevice()
            promise?.reject(e)
        }
    }

    override fun onUpgradeStarted(controller: FirmwareUpgradeController) {}

    override fun onStateChanged(prevState: FirmwareUpgradeManager.State, newState: FirmwareUpgradeManager.State) {
        val stateMap = Arguments.createMap()
        stateMap.putString("id", id)
        stateMap.putString("state", newState.name)
        manager.upgradeStateCB(stateMap)
    }

    override fun onUpgradeCompleted() {
        disconnectDevice()
        promise?.resolve(null)
    }

    override fun onUpgradeFailed(state: FirmwareUpgradeManager.State, error: McuMgrException) {
        disconnectDevice()
        promise?.reject(error)
    }

    override fun onUpgradeCanceled(state: FirmwareUpgradeManager.State) {
        disconnectDevice()
        promise?.reject(InterruptedException("Update cancelled"))
    }

    override fun onUploadProgressChanged(bytesSent: Int, imageSize: Int, timestamp: Long) {
        val progressPercent = bytesSent * 100 / imageSize
        if (progressPercent != lastNotification) {
            lastNotification = progressPercent
            val progressMap = Arguments.createMap()
            progressMap.putString("id", id)
            progressMap.putInt("progress", progressPercent)
            manager.updateProgressCB(progressMap)
        }
    }
}
