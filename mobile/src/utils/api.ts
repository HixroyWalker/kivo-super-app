import axios from 'axios';
import { Platform } from 'react-native';
import Constants from 'expo-constants';

const getBaseUrl = () => {
  const hostUri = Constants.expoConfig?.hostUri || 
                  Constants.expoGoConfig?.debuggerHost || 
                  (Constants as any).manifest2?.extra?.expoGo?.debuggerHost ||
                  (Constants as any).manifest?.debuggerHost;

  if (hostUri) {
    const ip = hostUri.split(':')[0];
    return `http://${ip}:8080`;
  }

  // Fallback in development: Android Emulator uses 10.0.2.2, iOS Simulator uses localhost
  if (Platform.OS === 'android') {
    return 'http://10.0.2.2:8080';
  }
  return 'http://localhost:8080';
};

const api = axios.create({
  baseURL: getBaseUrl(),
  timeout: 10000,
});

// Set default auth token bypass for local development ease
api.defaults.headers.common['Authorization'] = 'Bearer mock_testuser@kivo.com';

export default api;
