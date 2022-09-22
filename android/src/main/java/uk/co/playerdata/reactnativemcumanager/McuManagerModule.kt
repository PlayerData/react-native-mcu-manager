package uk.co.playerdata.reactnativemcumanager

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.net.Uri
import android.util.Log
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule.RCTDeviceEventEmitter
import io.runtime.mcumgr.ble.McuMgrBleTransport
import io.runtime.mcumgr.managers.ImageManager

class McuManagerModule(private val reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {
    private val TAG = "McuManagerModule"
    private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
    private val upgrades: MutableMap<String, DeviceUpgrade> = mutableMapOf()

    override fun getName(): String {
        return "McuManager"
    }

    @ReactMethod
    fun eraseImage(macAddress: String?, promise: Promise) {
        if (this.bluetoothAdapter == null) {
            throw Exception("No bluetooth adapter")
        }

        try {
            val device: BluetoothDevice = bluetoothAdapter.getRemoteDevice(macAddress)

            var transport = McuMgrBleTransport(reactContext, device)
            transport.connect(device).timeout(60000).await()

            val imageManager = ImageManager(transport);
            imageManager.erase()

            promise.resolve(null)
        } catch (e: Throwable) {
            promise.reject(e)
        }
    }

    @ReactMethod
    fun createUpgrade(id: String, macAddress: String?, updateFileUriString: String?, updateOptions: ReadableMap) {
        if (this.bluetoothAdapter == null) {
            throw Exception("No bluetooth adapter")
        }

        if (upgrades.contains(id)){
            throw Exception("Update ID already present")
        }

        val device: BluetoothDevice = bluetoothAdapter.getRemoteDevice(macAddress)
        val updateFileUri = Uri.parse(updateFileUriString)

        val upgrade = DeviceUpgrade(id, device, reactContext, updateFileUri, updateOptions, this)
        this.upgrades[id] = upgrade
    }

    @ReactMethod
    fun runUpgrade(id: String, promise: Promise) {
        if (!upgrades.contains(id)){
            promise.reject(Exception("update ID not present"))
        }

        upgrades[id]!!.startUpgrade(promise)
    }

    @ReactMethod
    fun cancelUpgrade(id: String) {
        if (!upgrades.contains(id)){
            Log.w(this.TAG,"can't cancel update ID ($id} not present")
            return
        }

        upgrades[id]!!.cancel()
    }

    @ReactMethod
    fun destroyUpgrade(id: String) {
        if (!upgrades.contains(id)){
            Log.w(this.TAG,"can't destroy update ID ($id} not present")
            return
        }

        upgrades[id]!!.cancel()
        upgrades.remove(id)
    }

    fun updateProgressCB(progress: WritableMap?) {
        reactContext
                .getJSModule(RCTDeviceEventEmitter::class.java)
                .emit("uploadProgress", progress)
    }

    fun upgradeStateCB(state: WritableMap?) {
        reactContext
                .getJSModule(RCTDeviceEventEmitter::class.java)
                .emit("upgradeStateChanged", state)
    }

    @ReactMethod
    fun addListener(eventName: String) {
        // Keep: Required for RN built in Event Emitter Calls.
    }

    @ReactMethod
    fun removeListeners(count: Integer) {
        // Keep: Required for RN built in Event Emitter Calls.
    }
}
