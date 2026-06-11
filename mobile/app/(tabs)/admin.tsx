import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, SafeAreaView } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { useColorScheme } from '@/hooks/use-color-scheme';

export default function AdminScreen() {
  const colorScheme = useColorScheme();
  const isDark = colorScheme === 'dark';

  return (
    <SafeAreaView style={[styles.safeArea, { backgroundColor: isDark ? '#0F0F1E' : '#F5F5F5' }]}>
      <ScrollView style={styles.container}>
        <View style={styles.header}>
          <Text style={[styles.headerTitle, { color: isDark ? '#FFF' : '#000' }]}>Admin Dashboard</Text>
          <View style={styles.badgeContainer}>
            <Text style={styles.badgeText}>SUPER ADMIN</Text>
          </View>
        </View>

        {/* System Overview Metrics */}
        <Text style={[styles.sectionTitle, { color: isDark ? '#FFF' : '#333' }]}>Platform Metrics</Text>
        <View style={styles.metricsGrid}>
          <LinearGradient colors={['#6C63FF', '#4B42E5']} style={styles.metricCard}>
            <Ionicons name="people" size={24} color="rgba(255,255,255,0.8)" />
            <Text style={styles.metricValue}>12,408</Text>
            <Text style={styles.metricLabel}>Total Users</Text>
          </LinearGradient>
          
          <LinearGradient colors={['#FF9900', '#FF5500']} style={styles.metricCard}>
            <Ionicons name="cash" size={24} color="rgba(255,255,255,0.8)" />
            <Text style={styles.metricValue}>$1.2M</Text>
            <Text style={styles.metricLabel}>Daily Volume</Text>
          </LinearGradient>

          <LinearGradient colors={['#00FFCC', '#00A885']} style={styles.metricCard}>
            <Ionicons name="storefront" size={24} color="rgba(255,255,255,0.8)" />
            <Text style={styles.metricValue}>342</Text>
            <Text style={styles.metricLabel}>Merchants</Text>
          </LinearGradient>

          <LinearGradient colors={['#FF3366', '#D61A46']} style={styles.metricCard}>
            <Ionicons name="warning" size={24} color="rgba(255,255,255,0.8)" />
            <Text style={styles.metricValue}>15</Text>
            <Text style={styles.metricLabel}>Disputes</Text>
          </LinearGradient>
        </View>

        {/* Action Center */}
        <Text style={[styles.sectionTitle, { color: isDark ? '#FFF' : '#333' }]}>Quick Actions</Text>
        <View style={styles.actionsList}>
          
          <TouchableOpacity style={[styles.actionItem, { backgroundColor: isDark ? '#1E1E2C' : '#FFF' }]}>
            <View style={[styles.actionIcon, { backgroundColor: 'rgba(108, 99, 255, 0.2)' }]}>
              <Ionicons name="person-add" size={24} color="#6C63FF" />
            </View>
            <View style={styles.actionContent}>
              <Text style={[styles.actionTitle, { color: isDark ? '#FFF' : '#000' }]}>Approve Merchants</Text>
              <Text style={styles.actionSubtitle}>8 pending applications</Text>
            </View>
            <Ionicons name="chevron-forward" size={20} color={isDark ? '#555' : '#CCC'} />
          </TouchableOpacity>

          <TouchableOpacity style={[styles.actionItem, { backgroundColor: isDark ? '#1E1E2C' : '#FFF' }]}>
            <View style={[styles.actionIcon, { backgroundColor: 'rgba(255, 153, 0, 0.2)' }]}>
              <Ionicons name="settings" size={24} color="#FF9900" />
            </View>
            <View style={styles.actionContent}>
              <Text style={[styles.actionTitle, { color: isDark ? '#FFF' : '#000' }]}>System Settings</Text>
              <Text style={styles.actionSubtitle}>Configure fees and limits</Text>
            </View>
            <Ionicons name="chevron-forward" size={20} color={isDark ? '#555' : '#CCC'} />
          </TouchableOpacity>

          <TouchableOpacity style={[styles.actionItem, { backgroundColor: isDark ? '#1E1E2C' : '#FFF' }]}>
            <View style={[styles.actionIcon, { backgroundColor: 'rgba(0, 255, 204, 0.2)' }]}>
              <Ionicons name="document-text" size={24} color="#00A885" />
            </View>
            <View style={styles.actionContent}>
              <Text style={[styles.actionTitle, { color: isDark ? '#FFF' : '#000' }]}>Supply Manifests</Text>
              <Text style={styles.actionSubtitle}>View B2B transaction logs</Text>
            </View>
            <Ionicons name="chevron-forward" size={20} color={isDark ? '#555' : '#CCC'} />
          </TouchableOpacity>

        </View>

      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
  },
  container: {
    flex: 1,
    padding: 20,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 30,
    marginTop: 10,
  },
  headerTitle: {
    fontSize: 28,
    fontWeight: 'bold',
  },
  badgeContainer: {
    backgroundColor: '#FF3366',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 20,
  },
  badgeText: {
    color: '#FFF',
    fontSize: 12,
    fontWeight: 'bold',
    letterSpacing: 1,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 15,
    marginTop: 10,
  },
  metricsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    marginBottom: 20,
  },
  metricCard: {
    width: '48%',
    padding: 20,
    borderRadius: 20,
    marginBottom: 15,
    elevation: 5,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 5,
  },
  metricValue: {
    color: '#FFF',
    fontSize: 24,
    fontWeight: 'bold',
    marginTop: 10,
  },
  metricLabel: {
    color: 'rgba(255,255,255,0.8)',
    fontSize: 14,
    marginTop: 4,
  },
  actionsList: {
    marginBottom: 40,
  },
  actionItem: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    borderRadius: 16,
    marginBottom: 12,
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 3,
  },
  actionIcon: {
    width: 50,
    height: 50,
    borderRadius: 25,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 15,
  },
  actionContent: {
    flex: 1,
  },
  actionTitle: {
    fontSize: 16,
    fontWeight: '600',
  },
  actionSubtitle: {
    fontSize: 13,
    color: '#888',
    marginTop: 2,
  },
});
