import { useEffect, useState } from 'react';
import { BleManager, Device } from 'react-native-ble-plx';
import { sortBy, uniqBy } from 'lodash';

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
          sortBy(uniqBy([...oldDevices, scannedDevice], 'id'), 'name')
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
