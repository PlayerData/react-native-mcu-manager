import { StyleSheet, Text, View } from 'react-native';

import * as ReactNativeMcuManager from '@playerdata/react-native-mcu-manager';

export default function App() {
  return (
    <View style={styles.container}>
      <Text>{ReactNativeMcuManager.hello()}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
  },
});
