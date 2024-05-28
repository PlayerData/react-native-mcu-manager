import {
  EventEmitter,
  Subscription,
} from 'expo-modules-core';
import { v4 as uuidv4 } from 'uuid';

import ReactNativeMcuManager from './ReactNativeMcuManagerModule';

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
   * McuManager firmware upgrades can actually be performed in few different ways.
   * These different upgrade modes determine the commands sent after the upload step.
   *
   * @see UpgradeMode
   */
  upgradeMode?: UpgradeMode;
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

const McuManagerEvents = new EventEmitter(ReactNativeMcuManager);

declare const UpgradeIdSymbol: unique symbol;
type UpgradeID = string & { [UpgradeIdSymbol]: never };

type UpgradeEvent = 'upgradeStateChanged' | 'uploadProgress';

type UpgradeStateChangedPayload = {
  id: UpgradeID;
  state: FirmwareUpgradeState;
};
type UploadProgressPayload = { id: UpgradeID; progress: number };
type UpgradeEventPayload = UpgradeStateChangedPayload & UploadProgressPayload;

type AddUpgradeListener = {
  (
    eventType: 'upgradeStateChanged',
    listener: (event: UpgradeStateChangedPayload) => void
  ): Subscription;
  (
    eventType: 'uploadProgress',
    listener: (event: UploadProgressPayload) => void
  ): Subscription;
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

    ReactNativeMcuManager.createUpgrade(
      this.id,
      bleId,
      updateFileUriString,
      updateOptions
    );
  }

  /**
   * Perform the upgrade.
   */
  runUpgrade = async (): Promise<void> =>
    ReactNativeMcuManager.runUpgrade(this.id);

  cancel = (): void => {
    ReactNativeMcuManager.cancelUpgrade(this.id);
  };

  addListener: AddUpgradeListener = (
    eventType: UpgradeEvent,
    listener: (event: UpgradeEventPayload) => void
  ): Subscription => {
    return McuManagerEvents.addListener<UpgradeEventPayload>(
      eventType,
      (event) => {
        if (event.id !== this.id) return;

        listener(event);
      }
    );
  };

  /**
   * Call to release native Upgrade class.
   * Failure to do so may result in memory leaks.
   */
  destroy = () => {
    ReactNativeMcuManager.destroyUpgrade(this.id);
  };
}

export default Upgrade;
