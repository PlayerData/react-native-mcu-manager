import { NativeModules } from 'react-native';

const { McuManager } = NativeModules;

import Upgrade, { UpgradeMode } from './Upgrade';

import type { FirmwareUpgradeState, UpgradeOptions } from './Upgrade';

export const eraseImage = McuManager?.eraseImage as (
  bleId: string
) => Promise<void>;

export { Upgrade, UpgradeMode };
export type { FirmwareUpgradeState, UpgradeOptions };
