import React, { useState } from 'react';

import {
  Button,
  FlatList,
  Modal,
  SafeAreaView,
  StyleSheet,
  Text,
  View,
} from 'react-native';

import { UpgradeMode } from '@playerdata/react-native-mcu-manager';

import useBluetoothDevices from './useBluetoothDevices';
import useFilePicker from './useFilePicker';
import useFirmwareUpdate from './useFirmwareUpdate';

const styles = StyleSheet.create({
  root: {
    paddingTop: 16,
  },

  block: {
    marginRight: 16,
    marginBottom: 16,
    marginLeft: 16,
  },

  list: {
    padding: 16,
  },
});

export default function App() {
  const [devicesListVisible, setDevicesListVisible] = useState(false);
  const [selectedDeviceName, setSelectedDeviceName] = useState<string | null>(
    null
  );
  const [upgradeMode, setUpgradeMode] = useState<UpgradeMode | undefined>(
    undefined
  );

  const { devices, error: scanError } = useBluetoothDevices();
  const { selectedFile, filePickerError, pickFile } = useFilePicker();
  const { bleId, progress, setBleId, startUpdate, state } = useFirmwareUpdate(
    upgradeMode
  );

  return (
    <SafeAreaView>
      <View style={styles.root}>
        <Text style={styles.block}>Step 1 - Select Device to Update</Text>

        <View style={styles.block}>
          {bleId && (
            <>
              <Text>Selected:</Text>
              <Text>{selectedDeviceName}</Text>
            </>
          )}
          <Button
            onPress={() => setDevicesListVisible(true)}
            title="Select Device"
          />
        </View>

        <Modal visible={devicesListVisible}>
          <FlatList
            contentContainerStyle={styles.list}
            data={devices}
            keyExtractor={({ id }) => id}
            renderItem={({ item }) => (
              <View>
                <Text>{item.name || item.id}</Text>

                <Button
                  title="Select"
                  onPress={() => {
                    setBleId(item.id);
                    setSelectedDeviceName(item.name);
                    setDevicesListVisible(false);
                  }}
                />
              </View>
            )}
            ListHeaderComponent={() => <Text>{scanError}</Text>}
          />
        </Modal>

        <Text style={styles.block}>Step 2 - Select Update File</Text>

        <View style={styles.block}>
          <Text>
            {selectedFile?.name} {filePickerError}
          </Text>
          <Button onPress={() => pickFile()} title="Pick File" />
        </View>

        <Text style={styles.block}>Step 3 - Upgrade Mode</Text>

        <View style={styles.block}>
          <Button
            disabled={upgradeMode === undefined}
            title="undefined"
            onPress={() => setUpgradeMode(undefined)}
          />
          <Button
            disabled={upgradeMode === UpgradeMode.TEST_AND_CONFIRM}
            title="TEST_AND_CONFIRM"
            onPress={() => setUpgradeMode(UpgradeMode.TEST_AND_CONFIRM)}
          />
          <Button
            disabled={upgradeMode === UpgradeMode.CONFIRM_ONLY}
            title="CONFIRM_ONLY"
            onPress={() => setUpgradeMode(UpgradeMode.CONFIRM_ONLY)}
          />
          <Button
            disabled={upgradeMode === UpgradeMode.TEST_ONLY}
            title="TEST_ONLY"
            onPress={() => setUpgradeMode(UpgradeMode.TEST_ONLY)}
          />
        </View>

        <Text style={styles.block}>Step 4 - Update</Text>

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
      </View>
    </SafeAreaView>
  );
}
