import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, ActivityIndicator, Alert } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import api from '@/src/utils/api';

const MerchantLocationsScreen = () => {
  const router = useRouter();
  const [locations, setLocations] = useState<any[]>([]);
  const [totalNetworkSales, setTotalNetworkSales] = useState(0);
  const [loading, setLoading] = useState(false);

  const fetchLocations = async () => {
    setLoading(true);
    try {
      const res = await api.get('/wallet/merchant/locations');
      setLocations(res.data.locations || []);
      setTotalNetworkSales(res.data.total_network_sales || 0);
    } catch (err: any) {
      console.error(err);
      Alert.alert('Error', err.response?.data?.error || 'Failed to fetch locations.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchLocations();
  }, []);

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.headerBtn}>
          <Ionicons name="arrow-back" size={24} color="#FFF" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Network Overview</Text>
        <View style={styles.headerBtn} />
      </View>

      <ScrollView contentContainerStyle={styles.contentContainer}>
        {/* Network Total Summary */}
        <LinearGradient colors={['#2A2A4A', '#1D1D35']} style={styles.summaryCard} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }}>
          <Text style={styles.summaryLabel}>Total Network Sales</Text>
          <Text style={styles.summaryValue}>${totalNetworkSales.toLocaleString('en-JM', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</Text>
          <View style={styles.summaryMetaRow}>
            <View style={styles.metaBadge}>
              <Ionicons name="business" size={14} color="#6C63FF" />
              <Text style={styles.metaText}>{locations.length} Locations</Text>
            </View>
          </View>
        </LinearGradient>

        <Text style={styles.sectionTitle}>Your Locations</Text>

        {loading ? (
          <ActivityIndicator size="large" color="#6C63FF" style={{ marginTop: 50 }} />
        ) : locations.length === 0 ? (
          <View style={styles.emptyState}>
            <Ionicons name="storefront-outline" size={60} color="#444" />
            <Text style={styles.emptyText}>No locations found.</Text>
            <Text style={styles.emptySubText}>Register a business to get started.</Text>
          </View>
        ) : (
          locations.map((loc) => (
            <View key={loc.id} style={styles.locationCard}>
              <View style={styles.locationHeader}>
                <View style={styles.locationIconBox}>
                  <Ionicons name="storefront" size={24} color="#FFF" />
                </View>
                <View style={{ flex: 1 }}>
                  <Text style={styles.locationName}>{loc.business_name}</Text>
                  <Text style={[styles.statusText, { color: loc.is_approved ? '#00FFCC' : '#FF9900' }]}>
                    {loc.is_approved ? 'Active' : 'Pending Approval'}
                  </Text>
                </View>
              </View>
              
              <View style={styles.locationStatsRow}>
                <View style={styles.statBox}>
                  <Text style={styles.statLabel}>Total Sales</Text>
                  <Text style={styles.statValue}>${loc.total_sales.toLocaleString('en-JM', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</Text>
                </View>
                <View style={styles.statDivider} />
                <View style={styles.statBox}>
                  <Text style={styles.statLabel}>Staff</Text>
                  <Text style={styles.statValue}>{loc.staff_count}</Text>
                </View>
              </View>
            </View>
          ))
        )}
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0F0F1E' },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 20, paddingTop: 10, paddingBottom: 15, borderBottomWidth: 1, borderBottomColor: 'rgba(255,255,255,0.05)' },
  headerTitle: { color: '#FFF', fontSize: 20, fontWeight: 'bold' },
  headerBtn: { padding: 5, width: 40 },
  contentContainer: { padding: 20, paddingBottom: 40 },
  summaryCard: { borderRadius: 20, padding: 25, marginBottom: 25, borderWidth: 1, borderColor: 'rgba(108, 99, 255, 0.2)', shadowColor: '#000', shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.3, shadowRadius: 5, elevation: 5 },
  summaryLabel: { color: '#888', fontSize: 14, fontWeight: 'bold', marginBottom: 5 },
  summaryValue: { color: '#FFF', fontSize: 36, fontWeight: 'bold', marginBottom: 15 },
  summaryMetaRow: { flexDirection: 'row', gap: 10 },
  metaBadge: { flexDirection: 'row', alignItems: 'center', backgroundColor: 'rgba(108, 99, 255, 0.1)', paddingHorizontal: 10, paddingVertical: 5, borderRadius: 10, gap: 5 },
  metaText: { color: '#6C63FF', fontSize: 12, fontWeight: 'bold' },
  sectionTitle: { color: '#FFF', fontSize: 18, fontWeight: 'bold', marginBottom: 15 },
  emptyState: { alignItems: 'center', justifyContent: 'center', marginTop: 40 },
  emptyText: { color: '#FFF', fontSize: 18, fontWeight: 'bold', marginTop: 15, marginBottom: 5 },
  emptySubText: { color: '#888', fontSize: 14, textAlign: 'center' },
  locationCard: { backgroundColor: 'rgba(255,255,255,0.03)', borderRadius: 15, padding: 20, marginBottom: 15, borderWidth: 1, borderColor: 'rgba(255,255,255,0.05)' },
  locationHeader: { flexDirection: 'row', alignItems: 'center', marginBottom: 20 },
  locationIconBox: { width: 50, height: 50, borderRadius: 15, backgroundColor: '#6C63FF', justifyContent: 'center', alignItems: 'center', marginRight: 15 },
  locationName: { color: '#FFF', fontSize: 18, fontWeight: 'bold', marginBottom: 3 },
  statusText: { fontSize: 13, fontWeight: 'bold' },
  locationStatsRow: { flexDirection: 'row', backgroundColor: 'rgba(0,0,0,0.2)', borderRadius: 12, padding: 15 },
  statBox: { flex: 1, justifyContent: 'center' },
  statDivider: { width: 1, backgroundColor: 'rgba(255,255,255,0.1)', marginHorizontal: 15 },
  statLabel: { color: '#888', fontSize: 12, fontWeight: 'bold', marginBottom: 5 },
  statValue: { color: '#FFF', fontSize: 16, fontWeight: 'bold' }
});

export default MerchantLocationsScreen;
