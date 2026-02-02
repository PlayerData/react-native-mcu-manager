# @playerdata/react-native-mcu-manager

React Native Wrappers for MCUMgr's Android / iOS client libraries

# API documentation

- [Documentation for the main branch](https://github.com/expo/expo/blob/main/docs/pages/versions/unversioned/sdk/@playerdata/react-native-mcu-manager.md)
- [Documentation for the latest stable release](https://docs.expo.dev/versions/latest/sdk/@playerdata/react-native-mcu-manager/)

# Installation in managed Expo projects

For [managed](https://docs.expo.dev/archive/managed-vs-bare/) Expo projects, please follow the installation instructions in the [API documentation for the latest stable release](#api-documentation). If you follow the link and there is no documentation available then this library is not yet usable within managed projects &mdash; it is likely to be included in an upcoming Expo SDK release.

# Installation in bare React Native projects

For bare React Native projects, you must ensure that you have [installed and configured the `expo` package](https://docs.expo.dev/bare/installing-expo-modules/) before continuing.

### Add the package to your npm dependencies

```
npm install @playerdata/react-native-mcu-manager
```

### Configure for iOS

Run `npx pod-install` after installing the npm package.

### Configure for Android

**Manifest & permissions:** This library does **not** declare any permissions in its own Android manifest. You must declare and request all required Bluetooth (and, where applicable, location) permissions in your **app’s** manifest and at runtime.

See [Android permissions](#android-permissions) below for the exact permissions and runtime handling.

# Android permissions

This library does **not** declare any permissions in its Android manifest. Your app must declare and handle all permissions itself.

**Required permissions:**

- **Android 12+ (API 31+):** `BLUETOOTH_CONNECT` (for BLE connect). If you also scan for devices, add `BLUETOOTH_SCAN`.
- **API 30 and below:** `BLUETOOTH`, `BLUETOOTH_ADMIN`, `ACCESS_FINE_LOCATION` (use `maxSdkVersion="30"`).
- **API 23 and below:** also `ACCESS_COARSE_LOCATION` (use `maxSdkVersion="23"`).

**What you should do:**

1. **Manifest:** Declare the above permissions in your app’s `AndroidManifest.xml`. The library will not add any.
2. **Runtime:** Request the relevant permissions at runtime before using this module (e.g. `BLUETOOTH_CONNECT` before connecting, `BLUETOOTH_SCAN` before scanning, `ACCESS_FINE_LOCATION` on older Android; `ACCESS_COARSE_LOCATION` on API 23 and below if needed for BLE).
3. **IDE:** The module uses `@RequiresPermission(BLUETOOTH_CONNECT)` for IDE guidance. Location and legacy Bluetooth permissions (see above) are documented in KDoc; ensure your app satisfies them where the API is used.

**If you are using Expo (managed or prebuild):**

- Configure the same Android permissions via your Expo config (`app.json` / `app.config.*`) instead of editing `AndroidManifest.xml` directly, for example:

  ```json
  {
    "expo": {
      "android": {
        "permissions": [
          "ACCESS_FINE_LOCATION",
          "ACCESS_COARSE_LOCATION",
          "BLUETOOTH_SCAN",
          "BLUETOOTH_CONNECT"
        ]
      },
      "ios": {
        "infoPlist": {
          "NSBluetoothAlwaysUsageDescription": "Requires Bluetooth to perform firmware updates."
        }
      }
    }
  }
  ```

# Contributing

Contributions are very welcome! Please refer to guidelines described in the [contributing guide](https://github.com/expo/expo#contributing).
