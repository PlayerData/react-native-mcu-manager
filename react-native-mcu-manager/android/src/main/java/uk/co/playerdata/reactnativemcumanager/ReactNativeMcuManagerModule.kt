package uk.co.playerdata.reactnativemcumanager

import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.content.Context
import android.net.Uri
import android.util.Log
import expo.modules.kotlin.Promise
import expo.modules.kotlin.exception.CodedException
import expo.modules.kotlin.jni.JavaScriptFunction
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import expo.modules.kotlin.records.Field
import expo.modules.kotlin.records.Record
import io.runtime.mcumgr.McuMgrCallback
import io.runtime.mcumgr.McuMgrErrorCode
import io.runtime.mcumgr.ble.McuMgrBleTransport
import io.runtime.mcumgr.exception.McuMgrErrorException
import io.runtime.mcumgr.exception.McuMgrException
import io.runtime.mcumgr.managers.DefaultManager
import io.runtime.mcumgr.managers.ImageManager
import io.runtime.mcumgr.response.dflt.McuMgrOsResponse

private const val MODULE_NAME = "ReactNativeMcuManager"
private val TAG = "McuManagerModule"

class UpdateOptions : Record {
  @Field val estimatedSwapTime: Int = 0
  @Field val upgradeFileType: Int = 0
  @Field val upgradeMode: Int? = null
  @Field val eraseAppSettings: Boolean? = false
}

class BootloaderInfo : Record {
  @Field var bootloader: String? = null
  @Field var mode: Int? = null
  @Field var noDowngrade: Boolean = false
}

class ReactNativeMcuManagerModule() : Module() {
  private val MCUBOOT = "MCUboot"

  private val upgrades: MutableMap<String, DeviceUpgrade> = mutableMapOf()
  private val context
    get() = requireNotNull(appContext.reactContext) { "React Application Context is null" }

  private fun getTransport(macAddress: String): McuMgrBleTransport {
    val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    val adapter = bluetoothManager.adapter ?: throw Exception("No bluetooth adapter")
    val device = adapter.getRemoteDevice(macAddress)

    return McuMgrBleTransport(context, device)
  }

  private fun withTransport(macAddress: String, block: (transport: McuMgrBleTransport) -> Unit) {
    val transport = getTransport(macAddress)

    transport.connect(transport.bluetoothDevice).timeout(60000).await()

    try {
      block.invoke(transport)
    } finally {
      transport.release()
    }
  }

  override fun definition() = ModuleDefinition {
    Name(MODULE_NAME)

    AsyncFunction("bootloaderInfo") { macAddress: String, promise: Promise ->
      withTransport(macAddress) { transport ->
        val manager = DefaultManager(transport)
        val info = BootloaderInfo()

        try {
          val nameResult = manager.bootloaderInfo(DefaultManager.BOOTLOADER_INFO_QUERY_BOOTLOADER)
          info.bootloader = nameResult.bootloader
        } catch (ex: McuMgrErrorException) {
          // For consistency with iOS, if the error code is 8 (MGMT_ERR_ENOTSUP), return null
          if (ex.code == McuMgrErrorCode.NOT_SUPPORTED) {
            promise.resolve(info)
            return@withTransport
          }

          throw ex;
        }

        try {
          if (info.bootloader == MCUBOOT) {
            val mcuMgrResult = manager.bootloaderInfo(DefaultManager.BOOTLOADER_INFO_MCUBOOT_QUERY_MODE)

            info.mode = mcuMgrResult.mode
            info.noDowngrade = mcuMgrResult.noDowngrade
          }
        } catch (ex: McuMgrErrorException) {
          // For consistency with iOS, if the error code is 8 (MGMT_ERR_ENOTSUP), return null
          if (ex.code == McuMgrErrorCode.NOT_SUPPORTED) {
            promise.resolve(info)
            return@withTransport
          }

          throw ex;
        }

        promise.resolve(info)
      }
    }

    AsyncFunction("eraseImage") { macAddress: String, promise: Promise ->
      withTransport(macAddress) { transport ->
        try {
          val imageManager = ImageManager(transport)
          imageManager.erase()

          promise.resolve(null)
        } catch (e: McuMgrException) {
          promise.reject(ReactNativeMcuMgrException.fromMcuMgrException(e))
        }
      }
    }

    Function("createUpgrade") {
        id: String,
        macAddress: String,
        updateFileUriString: String?,
        updateOptions: UpdateOptions,
        progressCallback: JavaScriptFunction<Unit>,
        stateCallback: JavaScriptFunction<Unit> ->
      if (upgrades.contains(id)) {
        throw Exception("Update ID already present")
      }

      val transport = getTransport(macAddress)
      val updateFileUri = Uri.parse(updateFileUriString)

      val upgrade = DeviceUpgrade(
        transport,
        context,
        updateFileUri,
        updateOptions,
        { progress ->
          appContext.executeOnJavaScriptThread {
            progressCallback(id, progress)
          }
        },
        { state ->
          appContext.executeOnJavaScriptThread {
            stateCallback(id, state)
          }
        }
      )
      this@ReactNativeMcuManagerModule.upgrades[id] = upgrade
    }

    AsyncFunction("runUpgrade") { id: String, promise: Promise ->
      val upgrade = upgrades[id]

      if (upgrade == null) {
        promise.reject(CodedException("UPGRADE_ID_MISSING", "Upgrade ID $id not present", null))
        return@AsyncFunction
      }

      upgrade.startUpgrade(promise)
    }

    Function("cancelUpgrade") { id: String ->
      val upgrade = upgrades[id]

      if (upgrade == null) {
        Log.w(TAG, "Can't cancel update ID ($id} not present")
        return@Function
      }

      upgrade.cancel()
    }

    Function("destroyUpgrade") { id: String ->
      val upgrade = upgrades[id]

      if (upgrade == null) {
        Log.w(TAG, "Can't destroy update ID ($id} not present")
        return@Function
      }

      upgrade.cancel()
      upgrades.remove(id)
    }

    AsyncFunction("resetDevice") { macAddress: String, promise: Promise ->
      withTransport(macAddress) { transport ->
        val manager = DefaultManager(transport)

        try {
          manager.reset()
          promise.resolve()
        } catch (error: McuMgrException) {
          promise.reject(CodedException("RESET_DEVICE_FAILED", "Failed to reset device", error))
        }
      }
    }
  }
}
