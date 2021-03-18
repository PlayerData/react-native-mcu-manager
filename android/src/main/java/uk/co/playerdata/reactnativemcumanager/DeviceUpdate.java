package uk.co.playerdata.reactnativemcumanager;

import android.bluetooth.BluetoothDevice;
import android.net.Uri;
import android.util.Log;

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
    private final String TAG = "DeviceUpdate";
    private final BluetoothDevice device;
    private final Promise promise;
    private final ReactApplicationContext context;
    private final Uri updateFileUri;
    private final McuManagerModule manager;
    private FirmwareUpgradeManager dfuManager;
    private int LastNotification = -1;
    private McuMgrTransport transport;
    private Boolean noFailures = true;

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

    public void cancel() {
        this.dfuManager.cancel();
        this.disconnectDevice();
        this.promise.reject("Update cancelled");
        this.manager.unsetUpdate();
    }

    public void disconnectDevice() {
        if (this.transport != null) {
            this.transport.release();
        }
    }

    private void doUpdate(Uri updateBundleUri) {
        this.transport = new McuMgrBleTransport(this.context, device);
        this.dfuManager = new FirmwareUpgradeManager(this.transport, this);

        try {
            InputStream stream = context.getContentResolver().openInputStream(updateBundleUri);

            byte[] imageData = new byte[(int) stream.available()];
            stream.read(imageData);

            this.dfuManager.setMode(FirmwareUpgradeManager.Mode.TEST_AND_CONFIRM);
            this.dfuManager.start(imageData);
        } catch (IOException e) {
            e.printStackTrace();
            this.disconnectDevice();
            this.manager.unsetUpdate();
            this.promise.reject(e);
        } catch (McuMgrException e) {
            e.printStackTrace();
            this.disconnectDevice();
            this.manager.unsetUpdate();
            this.promise.reject(e);
        }
    }


    @Override
    public void onUpgradeStarted(FirmwareUpgradeController controller) {

    }

    @Override
    public void onStateChanged(FirmwareUpgradeManager.State prevState, FirmwareUpgradeManager.State newState) {
        Log.i(TAG, "Leaving state: " + prevState);
        Log.i(TAG, "Entering state: " + newState);
        WritableMap stateMap = Arguments.createMap();

        stateMap.putString("bleId", this.device.getAddress());
        stateMap.putString("state", newState.name());
        this.manager.updateStateCB(stateMap);
    }

    @Override
    public void onUpgradeCompleted() {
        this.manager.unsetUpdate();
        this.disconnectDevice();
        this.promise.resolve(null);
    }

    @Override
    public void onUpgradeFailed(FirmwareUpgradeManager.State state, McuMgrException error) {
        if (state == FirmwareUpgradeManager.State.RESET && noFailures) {
            Log.w(TAG, "experienced first time failure in reset state");
            //assume the device has taken slightly longer to come back up and has dropped bluetooth connection the first time this happens
            noFailures = false;
            this.disconnectDevice();
            try {
                Thread.sleep(4000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            doUpdate(updateFileUri);
            return;
        }
        Log.e(TAG,"failed while in state: " + state);
        Log.e(TAG,"with error: " + error);
        this.manager.unsetUpdate();
        this.disconnectDevice();
        this.promise.reject(error);
    }

    @Override
    public void onUpgradeCanceled(FirmwareUpgradeManager.State state) {
        this.manager.unsetUpdate();
        this.disconnectDevice();
        this.promise.reject("Update cancelled");
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
