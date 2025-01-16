import { Stack } from 'expo-router';

const HomeLayout = () => {
  return (
    <Stack>
      <Stack.Screen name="index" options={{ headerShown: false }} />
      <Stack.Screen
        name="select_device"
        options={{ title: 'Select Device', presentation: 'modal' }}
      />
    </Stack>
  );
};

export default HomeLayout;
