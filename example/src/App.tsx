import React from 'react';

import {
  StyleSheet,
  View,
  Text,
  Button,
  FlatList,
  SafeAreaView,
} from 'react-native';

import useBluetoothDevices from './useBluetoothDevices';
import useFilePicker from './useFilePicker';
import useFirmwareUpdate from './useFirmwareUpdate';

const styles = StyleSheet.create({
  root: {
    height: '100%',
    flex: 1,
  },

  block: {
    marginRight: 16,
    marginBottom: 16,
    marginLeft: 16,
  },

  list: {
    flexGrow: 1,
  },
});

export default function App() {
  const { devices, error: scanError } = useBluetoothDevices();
  const { selectedFile, filePickerError, pickFile } = useFilePicker();
  const { bleId, progress, setBleId, startUpdate, state } = useFirmwareUpdate();

  return (
    <SafeAreaView style={styles.root}>
      <Text style={styles.block}>Step 1 - Select Device to Update</Text>

      <FlatList
        data={devices}
        keyExtractor={({ id }) => id}
        renderItem={({ item }) => (
          <View>
            <Text>{item.name || item.id}</Text>

            <Button
              disabled={bleId === item.id}
              title="Select"
              onPress={() => setBleId(item.id)}
            />
          </View>
        )}
        ListHeaderComponent={() => <Text>{scanError}</Text>}
        style={[styles.block, styles.list]}
      />

      <Text style={styles.block}>Step 2 - Select Update File</Text>

      <View style={styles.block}>
        <Text>
          {selectedFile?.name} {filePickerError}
        </Text>
        <Button onPress={() => pickFile()} title="Pick File" />
      </View>

      <Text style={styles.block}>Step 3 - Update</Text>

      <View style={styles.block}>
        <Text>Update Progress / State:</Text>
        <Text>
          {state}: {progress}
        </Text>

        <Button
          disabled={!selectedFile || !bleId}
          onPress={() => selectedFile && startUpdate(selectedFile.uri)}
          title="Start Update"
        />
      </View>
    </SafeAreaView>
  );
}
