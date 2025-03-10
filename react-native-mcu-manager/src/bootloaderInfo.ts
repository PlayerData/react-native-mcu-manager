import McuManagerModule from './ReactNativeMcuManagerModule';

export enum MCUBootMode {
  MCUBOOT_MODE_SINGLE_SLOT = 0,
  MCUBOOT_MODE_SWAP_USING_SCRATCH = 1,
  MCUBOOT_MODE_UPGRADE_ONLY = 2,
  MCUBOOT_MODE_SWAP_USING_MOVE = 3,
  MCUBOOT_MODE_DIRECT_XIP = 4,
  MCUBOOT_MODE_DIRECT_XIP_WITH_REVERT = 5,
  MCUBOOT_MODE_RAM_LOAD = 6,
  MCUBOOT_MODE_FIRMWARE_LOADER = 7,
}

export interface BootloaderInfo {
  bootloader: string | null;
  mode: MCUBootMode | null;
  noDowngrade: boolean;
}

export const bootloaderInfo = McuManagerModule?.bootloaderInfo as (
  bleId: string
) => Promise<BootloaderInfo>;
