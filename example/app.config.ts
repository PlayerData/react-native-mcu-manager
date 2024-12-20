import { ExpoConfig } from '@expo/config-types';
import 'ts-node/register';

const config: ExpoConfig = {
  name: "react-native-mcu-manager-example",
  slug: "react-native-mcu-manager-example",
  version: "1.0.0",
  orientation: "portrait",
  assetBundlePatterns: ["**/*"],
  splash: {
    image: ".assets/images/pd.png",
    backgroundColor: "#FFFFFF",
  },
  ios: {
    supportsTablet: true,
    bundleIdentifier: "uk.co.playerdata.reactnativemcumanager.example",
    infoPlist: {
      NSBluetoothAlwaysUsageDescription: "Requires Bluetooth to perform firmware updates.",
    },
  },
  android: {
    package: "uk.co.playerdata.reactnativemcumanager.example",
    permissions: [
      "ACCESS_FINE_LOCATION",
      "ACCESS_COARSE_LOCATION",
    ],
  },
  plugins: [
    ["expo-document-picker"],
    ["./gradlePlugin.ts"]
  ]
};

export default config;
