import { NativeModules, NativeEventEmitter } from 'react-native';

const { McuManager } = NativeModules;
const UploadEvents = new NativeEventEmitter(McuManager)

export { UploadEvents };

export default McuManager;
