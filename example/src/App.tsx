import { UpgradeMode } from '@playerdata/react-native-mcu-manager';

import React, { useState } from 'react';
import {
  Button,
  FlatList,
  Modal,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';

import useBluetoothDevices from './useBluetoothDevices';
import useFilePicker from './useFilePicker';
import useFirmwareUpdate from './useFirmwareUpdate';

const styles = StyleSheet.create({
  root: {
    padding: 16,
  },

  block: {
    marginBottom: 16,
  },

  list: {
    padding: 16,
  },
});

export default function App() {
  const [devicesListVisible, setDevicesListVisible] = useState(false);
  const [selectedDeviceId, setSelectedDeviceId] = useState<string | null>(null);
  const [selectedDeviceName, setSelectedDeviceName] = useState<string | null>(
    null
  );
  const [upgradeMode, setUpgradeMode] = useState<UpgradeMode | undefined>(
    undefined
  );

  const { devices, error: scanError } = useBluetoothDevices();
  const { selectedFile, filePickerError, pickFile } = useFilePicker();
  const { cancelUpdate, runUpdate, progress, state } = useFirmwareUpdate(
    selectedDeviceId,
    selectedFile?.uri || null,
    upgradeMode
  );

  return (
    <SafeAreaView>
      <ScrollView contentContainerStyle={styles.root}>
        <Text style={styles.block}>Step 1 - Select Device to Update</Text>

        <View style={styles.block}>
          {selectedDeviceId && (
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
                    setSelectedDeviceId(item.id);
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
          <Text>State / Update Progress:</Text>
          <Text>
            {state}: {progress}
          </Text>

          <Button
            disabled={!selectedFile || !selectedDeviceId}
            onPress={() => selectedFile && runUpdate()}
            title="Start Update"
          />

          <Button
            disabled={!selectedFile || !selectedDeviceId}
            onPress={() => cancelUpdate()}
            title="Cancel Update"
          />
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}
