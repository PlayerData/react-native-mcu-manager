import { Upgrade, UpgradeMode } from '@playerdata/react-native-mcu-manager';
import { useState, useEffect, useRef } from 'react';

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

    const upgrade = new Upgrade(
      bleId,
      updateFileUri,
      {
        estimatedSwapTime: 60,
        upgradeMode,
      },
      setProgress,
      setState
    );

    upgradeRef.current = upgrade;

    return function cleanup() {
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
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    } catch (ex: any) {
      setState(ex.message);
    }
  };

  const cancelUpdate = (): void => {
    if (!upgradeRef.current) return;

    upgradeRef.current.cancel();
  };

  return { progress, runUpdate, state, cancelUpdate };
};

export default useFirmwareUpdate;
