import * as DocumentPicker from 'expo-document-picker';
import { useState } from 'react';

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
    try {
      const pickedFile = await DocumentPicker.getDocumentAsync();

      const assets = pickedFile.assets;
      if (!assets) {
        return;
      }
      const file = assets[0];
      setSelectedFile({
        uri: file.uri,
        name: file.name || '',
      });
    } catch (error) {
      setError(JSON.stringify(error));
    }
  };

  return { selectedFile, filePickerError, pickFile };
};

export default useFilePicker;
