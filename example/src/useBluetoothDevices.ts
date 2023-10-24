import { useEffect, useRef, useState } from 'react';
import { BleManager, Device } from 'react-native-ble-plx';
import { sortBy, uniqBy } from 'lodash';

const useBluetoothDevices = () => {
  const [bleManager] = useState(() => new BleManager());
  const [error, setError] = useState<string | null>(null);
  const [devices, setDevices] = useState<Device[]>([]);
  const deviceIdRef = useRef<string[]>([]);

  useEffect(() => {
    bleManager.startDeviceScan(
      [],
      { allowDuplicates: false },
      (e, scannedDevice) => {
        if (e) {
          setError(`${e.message} - ${e.reason}`);
        }

        if (!scannedDevice) return;

        if (deviceIdRef.current.includes(scannedDevice.id)) return;
        deviceIdRef.current.push(scannedDevice.id);

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
