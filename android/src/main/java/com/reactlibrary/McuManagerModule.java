package com.reactlibrary;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.net.Uri;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;

import com.facebook.react.modules.core.DeviceEventManagerModule;

public class McuManagerModule extends ReactContextBaseJavaModule {

    private final ReactApplicationContext reactContext;
    private final BluetoothAdapter bluetoothAdapter;
    DeviceUpdate update;

    public McuManagerModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;

        this.bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
    }

    @Override
    public String getName() {
        return "McuManager";
    }

    @ReactMethod
    public void updateDevice(String macAddress, String updateFileUriString, Promise promise) {
        if this.update == null {
            promise.reject("an update is already running");
        }
        BluetoothDevice device = bluetoothAdapter.getRemoteDevice(macAddress);
        Uri updateFileUri = Uri.parse(updateFileUriString);

        this.update = new DeviceUpdate(device, promise, reactContext, updateFileUri, this);
        this.update.startUpdate();
    }

    @ReactMethod
    public void cancelRunningUpdates() {
        if this.update != null {
            this.update.cancel();
        }
    }

    public void updateProgressCB(WritableMap progress) {
        this.reactContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
            .emit("uploadProgress", progress);
    }

    public void updateStateCB(WritableMap state) {
        this.reactContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
            .emit("uploadStateChanged", state);
    }

    public void unsetUpdate() {
        this.update = null;
    }
}
