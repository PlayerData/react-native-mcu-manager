import { useState, useEffect } from 'react';

import McuManager, {
  ProgressEvent,
  UploadEvents,
} from '@playerdata/react-native-mcu-manager';

const useFirmwareUpdate = () => {
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

    UploadEvents.addListener('uploadProgress', onUploadProgress);
    UploadEvents.addListener('uploadStateChanged', onUploadStateChanged);

    return function cleanup() {
      UploadEvents.removeListener('uploadStateChanged', onUploadStateChanged);
      UploadEvents.removeListener('uploadProgress', onUploadProgress);
      McuManager.cancel();
    };
  }, []);

  const startUpdate = (updateFileUri: string): Promise<void> =>
    McuManager.updateDevice(bleId!, updateFileUri).catch((e: Error) => {
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
