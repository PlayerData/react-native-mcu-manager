package uk.co.playerdata.reactnativemcumanager

import android.bluetooth.BluetoothAdapter
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
import expo.modules.kotlin.objects.Object
import expo.modules.kotlin.records.Field
import expo.modules.kotlin.records.Record
import io.runtime.mcumgr.ble.McuMgrBleTransport
import io.runtime.mcumgr.exception.McuMgrException
import io.runtime.mcumgr.managers.DefaultManager
import io.runtime.mcumgr.managers.ImageManager
import io.runtime.mcumgr.managers.SettingsManager
import io.runtime.mcumgr.McuMgrCallback
import io.runtime.mcumgr.response.dflt.McuMgrOsResponse
import io.runtime.mcumgr.response.McuMgrResponse
import io.runtime.mcumgr.response.settings.McuMgrSettingsReadResponse
import java.util.Base64

private const val MODULE_NAME = "ReactNativeMcuManager"
private val TAG = "McuManagerModule"

class UpdateOptions : Record {
  @Field val estimatedSwapTime: Int = 0
  @Field val upgradeFileType: Int = 0
  @Field val upgradeMode: Int? = null
}

class ReactNativeMcuManagerModule() : Module() {
  private val upgrades: MutableMap<String, DeviceUpgrade> = mutableMapOf()
  private val context
    get() = requireNotNull(appContext.reactContext) { "React Application Context is null" }

  private fun getTransport(macAddress: String?): McuMgrBleTransport {
    val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    val adapter = bluetoothManager.adapter ?: throw Exception("No bluetooth adapter")

    val device = adapter.getRemoteDevice(macAddress)

    val transport = McuMgrBleTransport(context, device)
    transport.connect(device).timeout(60000).await()

    return transport
  }

  override fun definition() = ModuleDefinition {
    Name(MODULE_NAME)

    AsyncFunction("eraseImage") { macAddress: String?, promise: Promise ->
      try {
        val transport = getTransport(macAddress)

        val imageManager = ImageManager(transport)
        imageManager.erase()

        promise.resolve(null)
      } catch (e: McuMgrException) {
        promise.reject(ReactNativeMcuMgrException.fromMcuMgrException(e))
      }
    }

    Function("createUpgrade") {
        id: String,
        macAddress: String?,
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

    AsyncFunction("cancelUpgrade") { id: String, promise: Promise ->
      val upgrade = upgrades[id]

      if (upgrade == null) {
        promise.reject(CodedException("UPGRADE_ID_MISSING", "Upgrade ID $id not present", null))
        return@AsyncFunction
      }

      upgrade.startUpgrade(promise)
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

    AsyncFunction("readSetting") { macAddress: String, settingName: String, promise: Promise ->
      val transport = getTransport(macAddress)
      val settingsManager = SettingsManager(transport)

      val callback = object: McuMgrCallback<McuMgrSettingsReadResponse> {
          override fun onResponse(response: McuMgrSettingsReadResponse) {
            transport.release()
            promise.resolve(
              Base64.getEncoder().encodeToString(response.`val`)
            )
          }

          override fun onError(error: McuMgrException) {
            transport.release()
            promise.reject(CodedException("READ_FAILED", "Failed to read setting", error))
          }
        }

      settingsManager.read(settingName, callback)
    }

    AsyncFunction("writeSetting") { macAddress: String, settingName: String, valueB64: String, promise: Promise ->
      val transport = getTransport(macAddress)
      val settingsManager = SettingsManager(transport)

      val value = Base64.getDecoder().decode(valueB64)

      val callback = object: McuMgrCallback<McuMgrResponse> {
        override fun onResponse(response: McuMgrResponse) {
          transport.release()
          promise.resolve()
        }

        override fun onError(error: McuMgrException) {
          transport.release()
          promise.reject(CodedException("WRITE_FAILED", "Failed to write setting", error))
        }
      }

      settingsManager.write(settingName, value, callback)
    }

    AsyncFunction("resetDevice") { macAddress: String, promise: Promise ->
      val transport = getTransport(macAddress)
      val manager = DefaultManager(transport)

      val callback = object: McuMgrCallback<McuMgrOsResponse> {
        override fun onResponse(response: McuMgrOsResponse) {
          transport.release()
          promise.resolve()
        }

        override fun onError(error: McuMgrException) {
          transport.release()
          promise.reject(CodedException("RESET_DEVICE_FAILED", "Failed to reset device", error))
        }
      }

      manager.reset(callback)
    }
  }
}
