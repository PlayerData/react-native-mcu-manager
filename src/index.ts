import { NativeModulesProxy, EventEmitter, Subscription } from 'expo-modules-core';

// Import the native module. On web, it will be resolved to ReactNativeMcuManager.web.ts
// and on native platforms to ReactNativeMcuManager.ts
import ReactNativeMcuManagerModule from './ReactNativeMcuManagerModule';
import { ChangeEventPayload } from './ReactNativeMcuManager.types';

// Get the native constant value.
export const PI = ReactNativeMcuManagerModule.PI;

export function hello(): string {
  return ReactNativeMcuManagerModule.hello();
}

export async function setValueAsync(value: string) {
  return await ReactNativeMcuManagerModule.setValueAsync(value);
}

const emitter = new EventEmitter(ReactNativeMcuManagerModule ?? NativeModulesProxy.ReactNativeMcuManager);

export function addChangeListener(listener: (event: ChangeEventPayload) => void): Subscription {
  return emitter.addListener<ChangeEventPayload>('onChange', listener);
}

export { ChangeEventPayload };
