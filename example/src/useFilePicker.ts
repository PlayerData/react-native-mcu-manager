import { useState } from 'react';
import { Platform } from 'react-native';
import DocumentPicker, {
  DocumentPickerOptions,
} from 'react-native-document-picker';

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

  const runDocumentPicker = async (
    pickerArgs: DocumentPickerOptions<any>,
    fileDelimiter: string
  ) => {
    try {
      const res = await DocumentPicker.pickSingle(pickerArgs);
      const uri = res.fileCopyUri ? res.fileCopyUri : res.uri;
      setSelectedFile({ uri, name: uri.split(fileDelimiter).slice(-1)[0] });
    } catch (err) {
      if (!DocumentPicker.isCancel(err)) {
        setSelectedFile(null);
        setError(err.message);
      }
    }
  };

  const pickFile = async () => {
    try {
      if (Platform.OS === 'ios') {
        runDocumentPicker(
          {
            type: ['public.data'],
            copyTo: 'cachesDirectory',
          },
          '/'
        );
      } else {
        runDocumentPicker(
          {
            type: ['*/*'],
          },
          '%2F'
        );
      }
    } catch (err) {
      if (!DocumentPicker.isCancel(err)) {
        setSelectedFile(null);
        setError(err.message);
      }
    }
  };

  return { selectedFile, filePickerError, pickFile };
};

export default useFilePicker;
