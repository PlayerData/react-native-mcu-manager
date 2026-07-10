import McuManagerModule from './ReactNativeMcuManagerModule';
import type { FirmwareUpgradeState, UpgradeOptions } from './Upgrade';
import Upgrade, { UpgradeMode, UpgradeFileType } from './Upgrade';
import { BootloaderInfo, bootloaderInfo, MCUBootMode } from './bootloaderInfo';
import { ImageSlotState, readImageState } from './readImageState';

export const eraseImage = McuManagerModule?.eraseImage as (
  bleId: string
) => Promise<void>;

export const resetDevice = McuManagerModule?.resetDevice as (
  bleId: string
) => Promise<void>;

export {
  bootloaderInfo,
  readImageState,
  Upgrade,
  UpgradeMode,
  UpgradeFileType,
  MCUBootMode,
};
export type {
  BootloaderInfo,
  FirmwareUpgradeState,
  ImageSlotState,
  UpgradeOptions,
};
