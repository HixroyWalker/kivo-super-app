import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Dimensions, Alert } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { router, Link } from 'expo-router';
import api from '@/src/utils/api';

const { width } = Dimensions.get('window');

const WalletHomeScreen = () => {
  const [showBalance, setShowBalance] = React.useState(false);
  const [unityScore, setUnityScore] = React.useState(0);

  const [user, setUser] = React.useState<any>({});
  
  const fetchMe = async () => {
    try {
      const res = await api.get('/api/auth/me');
      if (res.data && res.data.user) {
        setUnityScore(res.data.user.unity_score || 0);
        setUser(res.data.user);
      }
    } catch (err) {
      console.error('Failed to fetch user data', err);
    }
  };

  React.useEffect(() => {
    fetchMe();
  }, []);

  const handleRepaySafetyNet = async () => {
    try {
      const response = await api.post('/wallet/safety-net/repay');
      Alert.alert('Success', response.data.message);
      fetchMe(); // Refresh UI to update balances
    } catch (error: any) {
      Alert.alert('Repayment Failed', error.response?.data?.error || 'An error occurred while repaying.');
    }
  };

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
        <Link href="/SendMoney" asChild>
          <TouchableOpacity style={styles.actionButton}>
            <View style={styles.iconCircle}><Ionicons name="send" size={24} color="#FFF" /></View>
            <Text style={styles.actionText}>Send</Text>
          </TouchableOpacity>
        </Link>
        <Link href="/ScanToPay" asChild>
          <TouchableOpacity style={styles.actionButton}>
            <View style={[styles.iconCircle, { backgroundColor: '#00FFCC' }]}><Ionicons name="qr-code" size={24} color="#000" /></View>
            <Text style={styles.actionText}>Scan</Text>
          </TouchableOpacity>
        </Link>
        <Link href="/Exchange" asChild>
          <TouchableOpacity style={styles.actionButton}>
            <View style={[styles.iconCircle, { backgroundColor: '#FFD700' }]}><Ionicons name="swap-horizontal" size={24} color="#000" /></View>
            <Text style={styles.actionText}>Exchange</Text>
          </TouchableOpacity>
        </Link>
        <Link href="/MerchantPOS" asChild>
          <TouchableOpacity style={styles.actionButton}>
            <View style={[styles.iconCircle, { backgroundColor: '#A020F0' }]}><Ionicons name="calculator-outline" size={24} color="#FFF" /></View>
            <Text style={styles.actionText}>POS</Text>
          </TouchableOpacity>
        </Link>
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

      {/* Unity Score Banner */}
      <View style={styles.unityScoreBox}>
        <Ionicons name="star" size={28} color="#FFD700" />
        <View style={{ marginLeft: 15, flex: 1 }}>
          <Text style={styles.unityScoreTitle}>Unity Score Rewards</Text>
          <Text style={styles.unityScoreText}>{unityScore} Points</Text>
        </View>
      </View>

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
          <Text style={styles.safetyValue}>${parseFloat(user.safety_net_used).toFixed(2)} / ${parseFloat(user.safety_net_limit).toFixed(2)} Used</Text>
        </View>
        <TouchableOpacity style={styles.repayButton} onPress={handleRepaySafetyNet}>
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
  actionsRow: { flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'center', gap: 15, marginVertical: 30 },
  actionButton: { alignItems: 'center', width: 65 },
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
  shopBannerSub: { color: 'rgba(255,255,255,0.9)', fontSize: 13 },
  unityScoreBox: { backgroundColor: 'rgba(255,215,0,0.1)', padding: 20, borderRadius: 20, flexDirection: 'row', alignItems: 'center', marginBottom: 30, borderWidth: 1, borderColor: 'rgba(255,215,0,0.3)' },
  unityScoreTitle: { color: '#FFD700', fontSize: 14, fontWeight: 'bold' },
  unityScoreText: { color: '#FFF', fontSize: 22, fontWeight: 'bold' }
});

export default WalletHomeScreen;
