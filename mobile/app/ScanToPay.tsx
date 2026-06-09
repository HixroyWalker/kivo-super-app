import React from 'react';
import ScanToPayScreen from '@/src/features/wallet/ScanToPayScreen';
import { useNavigation } from 'expo-router';

export default function ScanToPayRoute() {
  const navigation = useNavigation();
  return <ScanToPayScreen navigation={navigation} />;
}
