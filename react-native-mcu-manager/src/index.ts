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
