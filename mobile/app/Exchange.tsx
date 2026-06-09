import React from 'react';
import ExchangeScreen from '@/src/features/wallet/ExchangeScreen';
import { useNavigation } from 'expo-router';

export default function ExchangeRoute() {
  const navigation = useNavigation();
  return <ExchangeScreen navigation={navigation} />;
}
