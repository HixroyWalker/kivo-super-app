import React, { useState } from 'react';
import { View, Text, StyleSheet, TextInput, TouchableOpacity, ScrollView, Alert, ActivityIndicator } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';

const RATES: Record<string, number> = {
  USD: 155.20,
  CAD: 114.50,
  GBP: 198.80,
  JMD: 1.00
};

const ExchangeScreen = ({ navigation }: any) => {
  const router = useRouter();
  const [fromCurrency, setFromCurrency] = useState('USD');
  const [toCurrency, setToCurrency] = useState('JMD');
  const [amount, setAmount] = useState('');
  const [loading, setLoading] = useState(false);

  const calculateConversion = () => {
    if (!amount || isNaN(parseFloat(amount))) return '0.00';
    const val = parseFloat(amount);
    // Convert to JMD baseline, then to target currency
    const jmdBaseline = val * RATES[fromCurrency];
    const converted = jmdBaseline / RATES[toCurrency];
    return converted.toFixed(2);
  };

  const handleSwap = () => {
    const temp = fromCurrency;
    setFromCurrency(toCurrency);
    setToCurrency(temp);
  };

  const handleExchange = () => {
    if (!amount || parseFloat(amount) <= 0) {
      Alert.alert('Invalid Amount', 'Please enter an amount to convert.');
      return;
    }

    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      Alert.alert(
        'Exchange Completed',
        `Successfully converted ${amount} ${fromCurrency} into ${calculateConversion()} ${toCurrency}!`,
        [{ text: 'OK', onPress: () => router.push('/(tabs)') }]
      );
    }, 1500);
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.contentContainer}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()}>
          <Ionicons name="arrow-back" size={24} color="#FFF" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Global Exchange</Text>
        <View style={{ width: 24 }} />
      </View>

      {/* Exchange Rates Panel */}
      <LinearGradient colors={['#1D1D35', '#0F0F1E']} style={styles.ratesPanel}>
        <Text style={styles.panelTitle}>Live Exchange Rates (vs JMD)</Text>
        <View style={styles.rateRow}>
          <Text style={styles.currencyName}>🇺🇸 US Dollar (USD)</Text>
          <Text style={styles.rateValue}>$155.20 JMD</Text>
        </View>
        <View style={styles.rateRow}>
          <Text style={styles.currencyName}>🇨🇦 Canadian Dollar (CAD)</Text>
          <Text style={styles.rateValue}>$114.50 JMD</Text>
        </View>
        <View style={styles.rateRow}>
          <Text style={styles.currencyName}>🇬🇧 British Pound (GBP)</Text>
          <Text style={styles.rateValue}>$198.80 JMD</Text>
        </View>
      </LinearGradient>

      {/* Converter Inputs */}
      <View style={styles.converterBox}>
        <View style={styles.inputSection}>
          <Text style={styles.inputLabel}>Convert From</Text>
          <View style={styles.row}>
            <TextInput
              style={styles.numericInput}
              keyboardType="numeric"
              placeholder="0.00"
              placeholderTextColor="rgba(255,255,255,0.3)"
              value={amount}
              onChangeText={setAmount}
            />
            <View style={styles.currencySelector}>
              {['USD', 'CAD', 'GBP', 'JMD'].map((curr) => (
                <TouchableOpacity
                  key={curr}
                  style={[styles.chip, fromCurrency === curr && styles.activeChip]}
                  onPress={() => setFromCurrency(curr)}
                >
                  <Text style={[styles.chipText, fromCurrency === curr && styles.activeChipText]}>{curr}</Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>
        </View>

        {/* Swap Button */}
        <TouchableOpacity style={styles.swapBtn} onPress={handleSwap}>
          <Ionicons name="swap-vertical" size={24} color="#6C63FF" />
        </TouchableOpacity>

        <View style={styles.inputSection}>
          <Text style={styles.inputLabel}>Converted Amount</Text>
          <View style={styles.row}>
            <Text style={styles.resultText}>{calculateConversion()}</Text>
            <View style={styles.currencySelector}>
              {['USD', 'CAD', 'GBP', 'JMD'].map((curr) => (
                <TouchableOpacity
                  key={curr}
                  style={[styles.chip, toCurrency === curr && styles.activeChip]}
                  onPress={() => setToCurrency(curr)}
                >
                  <Text style={[styles.chipText, toCurrency === curr && styles.activeChipText]}>{curr}</Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>
        </View>
      </View>

      {/* Action Button */}
      <TouchableOpacity style={styles.exchangeBtn} onPress={handleExchange} disabled={loading}>
        <LinearGradient colors={['#6C63FF', '#4B42E5']} style={styles.gradientBtn}>
          {loading ? (
            <ActivityIndicator size="small" color="#FFF" />
          ) : (
            <Text style={styles.exchangeBtnText}>Complete Exchange</Text>
          )}
        </LinearGradient>
      </TouchableOpacity>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0F0F1E' },
  contentContainer: { padding: 20, paddingBottom: 40 },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 25, marginTop: 10 },
  headerTitle: { color: '#FFF', fontSize: 20, fontWeight: 'bold' },
  ratesPanel: { padding: 20, borderRadius: 20, marginBottom: 25, borderWidth: 1, borderColor: 'rgba(255,255,255,0.05)' },
  panelTitle: { color: '#6C63FF', fontWeight: 'bold', fontSize: 14, marginBottom: 15, letterSpacing: 1 },
  rateRow: { flexDirection: 'row', justifyContent: 'space-between', marginVertical: 8 },
  currencyName: { color: '#FFF', fontSize: 15 },
  rateValue: { color: '#FFF', fontWeight: 'bold' },
  converterBox: { backgroundColor: 'rgba(255,255,255,0.03)', padding: 20, borderRadius: 20, marginBottom: 30 },
  inputSection: { marginVertical: 10 },
  inputLabel: { color: '#888', fontSize: 12, fontWeight: 'bold', marginBottom: 8, letterSpacing: 1 },
  row: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  numericInput: { color: '#FFF', fontSize: 28, fontWeight: 'bold', width: '40%' },
  resultText: { color: '#00FFCC', fontSize: 28, fontWeight: 'bold', width: '40%' },
  currencySelector: { flexDirection: 'row', width: '55%', justifyContent: 'space-between' },
  chip: { paddingVertical: 6, paddingHorizontal: 10, borderRadius: 10, backgroundColor: 'rgba(255,255,255,0.05)' },
  activeChip: { backgroundColor: '#6C63FF' },
  chipText: { color: '#888', fontWeight: 'bold', fontSize: 12 },
  activeChipText: { color: '#FFF' },
  swapBtn: { alignSelf: 'center', marginVertical: 15, backgroundColor: 'rgba(108, 99, 255, 0.1)', padding: 10, borderRadius: 20 },
  exchangeBtn: { width: '100%', height: 55, borderRadius: 15, overflow: 'hidden' },
  gradientBtn: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  exchangeBtnText: { color: '#FFF', fontSize: 18, fontWeight: 'bold' }
});

export default ExchangeScreen;
