import {
  readSetting,
  writeSetting,
} from '@playerdata/react-native-mcu-manager';
import { Buffer } from 'buffer';

import React, { useState } from 'react';
import {
  Button,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';

import { useSelectedDevice } from '../context/selectedDevice';

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

export default function settings() {
  const { selectedDevice } = useSelectedDevice();

  const [settingError, setSettingError] = useState<string | null>(null);
  const [settingName, setSettingName] = useState<string>('');
  const [settingValue, setSettingValue] = useState<string>('');

  return (
    <SafeAreaView>
      <ScrollView contentContainerStyle={styles.root}>
        <Text style={styles.block}>Step 1 - Select Device to Update</Text>

        <View style={styles.block}>
          {selectedDevice && (
            <>
              <Text>Selected:</Text>
              <Text>{selectedDevice.deviceName}</Text>
            </>
          )}
        </View>

        <Text style={styles.block}>
          Step 2 - Read or Write settings to the device
        </Text>

        <View style={styles.block}>
          <Text>Setting Name</Text>

          <TextInput
            value={settingName || ''}
            onChangeText={setSettingName}
            placeholder="Enter setting name"
          />
        </View>

        <View style={styles.block}>
          <Text>Setting Value</Text>

          <TextInput
            value={settingValue || ''}
            onChangeText={setSettingValue}
            placeholder="Enter setting value"
          />
        </View>

        {settingError && (
          <View style={styles.block}>
            <Text>{settingError}</Text>
          </View>
        )}

        <View style={styles.block}>
          <Button
            onPress={async () => {
              try {
                setSettingError(null);

                const valueB64 = await readSetting(
                  selectedDevice?.deviceId || '',
                  settingName
                );

                const decodedValue = Buffer.from(valueB64, 'base64').toString(
                  'binary'
                );
                setSettingValue(decodedValue);
              } catch (error) {
                if (error instanceof Error) {
                  setSettingError(error.message);
                } else {
                  setSettingError('An unknown error occurred');
                }
              }
            }}
            title="Read Setting"
          />
        </View>

        <View style={styles.block}>
          <Button
            onPress={async () => {
              try {
                setSettingError(null);

                const encodedValue = Buffer.from(
                  settingValue,
                  'binary'
                ).toString('base64');

                await writeSetting(
                  selectedDevice?.deviceId || '',
                  settingName,
                  encodedValue
                );
              } catch (error) {
                if (error instanceof Error) {
                  setSettingError(error.message);
                } else {
                  setSettingError('An unknown error occurred');
                }
              }
            }}
            title="Write Setting"
          />
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}
