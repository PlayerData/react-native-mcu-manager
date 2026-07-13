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

## Android permissions

This library does **not** declare any permissions in its Android manifest. Your app must declare and handle all permissions itself.

For the **full list of required permissions**, runtime handling notes, and **Expo config (`app.json` / `app.config.*`) examples**, see the **Android permissions** section in the package README:  
[`react-native-mcu-manager/README.md`](react-native-mcu-manager/README.md#android-permissions)

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

## Reading image state

`readImageState(bleId)` exposes the SMP image state read, returning one entry
per slot with `image`, `slot`, `version`, `hash` (lowercase hex) and the
`bootable` / `pending` / `confirmed` / `active` / `permanent` flags.

We recommend using it to verify upgrades: the underlying Nordic libraries can
report a `TEST_AND_CONFIRM` upgrade as successful while the image is not
durably confirmed (for example when the confirm did not persist, or when the
device rebooted and reverted before the confirm was sent), in which case
MCUboot boots the previous firmware on the device's next reboot. After an
upgrade in a confirming mode resolves, read the image state and only trust the
update once:

- the primary slot (`image: 0, slot: 0`) reports `active && confirmed` and not
  `pending` — the one state that survives a reboot in swap-with-revert
  bootloaders, and
- no other slot for the same image is `pending` or `permanent` — a staged
  secondary slot means the device is still running the old firmware and will
  only swap on a future boot.

If verification fails, retry the upgrade from the start.

```ts
import { readImageState } from '@playerdata/react-native-mcu-manager';

const slots = await readImageState(bluetoothId);

const primary = slots.find((slot) => slot.image === 0 && slot.slot === 0);
const staged = slots.some(
  (slot) => slot.slot !== 0 && (slot.pending || slot.permanent)
);

const durablyConfirmed =
  primary?.active && primary.confirmed && !primary.pending && !staged;
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
