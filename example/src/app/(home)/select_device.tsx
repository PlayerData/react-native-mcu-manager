import React from 'react';
import { Button, FlatList, StyleSheet, Text, View } from 'react-native';
import { useNavigation } from 'expo-router';

import { useSelectedDevice } from '../../context/selectedDevice';
import useBluetoothDevices from '../../hooks/useBluetoothDevices';

const styles = StyleSheet.create({
  list: {
    padding: 16,
  },
});

const SelectDevice = () => {
  const navigation = useNavigation();
  const { setSelectedDevice } = useSelectedDevice();
  const { devices, error: scanError } = useBluetoothDevices();

  return (
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
              setSelectedDevice({ deviceId: item.id, deviceName: item.name });
              navigation.goBack();
            }}
          />
        </View>
      )}
      ListHeaderComponent={() => <Text>{scanError}</Text>}
    />
  );
};

export default SelectDevice;
