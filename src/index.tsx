import { NativeModules } from 'react-native';

const { McuManager } = NativeModules;

import Upgrade, {
  FirmwareUpgradeState,
  UpgradeOptions,
  UpgradeMode,
} from './Upgrade';

export const eraseImage = McuManager.eraseImage as (
  bleId: string
) => Promise<void>;

export { Upgrade, FirmwareUpgradeState, UpgradeOptions, UpgradeMode };
