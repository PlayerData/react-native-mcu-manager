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

## Contributing

### Development workflow

To get started with the project, run `yarn` in the root directory to install the required dependencies for each package:

```sh
yarn install
yarn example install
yarn example pods
```

While developing, you can run the [example app](/example/) to test your changes.

To start the packager:

```sh
yarn example start
```

To run the example app on Android:

```sh
yarn example android
```

To run the example app on iOS:

```sh
yarn example ios
```

Make sure your code passes TypeScript and ESLint. Run the following to verify:

```sh
yarn typecheck
yarn lint
```

To fix formatting errors, run the following:

```sh
yarn lint --fix
```

Remember to add tests for your change if possible. Run the unit tests by:

```sh
yarn test
```

To edit the Swift files, open `example/ios/McuManagerExample.xcworkspace` in XCode and find the source files at `Pods > Development Pods > react-native-mcu-manager`.

To edit the Kotlin files, open `example/android` in Android studio and find the source files at `reactnativemcumanager` under `Android`.
