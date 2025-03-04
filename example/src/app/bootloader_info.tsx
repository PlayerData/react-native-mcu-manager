import {
  BootloaderInfo,
  bootloaderInfo as rnmcumgrBootloaderInfo,
} from '@playerdata/react-native-mcu-manager';

import React, { useCallback, useState } from 'react';
import {
  Button,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
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
});

const BootloaderInfoView = () => {
  const { selectedDevice } = useSelectedDevice();

  const [fetchInProgress, setFetchInProgress] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [bootloaderInfo, setBootloaderInfo] = useState<BootloaderInfo | null>(
    null
  );

  const fetchBootloaderInfo = useCallback(async () => {
    setError(null);
    setFetchInProgress(true);

    try {
      setBootloaderInfo(
        await rnmcumgrBootloaderInfo(selectedDevice?.deviceId || '')
      );
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';

      setError(errorMessage);
    } finally {
      setFetchInProgress(false);
    }
  }, [selectedDevice]);

  return (
    <SafeAreaView>
      <ScrollView contentContainerStyle={styles.root}>
        <View style={styles.block}>
          <Button
            disabled={fetchInProgress}
            onPress={() => fetchBootloaderInfo()}
            title="Fetch Bootloader Info"
          />
        </View>

        {error && (
          <View style={styles.block}>
            <Text style={{ color: 'red' }}>{error}</Text>
          </View>
        )}

        {bootloaderInfo && (
          <View style={styles.block}>
            <Text>{JSON.stringify(bootloaderInfo)}</Text>
          </View>
        )}
      </ScrollView>
    </SafeAreaView>
  );
};

export default BootloaderInfoView;
