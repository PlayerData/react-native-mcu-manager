const { withAndroidManifest } = require('@expo/config-plugins');

/**
 * Expo plugin: Fix Location Permission Manifest Merging Issue
 * 
 * On Android API 30 and below, Bluetooth usage requires location permissions.
 * On API 30+, Bluetooth permissions changed (BLUETOOTH_SCAN, BLUETOOTH_CONNECT).
 * 
 * This library's manifest includes location permissions with maxSdkVersion="30".
 * During manifest merging, even if you remove maxSdkVersion from your app's manifest,
 * the library's manifest will merge in and reintroduce the maxSdkVersion attribute.
 * 
 * This plugin uses tools:remove to remove the maxSdkVersion attribute from location
 * permissions that are merged from the library's manifest.
 * 
 * @param {Object} config - Expo config
 * @param {Object} props - Plugin options
 * @param {boolean} props.removeLocationMaxSdkVersion - Whether to remove maxSdkVersion from location permissions (default: true)
 * @returns {Object} Modified Expo config
 */
const withLocationPermissionFix = (config, { removeLocationMaxSdkVersion = true } = {}) => {
  if (!removeLocationMaxSdkVersion) {
    return config;
  }

  return withAndroidManifest(config, (config) => {
    const androidManifest = config.modResults;
    const { manifest } = androidManifest;

    // Add tools namespace
    if (!manifest.$) {
      manifest.$ = {};
    }
    if (!manifest.$['xmlns:tools']) {
      manifest.$['xmlns:tools'] = 'http://schemas.android.com/tools';
    }

    // Ensure uses-permission array exists
    if (!manifest['uses-permission']) {
      manifest['uses-permission'] = [];
    }

    // Location permissions that need maxSdkVersion removed
    const locationPermissions = [
      'android.permission.ACCESS_FINE_LOCATION',
      'android.permission.ACCESS_COARSE_LOCATION',
    ];

    // Process each location permission
    locationPermissions.forEach((permissionName) => {
      // Find or create permission declaration
      let permission = manifest['uses-permission'].find(
        (p) => p.$ && p.$['android:name'] === permissionName
      );

      if (!permission) {
        permission = {
          $: {
            'android:name': permissionName,
          },
        };
        manifest['uses-permission'].push(permission);
      }

      // Add tools:remove to remove maxSdkVersion attribute from merged manifest
      if (!permission.$) {
        permission.$ = {};
      }

      if (!permission.$['tools:remove']) {
        permission.$['tools:remove'] = 'android:maxSdkVersion';
      } else {
        // If tools:remove already exists, append maxSdkVersion
        const existingRemove = permission.$['tools:remove'].split(',').map((a) => a.trim());
        if (!existingRemove.includes('android:maxSdkVersion')) {
          permission.$['tools:remove'] = [...existingRemove, 'android:maxSdkVersion'].join(',');
        }
      }
    });

    return config;
  });
};

module.exports = withLocationPermissionFix;
