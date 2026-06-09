import React from 'react';
import SendMoneyScreen from '@/src/features/wallet/SendMoneyScreen';
import { useNavigation } from 'expo-router';

export default function SendMoneyRoute() {
  const navigation = useNavigation();
  return <SendMoneyScreen navigation={navigation} />;
}
