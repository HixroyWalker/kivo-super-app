import React, { useState } from 'react';
import { View, Text, StyleSheet, TextInput, TouchableOpacity, ScrollView, Alert, ActivityIndicator, Image } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import * as ImagePicker from 'expo-image-picker';
import api from '@/src/utils/api';

const MerchantRegistrationScreen = () => {
  const router = useRouter();
  const [businessName, setBusinessName] = useState('');
  const [kycDocument, setKycDocument] = useState<string | null>(null);
  const [bizRegDocument, setBizRegDocument] = useState<string | null>(null);
  const [additionalDocument, setAdditionalDocument] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const handlePickDocument = async (setter: React.Dispatch<React.SetStateAction<string | null>>) => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsEditing: true,
      quality: 0.8,
    });

    if (!result.canceled && result.assets && result.assets.length > 0) {
      setter(result.assets[0].uri);
    }
  };

  const handleSubmit = async () => {
    if (!businessName.trim()) {
      Alert.alert('Required', 'Please enter your business name to proceed.');
      return;
    }
    if (!kycDocument || !bizRegDocument || !additionalDocument) {
      Alert.alert('Required', 'Please upload all 3 required documents to proceed.');
      return;
    }

    setLoading(true);
    try {
      // In a real app we would use FormData to upload the images.
      // For now, we mock the uploaded URLs.
      const mockKycUrl = 'https://storage.kivo.app/kyc/' + Date.now() + '.jpg';
      const mockBizRegUrl = 'https://storage.kivo.app/bizreg/' + Date.now() + '.jpg';
      const mockAdditionalUrl = 'https://storage.kivo.app/additional/' + Date.now() + '.jpg';
      
      const response = await api.post('/api/wallet/merchant/register', {
        business_name: businessName.trim(),
        kyc_document_url: mockKycUrl,
        business_registration_url: mockBizRegUrl,
        additional_docs_url: mockAdditionalUrl
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

        <Text style={styles.inputLabel}>KYC Document (ID / License)</Text>
        <TouchableOpacity style={styles.uploadBtn} onPress={() => handlePickDocument(setKycDocument)}>
          {kycDocument ? (
            <Image source={{ uri: kycDocument }} style={styles.uploadedImage} />
          ) : (
            <View style={styles.uploadPlaceholder}>
              <Ionicons name="person-outline" size={30} color="#6C63FF" />
              <Text style={styles.uploadText}>Upload Personal ID</Text>
            </View>
          )}
        </TouchableOpacity>

        <Text style={styles.inputLabel}>Business Registration Certificate</Text>
        <TouchableOpacity style={styles.uploadBtn} onPress={() => handlePickDocument(setBizRegDocument)}>
          {bizRegDocument ? (
            <Image source={{ uri: bizRegDocument }} style={styles.uploadedImage} />
          ) : (
            <View style={styles.uploadPlaceholder}>
              <Ionicons name="document-text-outline" size={30} color="#6C63FF" />
              <Text style={styles.uploadText}>Upload Registration</Text>
            </View>
          )}
        </TouchableOpacity>

        <Text style={styles.inputLabel}>Additional Supporting Document</Text>
        <TouchableOpacity style={styles.uploadBtn} onPress={() => handlePickDocument(setAdditionalDocument)}>
          {additionalDocument ? (
            <Image source={{ uri: additionalDocument }} style={styles.uploadedImage} />
          ) : (
            <View style={styles.uploadPlaceholder}>
              <Ionicons name="add-circle-outline" size={30} color="#6C63FF" />
              <Text style={styles.uploadText}>Upload Additional Docs</Text>
            </View>
          )}
        </TouchableOpacity>

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
  uploadBtn: { height: 100, backgroundColor: 'rgba(255,255,255,0.05)', borderRadius: 12, marginBottom: 25, overflow: 'hidden', borderWidth: 1, borderColor: 'rgba(108,99,255,0.3)', borderStyle: 'dashed' },
  uploadPlaceholder: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  uploadText: { color: '#888', marginTop: 8, fontSize: 13 },
  uploadedImage: { width: '100%', height: '100%', resizeMode: 'cover' },
  submitBtn: { width: '100%', height: 55, borderRadius: 15, overflow: 'hidden', marginTop: 10 },
  gradientBtn: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  submitBtnText: { color: '#FFF', fontSize: 18, fontWeight: 'bold' }
});

export default MerchantRegistrationScreen;
