import React, { useState } from 'react';
import { View, Text, StyleSheet, TextInput, TouchableOpacity, ScrollView, Alert, ActivityIndicator } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import api from '@/src/utils/api';

const MerchantRegistrationScreen = () => {
  const router = useRouter();
  const [businessName, setBusinessName] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async () => {
    if (!businessName.trim()) {
      Alert.alert('Required', 'Please enter your business name to proceed.');
      return;
    }

    setLoading(true);
    try {
      const response = await api.post('/wallet/merchant/register', {
        business_name: businessName.trim()
      });
      
      Alert.alert(
        'Application Submitted!',
        response.data.message || 'Your application is now pending admin approval.',
        [{ text: 'OK', onPress: () => router.push('/(tabs)') }]
      );
    } catch (error: any) {
      Alert.alert('Error', error.response?.data?.error || 'Failed to submit application.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.contentContainer}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()}>
          <Ionicons name="arrow-back" size={24} color="#FFF" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Merchant Setup</Text>
        <View style={{ width: 24 }} />
      </View>

      <LinearGradient colors={['#1D1D35', '#0F0F1E']} style={styles.infoCard}>
        <Ionicons name="briefcase-outline" size={40} color="#6C63FF" style={styles.icon} />
        <Text style={styles.cardTitle}>Grow Your Business with Kivo</Text>
        <Text style={styles.cardDesc}>
          Accept digital payments instantly, track inventory, and earn loyalty rewards. Apply today to become an approved Kivo Merchant.
        </Text>
      </LinearGradient>

      <View style={styles.formContainer}>
        <Text style={styles.inputLabel}>Business Name</Text>
        <View style={styles.inputWrapper}>
          <Ionicons name="storefront-outline" size={20} color="#888" style={styles.inputIcon} />
          <TextInput
            style={styles.textInput}
            placeholder="e.g. Tastee Patties, Transit Authority"
            placeholderTextColor="rgba(255,255,255,0.3)"
            value={businessName}
            onChangeText={setBusinessName}
            autoCapitalize="words"
          />
        </View>

        <TouchableOpacity style={styles.submitBtn} onPress={handleSubmit} disabled={loading}>
          <LinearGradient colors={['#6C63FF', '#4B42E5']} style={styles.gradientBtn}>
            {loading ? (
              <ActivityIndicator size="small" color="#FFF" />
            ) : (
              <Text style={styles.submitBtnText}>Submit Application</Text>
            )}
          </LinearGradient>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0F0F1E' },
  contentContainer: { padding: 20, paddingBottom: 40 },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 25, marginTop: 10 },
  headerTitle: { color: '#FFF', fontSize: 20, fontWeight: 'bold' },
  infoCard: { padding: 20, borderRadius: 20, marginBottom: 30, borderWidth: 1, borderColor: 'rgba(255,255,255,0.05)', alignItems: 'center' },
  icon: { marginBottom: 15 },
  cardTitle: { color: '#FFF', fontSize: 18, fontWeight: 'bold', marginBottom: 10, textAlign: 'center' },
  cardDesc: { color: '#999', fontSize: 14, textAlign: 'center', lineHeight: 22 },
  formContainer: { backgroundColor: 'rgba(255,255,255,0.03)', padding: 20, borderRadius: 20 },
  inputLabel: { color: '#888', fontSize: 13, fontWeight: 'bold', marginBottom: 8, letterSpacing: 1 },
  inputWrapper: { flexDirection: 'row', alignItems: 'center', backgroundColor: 'rgba(255,255,255,0.05)', borderRadius: 12, paddingHorizontal: 15, marginBottom: 25 },
  inputIcon: { marginRight: 10 },
  textInput: { flex: 1, height: 55, color: '#FFF', fontSize: 16 },
  submitBtn: { width: '100%', height: 55, borderRadius: 15, overflow: 'hidden' },
  gradientBtn: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  submitBtnText: { color: '#FFF', fontSize: 18, fontWeight: 'bold' }
});

export default MerchantRegistrationScreen;
