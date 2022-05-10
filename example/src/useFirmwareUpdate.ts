import { useState, useEffect, useRef } from 'react';

import { Upgrade, UpgradeMode } from '@playerdata/react-native-mcu-manager';

const useFirmwareUpdate = (
  bleId: string | null,
  updateFileUri: string | null,
  upgradeMode?: UpgradeMode
) => {
  const [progress, setProgress] = useState(0);
  const [state, setState] = useState('');
  const upgradeRef = useRef<Upgrade>();

  useEffect(() => {
    if (!bleId || !updateFileUri) {
      return () => null;
    }

    const upgrade = new Upgrade(bleId, updateFileUri, {
      estimatedSwapTime: 60,
      upgradeMode,
    });

    upgradeRef.current = upgrade;

    const uploadProgressListener = upgrade.addListener(
      'uploadProgress',
      ({ progress: newProgress }) => {
        setProgress(newProgress);
      }
    );

    const uploadStateChangedListener = upgrade.addListener(
      'upgradeStateChanged',
      ({ state: newState }) => {
        setState(newState);
      }
    );

    return function cleanup() {
      uploadProgressListener.remove();
      uploadStateChangedListener.remove();

      upgrade.cancel();
      upgrade.destroy();
    };
  }, [bleId, updateFileUri, upgradeMode]);

  const runUpdate = async (): Promise<void> => {
    try {
      if (!upgradeRef.current) {
        throw new Error('No upgrade class - missing BleId or updateFileUri?');
      }

      await upgradeRef.current.runUpgrade();
    } catch (ex: any) {
      setState(ex.message);
    }
  };

  return { progress, runUpdate, state };
};

export default useFirmwareUpdate;
