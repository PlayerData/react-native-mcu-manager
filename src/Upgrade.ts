import {
  NativeModules,
  NativeEventEmitter,
  EmitterSubscription,
} from 'react-native';

import { v4 as uuidv4 } from 'uuid';

const { McuManager } = NativeModules;

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

export interface UpgradeOptions {
  /**
   * The estimated time, in seconds, that it takes for the target device to swap to the updated image.
   */
  estimatedSwapTime: number;

  /**
   * Each packet will be truncated to fit this alignment.
   *
   * If a device uses internal flash buffering this can be disabled.
   */
  memoryAlignment?: number;

  /**
   * McuManager firmware upgrades can actually be performed in few different ways.
   * These different upgrade modes determine the commands sent after the upload step.
   *
   * @see UpgradeMode
   */
  upgradeMode?: UpgradeMode;

  /**
   * The number of buffers to allocate for MCUMgr.
   * Multiple buffers allow for sending packets in parallel, which may improve upload speed.
   *
   * For nRF-Connect applications, set this to match MCUMGR_BUF_COUNT.
   */
  windowUploadCapacity?: number;
}

export type FirmwareUpgradeState =
  | 'NONE'
  | 'VALIDATE'
  | 'UPLOAD'
  | 'TEST'
  | 'RESET'
  | 'CONFIRM'
  | 'SUCCESS'
  | 'UNKNOWN';

const McuManagerEvents = new NativeEventEmitter(McuManager);

declare const UpgradeIdSymbol: unique symbol;
type UpgradeID = string & { [UpgradeIdSymbol]: never };

type AddUpgradeListener = {
  (
    eventType: 'upgradeStateChanged',
    listener: ({ state }: { state: FirmwareUpgradeState }) => void,
    context?: any
  ): EmitterSubscription;
  (
    eventType: 'uploadProgress',
    listener: ({ progress }: { progress: number }) => void,
    context?: any
  ): EmitterSubscription;
};

class Upgrade {
  private id: UpgradeID;

  /**
   * Create a new Upgrade.
   *
   * @param bleId The BLE ID of the device to upgrade.
   * @param updateFileUriString The URI of the firmware update file.
   * @param updateOptions see @UpgradeOptions
   */
  constructor(
    bleId: string,
    updateFileUriString: string,
    updateOptions: UpgradeOptions
  ) {
    this.id = uuidv4() as UpgradeID;

    McuManager.createUpgrade(
      this.id,
      bleId,
      updateFileUriString,
      updateOptions
    );
  }

  /**
   * Perform the upgrade.
   */
  runUpgrade = async (): Promise<void> => McuManager.runUpgrade(this.id);

  cancel = (): void => {
    McuManager.cancelUpgrade(this.id);
  };

  addListener: AddUpgradeListener = (
    eventType: any,
    listener: (...args: any[]) => void,
    context?: any
  ): EmitterSubscription => {
    return McuManagerEvents.addListener(
      eventType,
      ({ id, ...event }) => {
        if (id === this.id) {
          listener(event);
        }
      },
      context
    );
  };

  /**
   * Call to release native Upgrade class.
   * Failure to do so may result in memory leaks.
   */
  destroy = () => {
    McuManager.destroyUpgrade(this.id);
  };
}

export default Upgrade;
