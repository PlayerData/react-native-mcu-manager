import { useState } from 'react';
import { Tabs } from 'expo-router';
import 'react-native-reanimated';

import {
  SelectedDeviceProvider,
  SelectedDevice,
} from '../context/selectedDevice';

const RootLayout = () => {
  const [selectedDevice, setSelectedDevice] = useState<SelectedDevice | null>(
    null
  );

  return (
    <SelectedDeviceProvider value={{ selectedDevice, setSelectedDevice }}>
      <Tabs>
        <Tabs.Screen
          name="(home)"
          options={{ title: 'Home' }}
        />
        <Tabs.Screen name="update" options={{ title: 'Update' }} />
      </Tabs>
    </SelectedDeviceProvider>
  );
};

export default RootLayout;
