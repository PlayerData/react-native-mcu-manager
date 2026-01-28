# @playerdata/react-native-mcu-manager

React Native Wrappers for MCUMgr's Android / iOS client libraries

# Getting started

## Installation in managed Expo projects

For [managed](https://docs.expo.dev/archive/managed-vs-bare/) Expo projects,
we hope this will Just Work :tm:.

The example app uses Expo Prebuild, so we've some confidence, but let us know
how you get on.

## Installation in bare React Native projects

For bare React Native projects, you must ensure that you have [installed and configured the `expo` package](https://docs.expo.dev/bare/installing-expo-modules/) before continuing.

### Add the package to your pnpm dependencies

```
pnpm install @playerdata/react-native-mcu-manager
```

### Configure for iOS

Run `npx pod-install` after installing the pnpm package.

### Configure for Android

For Android API 30+ location permission configuration, see the [package README](./react-native-mcu-manager/README.md#fixing-location-permission-issues-api-30) for detailed instructions.

## Usage

```ts
import McuManager, {
  UpgradeOptions,
} from '@playerdata/react-native-mcu-manager';

const upgradeOptions: UpgradeOptions = {
  estimatedSwapTime: 30,
};

const onUploadProgress = (progress: number) => {
  console.log('Upload progress: ', progress);
};

const onUploadStateChanged = (state: string) => {
  console.log('Upload state change: ', state);
};

// bluetoothId is a MAC address on Android, and a UUID on iOS
McuManager.updateDevice(
  bluetoothId,
  fileUri,
  upgradeOptions,
  onUploadProgress,
  onUploadStateChanged
);
```

# Contributing

Contributions are very welcome!

There are many examples of expo modules in the expo repo packages like
https://github.com/expo/expo/blob/main/packages/expo-camera/README.md

## Development Workflow

Install dependencies:

```
npm install
```

You should use the example app to test your changes:

```
cd example

npx expo prebuild
```

From the top level of the repo, you can use `npm run open:(ios|android)` to open
the appropriate IDE.

For Swift files, you'll find the source files at `Pods > Development Pods > ReactNativeMcuManager`
in XCode.

For Kotlin, you'll find the source files at `reactnativemcumanager` under `Android` in Android Studio.

Make sure your code passes TypeScript and ESLint. Run the following to verify:

```sh
pnpm run typecheck
pnpm run lint
```

To fix formatting errors, run the following:

```sh
pnpm run typecheck run lint --fix
```

Remember to add unit tests for your change if possible. Run the unit tests by:

```sh
pnpm run typecheck run test
```
