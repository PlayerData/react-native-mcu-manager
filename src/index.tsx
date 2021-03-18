import { NativeModules, NativeEventEmitter } from 'react-native';

interface UpdateOptions {
  /*
   * The estimated time, in seconds, that it takes for the target device to swap to the updated image.
   */
  estimatedSwapTime: number;
}

type McuManagerType = {
  updateDevice: (
    macAddress: String,
    updateFileUriString: String,
    updateOptions: UpdateOptions
  ) => Promise<void>;
  cancel: () => void;
};

export type FirmwareUploadStateAndroid =
  | 'NONE'
  | 'VALIDATE'
  | 'UPLOAD'
  | 'TEST'
  | 'RESET'
  | 'CONFIRM'
  | 'SUCCESS'
  | 'UNKNOWN';

export type FirmwareUploadStateIOS =
  | 'none'
  | 'validate'
  | 'upload'
  | 'test'
  | 'reset'
  | 'confirm'
  | 'success';

export interface ProgressEvent {
  bleId: string;
  state: FirmwareUploadStateIOS | FirmwareUploadStateAndroid;
  progress: string;
}

const { McuManager } = NativeModules;

export const UploadEvents = new NativeEventEmitter(McuManager);
export default McuManager as McuManagerType;
