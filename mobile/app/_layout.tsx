import { DarkTheme, DefaultTheme, ThemeProvider } from '@react-navigation/native';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import 'react-native-reanimated';
import axios from 'axios';
import Constants from 'expo-constants';

import { useColorScheme } from '@/hooks/use-color-scheme';

// Dynamically resolve the developer's computer IP address on the local network
const getBackendUrl = () => {
  const hostUri = Constants.expoConfig?.hostUri || 
                  Constants.expoGoConfig?.debuggerHost || 
                  (Constants as any).manifest2?.extra?.expoGo?.debuggerHost ||
                  (Constants as any).manifest?.debuggerHost;

  console.log('[KIVO] Expo Constants check:', {
    expoConfigHostUri: Constants.expoConfig?.hostUri,
    expoGoConfigDebuggerHost: Constants.expoGoConfig?.debuggerHost,
    manifest2DebuggerHost: (Constants as any).manifest2?.extra?.expoGo?.debuggerHost,
    manifestDebuggerHost: (Constants as any).manifest?.debuggerHost,
  });

  if (hostUri) {
    const ip = hostUri.split(':')[0];
    return `http://${ip}:8080`;
  }
  // Fallback to localhost if hostUri is unavailable (e.g. standard local simulator or web browser fallback)
  return 'http://localhost:8080';
};

axios.defaults.baseURL = getBackendUrl();
console.log('[KIVO] Global Axios baseURL configured dynamically:', axios.defaults.baseURL);

export const unstable_settings = {
  initialRouteName: '(tabs)',
};


export default function RootLayout() {
  const colorScheme = useColorScheme();

  return (
    <ThemeProvider value={colorScheme === 'dark' ? DarkTheme : DefaultTheme}>
      <Stack>
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
        <Stack.Screen name="modal" options={{ presentation: 'modal', title: 'Modal' }} />
        <Stack.Screen name="SendMoney" options={{ headerShown: false }} />
        <Stack.Screen name="ScanToPay" options={{ headerShown: false }} />
        <Stack.Screen name="Exchange" options={{ headerShown: false }} />
        <Stack.Screen name="MerchantPOS" options={{ headerShown: false }} />
        <Stack.Screen name="Checkout" options={{ headerShown: false }} />
        <Stack.Screen name="ShopTickets" options={{ headerShown: false }} />
      </Stack>
      <StatusBar style="auto" />
    </ThemeProvider>
  );
}
