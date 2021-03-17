import { NativeModules, NativeEventEmitter } from 'react-native';

type McuManagerType = {
  updateDevice: (
    macAddress: String,
    updateFileUriString: String
  ) => Promise<void>;
  cancel: () => void;
};

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

const { McuManager } = NativeModules;

export const UploadEvents = new NativeEventEmitter(McuManager);
export default McuManager as McuManagerType;
