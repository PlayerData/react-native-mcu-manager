# react-native-mcu-manager

MCUMgr DFU from React Native.

## Getting started

`$ npm install @playerdata/react-native-mcu-manager --save`
## Usage
```ts
import McuManager, { ProgressEvent, UploadEvents } from '@playerdata/react-native-mcu-manager';

const onUploadProgress = (progress: ProgressEvent) => {
  console.log("Upload progress: ", progress.bleId, progress.progress);
};

const onUploadStateChanged = (progress: ProgressEvent) => {
  console.log("Upload state change: ", progress.bleId, progress.state);
};

UploadEvents.addListener('uploadProgress', onUploadProgress);
UploadEvents.addListener('uploadStateChanged', onUploadStateChanged);

// bluetoothId is a MAC address on Android, and a UUID on iOS
McuManager.updateDevice(bluetoothId, fileUri)
```
