import { createContext, useContext } from 'react';

export interface SelectedDevice {
  deviceId: string;
  deviceName: string | null;
}

const SelectedDeviceContext = createContext<{
  selectedDevice: SelectedDevice | null;
  setSelectedDevice: (device: SelectedDevice) => void;
}>({
  selectedDevice: null,
  setSelectedDevice: () => {},
});

export const SelectedDeviceProvider = SelectedDeviceContext.Provider;

export const useSelectedDevice = () => {
  const context = useContext(SelectedDeviceContext);

  if (!context) {
    throw new Error(
      'useSelectedDevice must be used within a SelectedDeviceProvider'
    );
  }

  return context;
};
