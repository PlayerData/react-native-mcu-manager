import McuManagerModule from './ReactNativeMcuManagerModule';

export interface ImageSlotState {
  image: number;
  slot: number;
  version: string | null;
  /** SHA-256 of the image, as a lowercase hex string. */
  hash: string;
  bootable: boolean;
  pending: boolean;
  confirmed: boolean;
  active: boolean;
  permanent: boolean;
}

/**
 * Read the MCUboot image state (SMP image state read) for every slot on the
 * device. Use after an upgrade to verify the running image is durably
 * confirmed: a slot that is `active` but not `confirmed` will be reverted by
 * MCUboot on the device's next reboot.
 */
export const readImageState = McuManagerModule?.readImageState as (
  bleId: string
) => Promise<ImageSlotState[]>;
