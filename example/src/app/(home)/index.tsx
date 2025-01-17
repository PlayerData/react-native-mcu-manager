import React, { useState } from 'react';
import { Button, StyleSheet, Text, View } from 'react-native';

import { Link } from 'expo-router';

import { resetDevice } from '@playerdata/react-native-mcu-manager';

import { useSelectedDevice } from '../../context/selectedDevice';

const styles = StyleSheet.create({
  root: {
    padding: 16,
  },

  block: {
    marginBottom: 16,
  },
});

const Home = () => {
  const { selectedDevice } = useSelectedDevice();
  const [resetState, setResetState] = useState('');

  return (
    <View style={styles.root}>
      <View style={styles.block}>
        <Text>
          Select a device, then use the tabs below to choose which function to
          test
        </Text>
      </View>

      <Link asChild href="/select_device">
        <Button title="Select Device" />
      </Link>

      <View style={styles.block}>
        <Text>Selected:</Text>

        {selectedDevice?.deviceId && <Text>{selectedDevice.deviceName}</Text>}
      </View>

      <View style={styles.block}>
        <Text>{resetState}</Text>

        <Button
          title="Reset Device"
          disabled={!selectedDevice?.deviceId}
          onPress={() => {
            setResetState('Resetting...');

            resetDevice(selectedDevice?.deviceId || '')
              .then(() => setResetState('Reset complete'))
              .catch((error) => setResetState(error.message));
          }}
        />
      </View>
    </View>
  );
};

export default Home;
