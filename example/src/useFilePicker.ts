import { useState } from 'react';
import { Platform } from 'react-native';
import DocumentPicker from 'react-native-document-picker';

import type { DocumentPickerResponse } from 'react-native-document-picker';

export interface SelectedFile {
  uri: string;
  name: string;
}

const useFilePicker = (): {
  selectedFile: SelectedFile | null;
  filePickerError: string | null;
  pickFile: () => void;
} => {
  const [selectedFile, setSelectedFile] = useState<SelectedFile | null>(null);
  const [filePickerError, setError] = useState<string | null>(null);

  const pickFile = async () => {
    let result: DocumentPickerResponse | null = null;
    let fileDelimiter: string | null = null;
    try {
      if (Platform.OS === 'ios') {
        type os = 'ios';
        fileDelimiter = '%2F';
        result = await DocumentPicker.pickSingle<os>({
          allowMultiSelection: false,
          type: ['public.data'],
          copyTo: 'cachesDirectory',
        });
      }
      if (Platform.OS === 'android') {
        type os = 'android';
        fileDelimiter = '/';
        result = await DocumentPicker.pickSingle<os>({
          allowMultiSelection: false,
          type: ['*/*'],
        });
      }

      if (result == null || fileDelimiter == null) {
        throw 'Failed to pick a file, is your OS supported?';
      }
      const uri = result.fileCopyUri ? result.fileCopyUri : result.uri;
      setSelectedFile({ uri, name: uri.split(fileDelimiter).slice(-1)[0] });
    } catch (err: any) {
      if (!DocumentPicker.isCancel(err)) {
        setSelectedFile(null);
        setError(err.message);
      }
    }
  };

  return { selectedFile, filePickerError, pickFile };
};

export default useFilePicker;
