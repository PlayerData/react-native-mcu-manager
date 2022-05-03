import { useState, useEffect } from 'react';

import McuManager, {
  ProgressEvent,
  UploadEvents,
  UpgradeMode,
} from '@playerdata/react-native-mcu-manager';

const useFirmwareUpdate = (upgradeMode?: UpgradeMode) => {
  const [bleId, setBleId] = useState<string | null>(null);
  const [progress, setProgress] = useState(0);
  const [state, setState] = useState('');

  useEffect(() => {
    McuManager.cancel();

    const onUploadProgress = (evt: ProgressEvent) => {
      setProgress(parseInt(evt.progress, 10));
    };

    const onUploadStateChanged = (evt: ProgressEvent) => {
      setState(evt.state);
    };

    const uploadProgressListener = UploadEvents.addListener(
      'uploadProgress',
      onUploadProgress
    );
    const uploadStateChangedListener = UploadEvents.addListener(
      'uploadStateChanged',
      onUploadStateChanged
    );

    return function cleanup() {
      uploadProgressListener.remove();
      uploadStateChangedListener.remove();
      McuManager.cancel();
    };
  }, []);

  const startUpdate = (updateFileUri: string): Promise<void> =>
    McuManager.updateDevice(bleId!, updateFileUri, {
      estimatedSwapTime: 60,
      upgradeMode,
    }).catch((e: Error) => {
      setState(e.message);
    });

  return {
    bleId,
    progress,
    setBleId,
    startUpdate,
    state,
  };
};

export default useFirmwareUpdate;
