import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Dimensions } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { router } from 'expo-router';

const { width } = Dimensions.get('window');

const WalletHomeScreen = () => {
  const [showBalance, setShowBalance] = React.useState(false);

  return (
    <ScrollView style={styles.container}>
      {/* Premium Balance Card */}
      <TouchableOpacity onPress={() => setShowBalance(!showBalance)} activeOpacity={0.9}>
        <LinearGradient colors={['#6C63FF', '#4B42E5']} style={styles.balanceCard}>
          <View style={styles.headerRow}>
            <Text style={styles.balanceLabel}>Main Balance (JMD)</Text>
            <Ionicons name={showBalance ? 'eye-outline' : 'eye-off-outline'} size={20} color="rgba(255,255,255,0.7)" />
          </View>
          <Text style={styles.balanceAmount}>
            {showBalance ? '$125,430.00' : '••••••••'}
          </Text>
          <View style={styles.cardFooter}>
            <Text style={styles.cardNumber}>•••• •••• •••• 4839</Text>
            <Text style={styles.cardType}>KIVO PRIME</Text>
          </View>
        </LinearGradient>
      </TouchableOpacity>

      {/* Quick Actions */}
      <View style={styles.actionsRow}>
        <TouchableOpacity style={styles.actionButton} onPress={() => router.push('/SendMoney')}>
          <View style={styles.iconCircle}><Ionicons name="send" size={24} color="#FFF" /></View>
          <Text style={styles.actionText}>Send</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.actionButton} onPress={() => router.push('/ScanToPay')}>
          <View style={[styles.iconCircle, { backgroundColor: '#00FFCC' }]}><Ionicons name="qr-code" size={24} color="#000" /></View>
          <Text style={styles.actionText}>Scan</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.actionButton} onPress={() => router.push('/Exchange')}>
          <View style={[styles.iconCircle, { backgroundColor: '#FFD700' }]}><Ionicons name="swap-horizontal" size={24} color="#000" /></View>
          <Text style={styles.actionText}>Exchange</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.actionButton} onPress={() => router.push('/MerchantPOS')}>
          <View style={[styles.iconCircle, { backgroundColor: '#A020F0' }]}><Ionicons name="calculator-outline" size={24} color="#FFF" /></View>
          <Text style={styles.actionText}>POS</Text>
        </TouchableOpacity>
      </View>

      {/* Shop & Tickets Banner */}
      <TouchableOpacity onPress={() => router.push('/ShopTickets')} activeOpacity={0.9} style={styles.shopBanner}>
        <LinearGradient colors={['#FF9900', '#FF5500']} style={styles.shopBannerGradient} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }}>
          <View>
            <Text style={styles.shopBannerTitle}>Shop & Tickets</Text>
            <Text style={styles.shopBannerSub}>Buy products, event passes, and more!</Text>
          </View>
          <Ionicons name="cart" size={36} color="#FFF" />
        </LinearGradient>
      </TouchableOpacity>

      {/* Currency Balances */}
      <Text style={styles.sectionTitle}>Global Accounts</Text>
      <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.currencyScroll}>
        <View style={styles.currencyCard}>
          <Text style={styles.currencyLabel}>USD Account</Text>
          <Text style={styles.currencyValue}>$840.20</Text>
        </View>
        <View style={styles.currencyCard}>
          <Text style={styles.currencyLabel}>CAD Account</Text>
          <Text style={styles.currencyValue}>$1,120.00</Text>
        </View>
        <View style={styles.currencyCard}>
          <Text style={styles.currencyLabel}>GBP Account</Text>
          <Text style={styles.currencyValue}>£450.50</Text>
        </View>
      </ScrollView>

      {/* Safety Net Status */}
      <View style={styles.safetyNetBox}>
        <View>
          <Text style={styles.safetyLabel}>Safety Net Credit</Text>
          <Text style={styles.safetyValue}>$15,000 / $50,000 Used</Text>
        </View>
        <TouchableOpacity style={styles.repayButton}>
          <Text style={styles.repayText}>Repay Now</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0F0F1E', padding: 20 },
  balanceCard: { width: '100%', height: 200, borderRadius: 25, padding: 25, justifyContent: 'space-between', elevation: 10 },
  headerRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  balanceLabel: { color: 'rgba(255,255,255,0.7)', fontSize: 16 },
  balanceAmount: { color: '#FFF', fontSize: 36, fontWeight: 'bold' },
  cardFooter: { flexDirection: 'row', justifyContent: 'space-between' },
  cardNumber: { color: 'rgba(255,255,255,0.8)', fontSize: 14 },
  cardType: { color: '#FFF', fontWeight: 'bold', letterSpacing: 2 },
  actionsRow: { flexDirection: 'row', justifyContent: 'space-around', marginVertical: 30 },
  actionButton: { alignItems: 'center' },
  iconCircle: { width: 55, height: 55, borderRadius: 28, backgroundColor: '#6C63FF', justifyContent: 'center', alignItems: 'center', marginBottom: 8 },
  actionText: { color: '#FFF', fontWeight: 'bold' },
  sectionTitle: { color: '#FFF', fontSize: 20, fontWeight: 'bold', marginBottom: 15 },
  currencyScroll: { marginBottom: 30 },
  currencyCard: { width: 140, height: 80, backgroundColor: 'rgba(255,255,255,0.05)', borderRadius: 15, padding: 15, marginRight: 15 },
  currencyLabel: { color: '#999', fontSize: 12 },
  currencyValue: { color: '#FFF', fontSize: 18, fontWeight: 'bold', marginTop: 5 },
  safetyNetBox: { backgroundColor: 'rgba(255, 107, 107, 0.1)', padding: 20, borderRadius: 20, flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  safetyLabel: { color: '#FF6B6B', fontWeight: 'bold' },
  safetyValue: { color: '#FFF', fontSize: 14 },
  repayButton: { backgroundColor: '#FF6B6B', paddingVertical: 8, paddingHorizontal: 15, borderRadius: 10 },
  repayText: { color: '#FFF', fontWeight: 'bold' },
  shopBanner: { marginBottom: 30, borderRadius: 20, overflow: 'hidden', shadowColor: '#FF9900', shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.3, shadowRadius: 5, elevation: 5 },
  shopBannerGradient: { padding: 20, flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  shopBannerTitle: { color: '#FFF', fontSize: 18, fontWeight: 'bold', marginBottom: 5 },
  shopBannerSub: { color: 'rgba(255,255,255,0.9)', fontSize: 13 }
});

export default WalletHomeScreen;
