import { NativeEventEmitter } from "react-native";

declare module McuManager {
  export const updateDevice: (
    macAddress: String,
    updateFileUriString: String
  ) => Promise<null>;
  export const cancel: () => void;
}

export const UploadEvents: NativeEventEmitter;

export type FirmwareUploadStateAndroid =
  | "NONE"
  | "VALIDATE"
  | "UPLOAD"
  | "TEST"
  | "RESET"
  | "CONFIRM"
  | "SUCCESS"
  | "UNKNOWN";

export type FirmwareUploadStateIOS =
  | "none"
  | "validate"
  | "upload"
  | "test"
  | "reset"
  | "confirm"
  | "success";

export interface ProgressEvent {
  bleId: string;
  state: FirmwareUploadStateIOS | FirmwareUploadStateAndroid;
  progress: string;
}

export default McuManager;
