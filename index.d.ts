import { NativeEventEmitter } from "react-native";
import McuManager from ".";

declare module McuManager {
  export const updateDevice: (
    macAddress: String,
    updateFileUriString: String,
  ) => Promise<null>;
  export const cancel: () => void;
}

export const UploadEvents: NativeEventEmitter;
export default McuManager;
