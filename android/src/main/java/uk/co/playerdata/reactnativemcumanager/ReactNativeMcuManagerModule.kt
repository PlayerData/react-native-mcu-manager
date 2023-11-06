package uk.co.playerdata.reactnativemcumanager

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.net.Uri
import android.util.Log
import expo.modules.kotlin.Promise
import expo.modules.kotlin.exception.CodedException
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import expo.modules.kotlin.records.Field
import expo.modules.kotlin.records.Record
import io.runtime.mcumgr.ble.McuMgrBleTransport
import io.runtime.mcumgr.managers.ImageManager

private const val MODULE_NAME = "ReactNativeMcuManager"
private val TAG = "McuManagerModule"

private const val UPGRADE_STATE_EVENTS = "upgradeStateChanged"
private const val UPLOAD_PROGRESS_EVENTS = "uploadProgressChanged"

class UpdateOptions : Record {
  @Field val estimatedSwapTime: Int = 0
  @Field val upgradeMode: Int? = null
}

class ReactNativeMcuManagerModule : Module() {

  private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
  private val upgrades: MutableMap<String, DeviceUpgrade> = mutableMapOf()
  private val context
    get() = requireNotNull(appContext.reactContext) { "React Application Context is null" }

  override fun definition() = ModuleDefinition {
    Name(MODULE_NAME)

    // Defines event names that the module can send to JavaScript.
    Events(UPGRADE_STATE_EVENTS, UPLOAD_PROGRESS_EVENTS)

    AsyncFunction("eraseImage") { macAddress: String?, promise: Promise ->
      if (this@ReactNativeMcuManagerModule.bluetoothAdapter == null) {
        throw Exception("No bluetooth adapter")
      }

      try {
        val device: BluetoothDevice = bluetoothAdapter.getRemoteDevice(macAddress)

        var transport = McuMgrBleTransport(context, device)
        transport.connect(device).timeout(60000).await()

        val imageManager = ImageManager(transport)
        imageManager.erase()

        promise.resolve(null)
      } catch (e: Throwable) {
        promise.reject(CodedException(e))
      }
    }

    Function("createUpgrade") {
        id: String,
        macAddress: String?,
        updateFileUriString: String?,
        updateOptions: UpdateOptions ->
      if (this@ReactNativeMcuManagerModule.bluetoothAdapter == null) {
        throw Exception("No bluetooth adapter")
      }

      if (upgrades.contains(id)) {
        throw Exception("Update ID already present")
      }

      val device: BluetoothDevice = bluetoothAdapter.getRemoteDevice(macAddress)
      val updateFileUri = Uri.parse(updateFileUriString)

      val upgrade =
          DeviceUpgrade(
              id,
              device,
              context,
              updateFileUri,
              updateOptions,
              this@ReactNativeMcuManagerModule
          )
      this@ReactNativeMcuManagerModule.upgrades[id] = upgrade
    }

    AsyncFunction("runUpgrade") { id: String, promise: Promise ->
      if (!upgrades.contains(id)) {
        promise.reject(CodedException("update ID not present"))
      }

      upgrades[id]!!.startUpgrade(promise)
    }

    AsyncFunction("cancelUpgrade") { id: String, promise: Promise ->
      if (!upgrades.contains(id)) {
        Log.w(TAG, "can't cancel update ID ($id} not present")
        return@AsyncFunction
      }

      upgrades[id]!!.cancel()
    }

    Function("destroyUpgrade") { id: String ->
      if (!upgrades.contains(id)) {
        Log.w(TAG, "can't destroy update ID ($id} not present")
        return@Function
      }

      upgrades[id]!!.cancel()
      upgrades.remove(id)
    }
  }

  fun updateProgressCB(progress: Map<String, Any?>) {
    sendEvent(UPLOAD_PROGRESS_EVENTS, progress)
  }

  fun upgradeStateCB(state: Map<String, Any?>) {
    sendEvent(UPGRADE_STATE_EVENTS, state)
  }
}
