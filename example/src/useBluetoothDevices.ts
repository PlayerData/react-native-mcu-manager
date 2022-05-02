import { useEffect, useState } from 'react';
import { BleManager, Device } from 'react-native-ble-plx';
import { uniqBy } from 'lodash';

const useBluetoothDevices = () => {
  const [bleManager] = useState(() => new BleManager());
  const [error, setError] = useState<string | null>(null);
  const [devices, setDevices] = useState<Device[]>([]);

  useEffect(() => {
    bleManager.startDeviceScan(
      [],
      { allowDuplicates: false },
      (e, scannedDevice) => {
        if (e) {
          setError(`${e.message} - ${e.reason}`);
        }

        if (!scannedDevice) return;

        setDevices((oldDevices) =>
          uniqBy([...oldDevices, scannedDevice], 'id')
        );
      }
    );

    return () => {
      bleManager.stopDeviceScan();
    };
  }, [bleManager]);

  return {
    devices,
    error,
  };
};

export default useBluetoothDevices;
