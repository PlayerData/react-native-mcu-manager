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

#### Fixing Location Permission Issues (API 30+)

On Android API 30 and below, Bluetooth usage requires location permissions (`ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION`). On API 30+, Bluetooth permissions changed to `BLUETOOTH_SCAN` and `BLUETOOTH_CONNECT`.

This library's manifest includes location permissions with `maxSdkVersion="30"`. During manifest merging, even if you remove `maxSdkVersion` from your app's manifest, the library's manifest will merge in and reintroduce the `maxSdkVersion` attribute due to [manifest merging rules](https://developer.android.com/build/manage-manifests).

To fix this issue, we provide an Expo plugin that uses `tools:remove` to remove the `maxSdkVersion` attribute from location permissions merged from the library's manifest.

**For Expo projects:**

Add the plugin to the `plugins` array in your project's `app.config.js` or `app.config.ts`:

```javascript
// app.config.js or app.config.ts
export default {
  // ... your existing config
  plugins: [
    // ... your other plugins
    [
      '@playerdata/react-native-mcu-manager',
      {
        removeLocationMaxSdkVersion: true, // Remove maxSdkVersion from location permissions (default: true)
      },
    ],
  ],
};
```

After adding the plugin, run `npx expo prebuild` to regenerate native files. The plugin will automatically add `tools:remove="android:maxSdkVersion"` to location permissions in your app's `AndroidManifest.xml`. This removes the `maxSdkVersion` attribute from permissions merged from the library's manifest, ensuring location permissions persist across all SDK versions.

**For bare React Native projects (manual setup):**

If you're not using Expo or prefer manual configuration, add `tools:remove="android:maxSdkVersion"` to location permissions in your app's `AndroidManifest.xml` file (typically located at `android/app/src/main/AndroidManifest.xml`):

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    package="your.package.name">

    <!-- Remove maxSdkVersion from merged location permissions -->
    <uses-permission
        android:name="android.permission.ACCESS_FINE_LOCATION"
        tools:remove="android:maxSdkVersion" />
    <uses-permission
        android:name="android.permission.ACCESS_COARSE_LOCATION"
        tools:remove="android:maxSdkVersion" />

    <application
        android:name=".MainApplication"
        android:label="@string/app_name">
        <!-- ... your application content ... -->
    </application>
</manifest>
```

**Note:** Make sure to add the `xmlns:tools` namespace declaration in the `<manifest>` tag if it's not already present.

This configuration ensures that the `maxSdkVersion` attribute is removed from location permissions during manifest merging, allowing them to persist on API 30+.

# Contributing

Contributions are very welcome! Please refer to guidelines described in the [contributing guide](https://github.com/expo/expo#contributing).
