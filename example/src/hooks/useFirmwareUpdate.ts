import {
  Upgrade,
  UpgradeMode,
  UpgradeFileType,
} from '@playerdata/react-native-mcu-manager';
import { useState, useEffect, useRef } from 'react';

const useFirmwareUpdate = (
  bleId: string | null,
  updateFileUri: string | null,
  upgradeFileType: UpgradeFileType,
  upgradeMode?: UpgradeMode
) => {
  const [progress, setProgress] = useState(0);
  const [state, setState] = useState('');
  const [error, setError] = useState<string | null>(null);
  const upgradeRef = useRef<Upgrade>(null);

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
        upgradeFileType,
      },
      setProgress,
      setState
    );

    upgradeRef.current = upgrade;

    return function cleanup() {
      upgrade.cancel();
      upgrade.destroy();
    };
  }, [bleId, upgradeFileType, updateFileUri, upgradeMode]);

  const runUpdate = async (): Promise<void> => {
    setError(null);

    try {
      if (!upgradeRef.current) {
        throw new Error('No upgrade class - missing BleId or updateFileUri?');
      }

      await upgradeRef.current.runUpgrade();
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
    } catch (ex: any) {
      setError(ex.message);
    }
  };

  const cancelUpdate = (): void => {
    if (!upgradeRef.current) return;

    upgradeRef.current.cancel();
  };

  return { progress, runUpdate, state, error, cancelUpdate };
};

export default useFirmwareUpdate;
