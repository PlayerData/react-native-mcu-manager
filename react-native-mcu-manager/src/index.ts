import McuManagerModule from './ReactNativeMcuManagerModule';
import type { FirmwareUpgradeState, UpgradeOptions } from './Upgrade';
import Upgrade, { UpgradeMode, UpgradeFileType } from './Upgrade';

export const eraseImage = McuManagerModule?.eraseImage as (
  bleId: string
) => Promise<void>;

export const resetDevice = McuManagerModule?.resetDevice as (
  bleId: string
) => Promise<void>;

export { Upgrade, UpgradeMode, UpgradeFileType };
export type { FirmwareUpgradeState, UpgradeOptions };

export const readSetting = McuManagerModule?.readSetting as (
  bleId: string,
  key: string
) => Promise<string>;

export const writeSetting = McuManagerModule?.writeSetting as (
  bleId: string,
  key: string,
  valueB64: string
) => Promise<void>;
