import {
  ImageSlotState,
  readImageState as rnmcumgrReadImageState,
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

const ReadImageStateView = () => {
  const { selectedDevice } = useSelectedDevice();

  const [fetchInProgress, setFetchInProgress] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [imageState, setImageState] = useState<ImageSlotState[] | null>(null);

  const fetchImageState = useCallback(async () => {
    setError(null);
    setFetchInProgress(true);

    try {
      setImageState(
        await rnmcumgrReadImageState(selectedDevice?.deviceId || '')
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
            onPress={() => fetchImageState()}
            title="Read Image State"
          />
        </View>

        {error && (
          <View style={styles.block}>
            <Text style={{ color: 'red' }}>{error}</Text>
          </View>
        )}

        {imageState &&
          imageState.map((slot) => (
            <View key={`${slot.image}-${slot.slot}`} style={styles.block}>
              <Text>{JSON.stringify(slot, null, 2)}</Text>
            </View>
          ))}
      </ScrollView>
    </SafeAreaView>
  );
};

export default ReadImageStateView;
