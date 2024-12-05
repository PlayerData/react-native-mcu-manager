import McuManagerModule from './ReactNativeMcuManagerModule';
import type { FirmwareUpgradeState, UpgradeOptions } from './Upgrade';
import Upgrade, { UpgradeMode } from './Upgrade';

export const eraseImage = McuManagerModule?.eraseImage as (
  bleId: string
) => Promise<void>;

export { Upgrade, UpgradeMode };
export type { FirmwareUpgradeState, UpgradeOptions };
