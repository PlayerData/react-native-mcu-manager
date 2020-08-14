package com.reactlibrary;

import android.app.Activity;
import android.bluetooth.BluetoothDevice;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;

import java.io.IOException;
import java.io.InputStream;

import io.runtime.mcumgr.McuMgrTransport;
import io.runtime.mcumgr.ble.McuMgrBleTransport;
import io.runtime.mcumgr.dfu.FirmwareUpgradeCallback;
import io.runtime.mcumgr.dfu.FirmwareUpgradeController;
import io.runtime.mcumgr.dfu.FirmwareUpgradeManager;
import io.runtime.mcumgr.exception.McuMgrException;

public class DeviceUpdate implements FirmwareUpgradeCallback {
    private final BluetoothDevice device;
    private final Promise promise;
    private final ReactApplicationContext context;
    private final Uri updateFileUri;
    private final McuManagerModule manager;
    private int LastNotification = -1;

    public DeviceUpdate(BluetoothDevice device, Promise promise, ReactApplicationContext context, Uri updateFileUri, McuManagerModule manager) {
        this.device = device;
        this.promise = promise;
        this.context = context;
        this.updateFileUri = updateFileUri;
        this.manager = manager;
    }

    public void startUpdate() {
        doUpdate(updateFileUri);
    }

    private void doUpdate(Uri updateBundleUri) {
        McuMgrTransport transport = new McuMgrBleTransport(this.context, device);
        FirmwareUpgradeManager dfuManager = new FirmwareUpgradeManager(transport, this);

        try {
            InputStream stream = context.getContentResolver().openInputStream(updateBundleUri);

            byte[] imageData = new byte[(int) stream.available()];
            stream.read(imageData);

            dfuManager.setMode(FirmwareUpgradeManager.Mode.TEST_AND_CONFIRM);
            dfuManager.start(imageData);
        } catch (IOException e) {
            e.printStackTrace();
            this.promise.reject(e);
        } catch (McuMgrException e) {
            e.printStackTrace();
            this.promise.reject(e);
        }
    }


    @Override
    public void onUpgradeStarted(FirmwareUpgradeController controller) {

    }

    @Override
    public void onStateChanged(FirmwareUpgradeManager.State prevState, FirmwareUpgradeManager.State newState) {
        WritableMap stateMap = Arguments.createMap();

        stateMap.putString("bleId", this.device.getAddress());
        stateMap.putString("state", newState.name());
        this.manager.updateStateCB(stateMap);
    }

    @Override
    public void onUpgradeCompleted() {
        this.promise.resolve(null);
    }

    @Override
    public void onUpgradeFailed(FirmwareUpgradeManager.State state, McuMgrException error) {
        this.promise.reject(error);
    }

    @Override
    public void onUpgradeCanceled(FirmwareUpgradeManager.State state) {

    }

    @Override
    public void onUploadProgressChanged(int bytesSent, int imageSize, long timestamp) {
        int progress_percent = bytesSent *100/imageSize;
        if (progress_percent != this.LastNotification) {
            this.LastNotification = progress_percent;
            WritableMap progressMap = Arguments.createMap();

            progressMap.putString("bleId", this.device.getAddress());
            progressMap.putString("progress", String.format("%d", progress_percent, 2));
            this.manager.updateProgressCB(progressMap);
        }
    }
}
