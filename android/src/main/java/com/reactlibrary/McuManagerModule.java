package com.reactlibrary;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.net.Uri;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import com.facebook.react.modules.core.DeviceEventManagerModule;

public class McuManagerModule extends ReactContextBaseJavaModule {

    private final ReactApplicationContext reactContext;
    private final BluetoothAdapter bluetoothAdapter;

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
        BluetoothDevice device = bluetoothAdapter.getRemoteDevice(macAddress);
        Uri updateFileUri = Uri.parse(updateFileUriString);

        DeviceUpdate update = new DeviceUpdate(device, promise, reactContext, updateFileUri, this);
        update.startUpdate();
    }

    public void updateProgressCB(String progress) {
        this.reactContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
            .emit("uploadProgress", progress);
    }
}
