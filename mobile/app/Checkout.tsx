import React from 'react';
import CheckoutScreen from '@/src/features/wallet/CheckoutScreen';
import { useNavigation } from 'expo-router';

export default function CheckoutRoute() {
  const navigation = useNavigation();
  return <CheckoutScreen navigation={navigation} />;
}
