import { sortBy, uniqBy } from 'lodash';
import { useEffect, useRef, useState } from 'react';
import { Device } from 'react-native-ble-plx';

import { BLEService } from '../BLEService';

const useBluetoothDevices = () => {
  const [bleManager] = useState(() => BLEService.manager);

  const [error, setError] = useState<string | null>(null);
  const [devices, setDevices] = useState<Device[]>([]);
  const deviceIdRef = useRef<string[]>([]);

  useEffect(() => {
    BLEService.initializeBLE().then(() =>
      bleManager.startDeviceScan(
        [],
        { allowDuplicates: false, legacyScan: false },
        (e, scannedDevice) => {
          if (e) {
            setError(`${e.message} - ${e.reason}`);
          }

          if (!scannedDevice) return;

          if (deviceIdRef.current.includes(scannedDevice.id)) return;
          deviceIdRef.current.push(scannedDevice.id);

          setDevices((oldDevices) =>
            sortBy(uniqBy([scannedDevice, ...oldDevices], 'id'), 'name')
          );
        }
      )
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
