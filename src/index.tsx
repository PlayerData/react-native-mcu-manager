import { NativeModules, NativeEventEmitter } from 'react-native';

export enum UpgradeMode {
  /**
   * This mode is the default and recommended mode for performing upgrades due to it's ability to
   * recover from a bad firmware upgrade. The process for this mode is upload, test, reset, confirm.
   */
  TEST_AND_CONFIRM = 1,

  /**
   * This mode is not recommended. If the device fails to boot into the new image, it will not be able
   * to recover and will need to be re-flashed. The process for this mode is upload, confirm, reset.
   */
  CONFIRM_ONLY = 2,

  /**
   * This mode is useful if you want to run tests on the new image running before confirming it
   * manually as the primary boot image. The process for this mode is upload, test, reset.
   */
  TEST_ONLY = 3,
}

export interface UpdateOptions {
  /**
   * The estimated time, in seconds, that it takes for the target device to swap to the updated image.
   */
  estimatedSwapTime: number;

  /**
   * McuManager firmware upgrades can actually be performed in few different ways.
   * These different upgrade modes determine the commands sent after the upload step.
   *
   * @see UpgradeMode
   */
  upgradeMode?: UpgradeMode;
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
