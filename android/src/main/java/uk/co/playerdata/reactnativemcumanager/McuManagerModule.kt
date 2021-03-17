package uk.co.playerdata.reactnativemcumanager

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.net.Uri
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule.RCTDeviceEventEmitter

class McuManagerModule(val reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {
    private val bluetoothAdapter: BluetoothAdapter = BluetoothAdapter.getDefaultAdapter()

    var update: DeviceUpdate? = null

    override fun getName(): String {
        return "McuManager"
    }

    @ReactMethod
    fun updateDevice(macAddress: String?, updateFileUriString: String?, promise: Promise) {
        if (this.update != null) {
            promise.reject("an update is already running")
            return
        }

        val device: BluetoothDevice = bluetoothAdapter.getRemoteDevice(macAddress)
        val updateFileUri = Uri.parse(updateFileUriString)

        var update = DeviceUpdate(device, promise, reactContext, updateFileUri, this)
        this.update = update

        update.startUpdate()
    }

    @ReactMethod
    fun cancel() {
        this.update?.cancel()
        this.update = null
    }

    fun updateProgressCB(progress: WritableMap?) {
        reactContext
                .getJSModule(RCTDeviceEventEmitter::class.java)
                .emit("uploadProgress", progress)
    }

    fun updateStateCB(state: WritableMap?) {
        reactContext
                .getJSModule(RCTDeviceEventEmitter::class.java)
                .emit("uploadStateChanged", state)
    }

    fun unsetUpdate() {
        this.update = null
    }
}
