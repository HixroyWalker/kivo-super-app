import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TextInput, TouchableOpacity, ScrollView, Alert, ActivityIndicator, Modal } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import api from '@/src/utils/api';

const MerchantStaffScreen = () => {
  const router = useRouter();
  const [staffList, setStaffList] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [modalVisible, setModalVisible] = useState(false);

  // New staff form state
  const [identifier, setIdentifier] = useState('');
  const [role, setRole] = useState('CASHIER');
  const [pin, setPin] = useState('');
  const [addingStaff, setAddingStaff] = useState(false);

  const fetchStaff = async () => {
    setLoading(true);
    try {
      const res = await api.get('/wallet/merchant/staff');
      setStaffList(res.data.staff || []);
    } catch (err: any) {
      console.error(err);
      Alert.alert('Error', err.response?.data?.error || 'Failed to fetch staff list.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchStaff();
  }, []);

  const handleAddStaff = async () => {
    if (!identifier.trim() || !pin.trim()) {
      Alert.alert('Required', 'Please enter a Kivo handle/email and a 6-digit PIN.');
      return;
    }
    if (pin.length < 4 || pin.length > 6) {
      Alert.alert('Invalid PIN', 'PIN must be 4-6 digits long.');
      return;
    }

    setAddingStaff(true);
    try {
      await api.post('/wallet/merchant/staff', {
        identifier: identifier.trim(),
        role,
        pin
      });
      Alert.alert('Success', 'Staff member added!');
      setModalVisible(false);
      setIdentifier('');
      setPin('');
      setRole('CASHIER');
      fetchStaff();
    } catch (err: any) {
      Alert.alert('Error', err.response?.data?.error || 'Failed to add staff.');
    } finally {
      setAddingStaff(false);
    }
  };

  const handleRemoveStaff = (id: string) => {
    Alert.alert('Remove Staff', 'Are you sure you want to remove this employee? They will lose access immediately.', [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Remove', style: 'destructive', onPress: async () => {
          try {
            await api.delete(`/wallet/merchant/staff/${id}`);
            Alert.alert('Success', 'Staff member removed.');
            fetchStaff();
          } catch (err: any) {
            Alert.alert('Error', err.response?.data?.error || 'Failed to remove staff.');
          }
      }}
    ]);
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.headerBtn}>
          <Ionicons name="arrow-back" size={24} color="#FFF" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Manage Employees</Text>
        <TouchableOpacity onPress={() => setModalVisible(true)} style={styles.headerBtn}>
          <Ionicons name="person-add" size={24} color="#6C63FF" />
        </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={styles.contentContainer}>
        {loading ? (
          <ActivityIndicator size="large" color="#6C63FF" style={{ marginTop: 50 }} />
        ) : staffList.length === 0 ? (
          <View style={styles.emptyState}>
            <Ionicons name="people-outline" size={60} color="#444" />
            <Text style={styles.emptyText}>You have no employees yet.</Text>
            <Text style={styles.emptySubText}>Tap the + icon in the top right to add one.</Text>
          </View>
        ) : (
          staffList.map((staff) => (
            <View key={staff.id} style={styles.staffCard}>
              <View style={styles.staffIconBox}>
                <Ionicons name="person" size={24} color="#FFF" />
              </View>
              <View style={styles.staffInfo}>
                <Text style={styles.staffHandle}>@{staff.lynk_handle}</Text>
                <Text style={styles.staffEmail}>{staff.email}</Text>
                <View style={[styles.roleBadge, { backgroundColor: staff.role === 'MANAGER' ? 'rgba(108, 99, 255, 0.2)' : 'rgba(0, 255, 204, 0.1)' }]}>
                  <Text style={[styles.roleText, { color: staff.role === 'MANAGER' ? '#6C63FF' : '#00FFCC' }]}>{staff.role}</Text>
                </View>
              </View>
              <TouchableOpacity style={styles.removeBtn} onPress={() => handleRemoveStaff(staff.id)}>
                <Ionicons name="trash-outline" size={22} color="#FF6B6B" />
              </TouchableOpacity>
            </View>
          ))
        )}
      </ScrollView>

      {/* Add Staff Modal */}
      <Modal visible={modalVisible} transparent={true} animationType="slide">
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Add Employee</Text>
              <TouchableOpacity onPress={() => setModalVisible(false)}>
                <Ionicons name="close" size={24} color="#FFF" />
              </TouchableOpacity>
            </View>

            <Text style={styles.inputLabel}>Kivo Handle or Email</Text>
            <TextInput
              style={styles.textInput}
              placeholder="e.g. jdoe or jdoe@email.com"
              placeholderTextColor="#666"
              value={identifier}
              onChangeText={setIdentifier}
              autoCapitalize="none"
            />

            <Text style={styles.inputLabel}>Role</Text>
            <View style={styles.roleSelector}>
              <TouchableOpacity 
                style={[styles.roleOption, role === 'CASHIER' && styles.roleOptionActive]}
                onPress={() => setRole('CASHIER')}
              >
                <Text style={[styles.roleOptionText, role === 'CASHIER' && styles.roleOptionTextActive]}>Cashier</Text>
              </TouchableOpacity>
              <TouchableOpacity 
                style={[styles.roleOption, role === 'MANAGER' && styles.roleOptionActive]}
                onPress={() => setRole('MANAGER')}
              >
                <Text style={[styles.roleOptionText, role === 'MANAGER' && styles.roleOptionTextActive]}>Manager</Text>
              </TouchableOpacity>
            </View>

            <Text style={styles.inputLabel}>Terminal PIN (4-6 Digits)</Text>
            <TextInput
              style={styles.textInput}
              placeholder="e.g. 1234"
              placeholderTextColor="#666"
              value={pin}
              onChangeText={setPin}
              keyboardType="number-pad"
              maxLength={6}
              secureTextEntry
            />

            <TouchableOpacity style={styles.submitBtn} onPress={handleAddStaff} disabled={addingStaff}>
              <LinearGradient colors={['#6C63FF', '#4B42E5']} style={styles.gradientBtn}>
                {addingStaff ? (
                  <ActivityIndicator size="small" color="#FFF" />
                ) : (
                  <Text style={styles.submitBtnText}>Add Employee</Text>
                )}
              </LinearGradient>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>
    </View>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0F0F1E' },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 20, paddingTop: 10, paddingBottom: 15, borderBottomWidth: 1, borderBottomColor: 'rgba(255,255,255,0.05)' },
  headerTitle: { color: '#FFF', fontSize: 20, fontWeight: 'bold' },
  headerBtn: { padding: 5 },
  contentContainer: { padding: 20, paddingBottom: 40 },
  emptyState: { alignItems: 'center', justifyContent: 'center', marginTop: 80 },
  emptyText: { color: '#FFF', fontSize: 18, fontWeight: 'bold', marginTop: 15, marginBottom: 5 },
  emptySubText: { color: '#888', fontSize: 14, textAlign: 'center' },
  staffCard: { backgroundColor: 'rgba(255,255,255,0.03)', borderRadius: 15, padding: 15, flexDirection: 'row', alignItems: 'center', marginBottom: 15, borderWidth: 1, borderColor: 'rgba(255,255,255,0.05)' },
  staffIconBox: { width: 50, height: 50, borderRadius: 25, backgroundColor: '#2A2A4A', justifyContent: 'center', alignItems: 'center', marginRight: 15 },
  staffInfo: { flex: 1 },
  staffHandle: { color: '#FFF', fontSize: 16, fontWeight: 'bold' },
  staffEmail: { color: '#888', fontSize: 13, marginBottom: 5 },
  roleBadge: { alignSelf: 'flex-start', paddingHorizontal: 8, paddingVertical: 3, borderRadius: 8 },
  roleText: { fontSize: 10, fontWeight: 'bold' },
  removeBtn: { padding: 10 },
  modalOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.7)', justifyContent: 'flex-end' },
  modalContent: { backgroundColor: '#1D1D35', borderTopLeftRadius: 30, borderTopRightRadius: 30, padding: 25, paddingBottom: 50 },
  modalHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 25 },
  modalTitle: { color: '#FFF', fontSize: 20, fontWeight: 'bold' },
  inputLabel: { color: '#888', fontSize: 13, fontWeight: 'bold', marginBottom: 8, marginTop: 15 },
  textInput: { backgroundColor: 'rgba(255,255,255,0.05)', borderRadius: 12, height: 55, paddingHorizontal: 15, color: '#FFF', fontSize: 16, borderWidth: 1, borderColor: 'rgba(255,255,255,0.1)' },
  roleSelector: { flexDirection: 'row', gap: 15 },
  roleOption: { flex: 1, height: 50, borderRadius: 12, borderWidth: 1, borderColor: 'rgba(255,255,255,0.1)', justifyContent: 'center', alignItems: 'center' },
  roleOptionActive: { borderColor: '#6C63FF', backgroundColor: 'rgba(108, 99, 255, 0.1)' },
  roleOptionText: { color: '#888', fontWeight: 'bold' },
  roleOptionTextActive: { color: '#6C63FF' },
  submitBtn: { width: '100%', height: 55, borderRadius: 15, overflow: 'hidden', marginTop: 30 },
  gradientBtn: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  submitBtnText: { color: '#FFF', fontSize: 18, fontWeight: 'bold' }
});

export default MerchantStaffScreen;
