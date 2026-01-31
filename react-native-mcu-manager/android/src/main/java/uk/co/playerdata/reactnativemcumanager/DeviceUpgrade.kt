package uk.co.playerdata.reactnativemcumanager

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
import io.runtime.mcumgr.dfu.mcuboot.model.ImageSet
import io.runtime.mcumgr.exception.McuMgrException
import io.runtime.mcumgr.image.McuMgrImage
import java.io.IOException

val UpgradeModes =
        mapOf(
            1 to FirmwareUpgradeManager.Mode.TEST_AND_CONFIRM,
            2 to FirmwareUpgradeManager.Mode.CONFIRM_ONLY,
            3 to FirmwareUpgradeManager.Mode.TEST_ONLY,
            4 to FirmwareUpgradeManager.Mode.NONE,
        )

enum class UpgradeFileType {
    BIN,
    ZIP,
}

val UpgradeFileTypes = mapOf(
    0 to UpgradeFileType.BIN,
    1 to UpgradeFileType.ZIP,
)

class DeviceUpgrade(
        private val transport: McuMgrBleTransport,
        private val context: Context,
        private val updateFileUri: Uri,
        private val updateOptions: UpdateOptions,
        private val progressCallback: (Int) -> Unit,
        private val stateCallback: (String) -> Unit
) : FirmwareUpgradeCallback<FirmwareUpgradeManager.State> {
    private val TAG = "DeviceUpdate"
    private var lastNotification = -1
    private var dfuManager = FirmwareUpgradeManager(transport, this)
    private var unsafePromise: Promise? = null
    private var promiseComplete = false

    init {
        dfuManager.setCallbackOnUiThread(false)
    }

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

    private fun uriToByteArray(uri: Uri): ByteArray? {
        val inputStream = context.contentResolver.openInputStream(uri) ?: return null
        return inputStream.use { it.readBytes() }
    }

    private fun extractImagesFrom(updateBundleUri: Uri, upgradeFileType: UpgradeFileType): ImageSet {
        val binData = uriToByteArray(updateBundleUri) ?: throw IOException("Failed to read update file")

        return when (upgradeFileType) {
            UpgradeFileType.BIN -> extractImagesFromBinFile(binData)
            UpgradeFileType.ZIP -> extractImagesFromZipFile(binData)
        }
    }

    private fun extractImagesFromBinFile(binData: ByteArray): ImageSet {
        // Check if the BIN file is valid.
        McuMgrImage.getHash(binData)

        val binaries = ImageSet()
        binaries.add(binData)

        return binaries
    }

    private fun extractImagesFromZipFile(zipData: ByteArray): ImageSet {
        return ZipPackage(zipData).getBinaries()
    }

    private fun doUpdate(updateBundleUri: Uri) {
        val eraseAppSettings = updateOptions.eraseAppSettings
        val estimatedSwapTime = updateOptions.estimatedSwapTime * 1000
        val modeInt = updateOptions.upgradeMode ?: 1
        val mcubootBufferCount = updateOptions.mcubootBufferCount
        val upgradeFileType = UpgradeFileTypes[updateOptions.upgradeFileType] ?: UpgradeFileType.BIN
        val upgradeMode = UpgradeModes[modeInt] ?: FirmwareUpgradeManager.Mode.TEST_AND_CONFIRM

        val settings = Settings.Builder()
            .setEstimatedSwapTime(estimatedSwapTime)
            .setEraseAppSettings(eraseAppSettings)
            .setWindowCapacity(mcubootBufferCount)
            .build()

        try {
            val images = extractImagesFrom(updateBundleUri, upgradeFileType)

            dfuManager.setMode(upgradeMode)
            dfuManager.start(images, settings)
        } catch (e: IOException) {
            e.printStackTrace()
            disconnectDevice()
            withSafePromise { promise -> promise.reject(CodedException(e)) }
        } catch (e: McuMgrException) {
            e.printStackTrace()
            disconnectDevice()
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
        stateCallback(newState.name)
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
            progressCallback(progressPercent)
        }
    }
}
