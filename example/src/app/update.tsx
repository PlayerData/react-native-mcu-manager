import {
  UpgradeFileType,
  UpgradeMode,
} from '@playerdata/react-native-mcu-manager';

import React, { useState } from 'react';
import {
  Button,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';

import useFilePicker from '../hooks/useFilePicker';
import useFirmwareUpdate from '../hooks/useFirmwareUpdate';
import { useSelectedDevice } from '../context/selectedDevice';

const styles = StyleSheet.create({
  root: {
    padding: 16,
  },

  block: {
    marginBottom: 16,
  },
});

const Update = () => {
  const { selectedDevice } = useSelectedDevice();

  const [fileType, setFileType] = useState<UpgradeFileType>(
    UpgradeFileType.BIN
  );
  const [upgradeMode, setUpgradeMode] = useState<UpgradeMode | undefined>(
    undefined
  );

  const { selectedFile, filePickerError, pickFile } = useFilePicker();
  const { cancelUpdate, runUpdate, progress, state } = useFirmwareUpdate(
    selectedDevice?.deviceId || null,
    selectedFile?.uri || null,
    fileType,
    upgradeMode
  );

  return (
    <SafeAreaView>
      <ScrollView contentContainerStyle={styles.root}>
        <Text style={styles.block}>Step 1 - Select Device to Update</Text>

        <View style={styles.block}>
          {selectedDevice?.deviceId && (
            <>
              <Text>Selected:</Text>
              <Text>{selectedDevice.deviceName}</Text>
            </>
          )}
        </View>

        <Text style={styles.block}>Step 2 - Select Update File</Text>

        <View style={styles.block}>
          <Text>
            {selectedFile?.name} {filePickerError}
          </Text>
          <Button onPress={() => pickFile()} title="Pick File" />
        </View>

        <Text style={styles.block}>Step 2a - Select Update File Type</Text>

        <View style={styles.block}>
          <Button
            disabled={fileType === UpgradeFileType.BIN}
            title="BIN"
            onPress={() => setFileType(UpgradeFileType.BIN)}
          />
          <Button
            disabled={fileType === UpgradeFileType.ZIP}
            title="ZIP"
            onPress={() => setFileType(UpgradeFileType.ZIP)}
          />
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
            disabled={!selectedFile || !selectedDevice?.deviceId}
            onPress={() => selectedFile && runUpdate()}
            title="Start Update"
          />

          <Button
            disabled={!selectedFile || !selectedDevice?.deviceId}
            onPress={() => cancelUpdate()}
            title="Cancel Update"
          />
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

export default Update;
