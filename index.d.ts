import McuManager from ".";

declare module McuManager {
  export const updateDevice: (
    macAddress: String,
    updateFileUriString: String,
  ) => Promise<null>;
}
export default McuManager;
