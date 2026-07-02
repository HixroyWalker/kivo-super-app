import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, TextInput, Alert, ActivityIndicator } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { router } from 'expo-router';
import api from '@/src/utils/api';

const AdminDashboardScreen = () => {
  const [activeTab, setActiveTab] = useState('overview'); // overview, settings, merchants
  
  // Data States
  const [stats, setStats] = useState({ users: 0, merchants: 0, transactionCount: 0, transactionVolume: 0 });
  const [settings, setSettings] = useState<any[]>([]);
  const [pendingMerchants, setPendingMerchants] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  // Edit Setting State
  const [editingSetting, setEditingSetting] = useState<any>(null);
  const [editValue, setEditValue] = useState('');

  const fetchData = async () => {
    setLoading(true);
    try {
      if (activeTab === 'overview') {
        const res = await api.get('/api/admin/stats');
        setStats(res.data);
      } else if (activeTab === 'settings') {
        const res = await api.get('/api/admin/settings');
        setSettings(res.data);
      } else if (activeTab === 'merchants') {
        const res = await api.get('/api/admin/merchants/pending');
        setPendingMerchants(res.data);
      }
    } catch (err: any) {
      Alert.alert('Error', err.response?.data?.error || 'Failed to fetch admin data.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [activeTab]);

  const handleUpdateSetting = async () => {
    try {
      await api.post('/api/admin/settings', { key: editingSetting.key, value: editValue });
      Alert.alert('Success', 'Setting updated successfully');
      setEditingSetting(null);
      fetchData();
    } catch (err: any) {
      Alert.alert('Error', err.response?.data?.error || 'Failed to update setting');
    }
  };

  const handleApproveMerchant = async (id: string) => {
    try {
      await api.post(`/api/admin/merchants/${id}/approve`);
      Alert.alert('Success', 'Merchant approved successfully');
      fetchData();
    } catch (err: any) {
      Alert.alert('Error', err.response?.data?.error || 'Failed to approve merchant');
    }
  };

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={() => router.back()}>
          <Ionicons name="chevron-back" size={24} color="#FFF" />
          <Text style={styles.backButtonText}>Back</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Admin Panel</Text>
        <View style={{ width: 60 }} />
      </View>

      {/* Tabs */}
      <View style={styles.tabContainer}>
        <TouchableOpacity style={[styles.tab, activeTab === 'overview' && styles.activeTab]} onPress={() => setActiveTab('overview')}>
          <Text style={[styles.tabText, activeTab === 'overview' && styles.activeTabText]}>Overview</Text>
        </TouchableOpacity>
        <TouchableOpacity style={[styles.tab, activeTab === 'settings' && styles.activeTab]} onPress={() => setActiveTab('settings')}>
          <Text style={[styles.tabText, activeTab === 'settings' && styles.activeTabText]}>Fees</Text>
        </TouchableOpacity>
        <TouchableOpacity style={[styles.tab, activeTab === 'merchants' && styles.activeTab]} onPress={() => setActiveTab('merchants')}>
          <Text style={[styles.tabText, activeTab === 'merchants' && styles.activeTabText]}>Approvals</Text>
        </TouchableOpacity>
      </View>

      {/* Content */}
      <ScrollView style={styles.content}>
        {loading ? (
          <ActivityIndicator size="large" color="#6C63FF" style={{ marginTop: 50 }} />
        ) : (
          <>
            {activeTab === 'overview' && (
              <View style={styles.grid}>
                <View style={styles.card}>
                  <Text style={styles.cardTitle}>Total Users</Text>
                  <Text style={styles.cardValue}>{stats.users}</Text>
                </View>
                <View style={styles.card}>
                  <Text style={styles.cardTitle}>Total Merchants</Text>
                  <Text style={styles.cardValue}>{stats.merchants}</Text>
                </View>
                <View style={styles.card}>
                  <Text style={styles.cardTitle}>Transactions</Text>
                  <Text style={styles.cardValue}>{stats.transactionCount}</Text>
                </View>
                <View style={styles.card}>
                  <Text style={styles.cardTitle}>Total Volume</Text>
                  <Text style={styles.cardValue}>${stats.transactionVolume.toLocaleString()} JMD</Text>
                </View>
              </View>
            )}

            {activeTab === 'settings' && (
              <View>
                {settings.map(s => (
                  <View key={s.key} style={styles.listItem}>
                    {editingSetting?.key === s.key ? (
                      <View style={{ flex: 1 }}>
                        <Text style={styles.listTitle}>{s.key}</Text>
                        <TextInput 
                          style={styles.input} 
                          value={editValue} 
                          onChangeText={setEditValue} 
                          keyboardType="decimal-pad" 
                          autoFocus 
                        />
                        <View style={{ flexDirection: 'row', marginTop: 10, gap: 10 }}>
                          <TouchableOpacity style={styles.btnSave} onPress={handleUpdateSetting}>
                            <Text style={styles.btnText}>Save</Text>
                          </TouchableOpacity>
                          <TouchableOpacity style={styles.btnCancel} onPress={() => setEditingSetting(null)}>
                            <Text style={styles.btnText}>Cancel</Text>
                          </TouchableOpacity>
                        </View>
                      </View>
                    ) : (
                      <>
                        <View style={{ flex: 1 }}>
                          <Text style={styles.listTitle}>{s.key}</Text>
                          <Text style={styles.listSubtitle}>{s.value}</Text>
                        </View>
                        <TouchableOpacity style={styles.btnEdit} onPress={() => { setEditingSetting(s); setEditValue(s.value); }}>
                          <Text style={styles.btnText}>Edit</Text>
                        </TouchableOpacity>
                      </>
                    )}
                  </View>
                ))}
              </View>
            )}

            {activeTab === 'merchants' && (
              <View>
                {pendingMerchants.length === 0 ? (
                  <Text style={{ color: '#888', textAlign: 'center', marginTop: 20 }}>No pending merchants to approve.</Text>
                ) : (
                  pendingMerchants.map(m => (
                    <View key={m.id} style={styles.listItem}>
                      <View style={{ flex: 1 }}>
                        <Text style={styles.listTitle}>{m.business_name}</Text>
                        <Text style={styles.listSubtitle}>Type: {m.business_type} | Handle: @{m.owner?.lynk_handle}</Text>
                      </View>
                      <TouchableOpacity style={styles.btnSave} onPress={() => handleApproveMerchant(m.id)}>
                        <Text style={styles.btnText}>Approve</Text>
                      </TouchableOpacity>
                    </View>
                  ))
                )}
              </View>
            )}
          </>
        )}
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0F0F1E', paddingTop: 50 },
  header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 20, marginBottom: 20 },
  backButton: { flexDirection: 'row', alignItems: 'center' },
  backButtonText: { color: '#FFF', fontSize: 16, marginLeft: 5 },
  headerTitle: { color: '#FFF', fontSize: 20, fontWeight: 'bold' },
  tabContainer: { flexDirection: 'row', paddingHorizontal: 20, marginBottom: 20, borderBottomWidth: 1, borderBottomColor: 'rgba(255,255,255,0.1)' },
  tab: { flex: 1, paddingVertical: 10, alignItems: 'center' },
  activeTab: { borderBottomWidth: 2, borderBottomColor: '#6C63FF' },
  tabText: { color: '#888', fontWeight: 'bold' },
  activeTabText: { color: '#FFF' },
  content: { flex: 1, paddingHorizontal: 20 },
  grid: { flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'space-between' },
  card: { width: '48%', backgroundColor: 'rgba(255,255,255,0.05)', borderRadius: 15, padding: 20, marginBottom: 15 },
  cardTitle: { color: '#888', fontSize: 12, marginBottom: 10 },
  cardValue: { color: '#FFF', fontSize: 20, fontWeight: 'bold' },
  listItem: { flexDirection: 'row', alignItems: 'center', backgroundColor: 'rgba(255,255,255,0.05)', padding: 15, borderRadius: 12, marginBottom: 10 },
  listTitle: { color: '#FFF', fontWeight: 'bold', fontSize: 16 },
  listSubtitle: { color: '#888', fontSize: 13, marginTop: 4 },
  btnEdit: { backgroundColor: 'rgba(255,255,255,0.1)', paddingHorizontal: 15, paddingVertical: 8, borderRadius: 8 },
  btnSave: { backgroundColor: '#6C63FF', paddingHorizontal: 15, paddingVertical: 8, borderRadius: 8 },
  btnCancel: { backgroundColor: '#FF6B6B', paddingHorizontal: 15, paddingVertical: 8, borderRadius: 8 },
  btnText: { color: '#FFF', fontWeight: 'bold', fontSize: 12 },
  input: { backgroundColor: 'rgba(255,255,255,0.1)', color: '#FFF', padding: 10, borderRadius: 8, marginTop: 10 }
});

export default AdminDashboardScreen;
