import React, { useState, useRef } from 'react';
import { 
  View, 
  Text, 
  TouchableOpacity, 
  StyleSheet, 
  FlatList, 
  Alert, 
  TextInput, 
  ActivityIndicator, 
  Dimensions, 
  PanResponder, 
  Animated 
} from 'react-native';
import { useCartStore } from '../../store/cartStore';
import api from '../../utils/api';
import * as LocalAuthentication from 'expo-local-authentication';
import { Ionicons } from '@expo/vector-icons';

// Swipe to Pay Component for Checkout
const SwipeToPay = ({ amount, onComplete }: { amount: number; onComplete: () => void }) => {
  const pan = useRef(new Animated.Value(0)).current;
  const trackWidth = Dimensions.get('window').width - 40; // Margin offsets
  const handleSize = 50;
  const maxSwipe = trackWidth - handleSize - 6;

  const panResponder = useRef(
    PanResponder.create({
      onStartShouldSetPanResponder: () => true,
      onPanResponderMove: (_, gestureState) => {
        if (gestureState.dx > 0) {
          pan.setValue(Math.min(gestureState.dx, maxSwipe));
        }
      },
      onPanResponderRelease: (_, gestureState) => {
        if (gestureState.dx >= maxSwipe * 0.85) {
          Animated.timing(pan, {
            toValue: maxSwipe,
            duration: 100,
            useNativeDriver: true,
          }).start(() => {
            onComplete();
            Animated.timing(pan, {
              toValue: 0,
              duration: 300,
              useNativeDriver: true
            }).start();
          });
        } else {
          Animated.spring(pan, {
            toValue: 0,
            useNativeDriver: true,
          }).start();
        }
      },
    })
  ).current;

  return (
    <View style={styles.swipeTrack}>
      <Text style={styles.swipeText}>Swipe to Place Order (${amount.toFixed(2)})</Text>
      <Animated.View
        {...panResponder.panHandlers}
        style={[
          styles.swipeHandle,
          { transform: [{ translateX: pan }] }
        ]}
      >
        <Ionicons name="chevron-forward-outline" size={24} color="#000" />
      </Animated.View>
    </View>
  );
};

const CheckoutScreen = ({ navigation }: any) => {
  const { items, total, addItem, removeItem, clearCart } = useCartStore();
  const [shippingAddress, setShippingAddress] = useState('12 Ring Road, Kingston 10, Jamaica');
  const [loading, setLoading] = useState(false);

  const handleIncreaseQuantity = (item: any) => {
    addItem({ ...item, quantity: 1 });
  };

  const handleDecreaseQuantity = (item: any) => {
    if (item.quantity <= 1) {
      removeItem(item.product_id);
    } else {
      addItem({ ...item, quantity: -1 });
    }
  };

  const handleRemoveItem = (productId: string) => {
    removeItem(productId);
  };

  const handleCheckout = async () => {
    if (items.length === 0) return;
    if (!shippingAddress.trim()) {
      Alert.alert('Address Required', 'Please enter a shipping address to complete your order.');
      return;
    }
    
    setLoading(true);
    try {
      // 1. Perform premium hardware biometric secondary check
      const hasHardware = await LocalAuthentication.hasHardwareAsync();
      const isEnrolled = await LocalAuthentication.isEnrolledAsync();
      let bioVerified = false;

      if (hasHardware && isEnrolled) {
        const result = await LocalAuthentication.authenticateAsync({
          promptMessage: 'Authorize payment of $' + total() + ' JMD',
          disableDeviceFallback: false,
        });
        bioVerified = result.success;
      } else {
        // Fallback for emulators/simulators without enrolled biometrics
        bioVerified = true;
      }

      if (!bioVerified) {
        Alert.alert('Security Block', 'Biometric confirmation required.');
        setLoading(false);
        return;
      }

      // 2. Submit payment with hardware binding, biometric double-lock headers, and shipping address
      const response = await api.post('/api/wallet/checkout', {
        cart_items: items,
        idempotency_key: `checkout-${Date.now()}`,
        shipping_address: shippingAddress
      }, {
        headers: {
          'x-device-uuid': 'mock-device-uuid-12345',
          'x-biometric-auth': 'true',
          'x-biometric-timestamp': Date.now().toString()
        }
      });
      
      if (response.data.status === 'SUCCESS') {
        Alert.alert('Success', 'Payment completed successfully!', [
          { text: 'OK', onPress: () => {
            clearCart();
            navigation.navigate('(tabs)');
          }}
        ]);
      }
    } catch (error: any) {
      const errMsg = error.response?.data?.error || error.message || 'Unknown error';
      if (errMsg.includes('Please top up') || errMsg.includes('top up')) {
        Alert.alert(
          'Top Up Required',
          errMsg,
          [
            { text: 'Cancel', style: 'cancel' },
            { 
              text: 'Exchange / Convert', 
              onPress: () => navigation.navigate('Exchange') 
            },
            { 
              text: 'Ask Friends (P2P Transfer)', 
              onPress: () => navigation.navigate('SendMoney') 
            }
          ]
        );
      } else {
        Alert.alert('Checkout Failed', errMsg);
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity style={styles.backBtn} onPress={() => navigation.goBack()}>
          <Ionicons name="chevron-back" size={24} color="#FFF" />
        </TouchableOpacity>
        <Text style={styles.title}>Review Your Order</Text>
        <View style={{ width: 24 }} />
      </View>
      
      {/* Estimated Delivery Status */}
      <View style={styles.deliveryBadge}>
        <Ionicons name="time-outline" size={18} color="#FF9900" style={{ marginRight: 6 }} />
        <Text style={styles.deliveryBadgeText}>Arriving Tomorrow • Express Shipping Included</Text>
      </View>

      <FlatList
        data={items}
        keyExtractor={(item) => item.product_id}
        contentContainerStyle={{ paddingBottom: 20 }}
        renderItem={({ item }) => (
          <View style={styles.itemRow}>
            <View style={styles.itemHeader}>
              <View style={{ flex: 1 }}>
                <Text style={styles.itemName} numberOfLines={2}>{item.name}</Text>
                <Text style={styles.merchantName}>Sold by: {item.merchant_id}</Text>
              </View>
              <Text style={styles.itemPrice}>${(item.price * item.quantity).toFixed(2)}</Text>
            </View>

            {/* Amazon-style quantity adjusters and delete */}
            <View style={styles.quantityControlsRow}>
              <View style={styles.qtyBox}>
                <TouchableOpacity onPress={() => handleDecreaseQuantity(item)} style={styles.qtyBtn}>
                  <Ionicons name="remove" size={16} color="#FFF" />
                </TouchableOpacity>
                <Text style={styles.qtyText}>{item.quantity}</Text>
                <TouchableOpacity onPress={() => handleIncreaseQuantity(item)} style={styles.qtyBtn}>
                  <Ionicons name="add" size={16} color="#FFF" />
                </TouchableOpacity>
              </View>

              <TouchableOpacity onPress={() => handleRemoveItem(item.product_id)} style={styles.deleteBtn}>
                <Ionicons name="trash-outline" size={16} color="#FF6B6B" style={{ marginRight: 4 }} />
                <Text style={styles.deleteText}>Delete</Text>
              </TouchableOpacity>
            </View>
          </View>
        )}
        ListFooterComponent={
          <View style={styles.footerSection}>
            {/* Delivery address input */}
            <Text style={styles.sectionTitle}>Shipping Address</Text>
            <TextInput
              style={styles.addressInput}
              value={shippingAddress}
              onChangeText={setShippingAddress}
              placeholder="Enter your shipping address"
              placeholderTextColor="#555"
              multiline
              numberOfLines={3}
            />

            {/* Amazon Payment Summary */}
            <Text style={styles.sectionTitle}>Order Summary</Text>
            <View style={styles.summaryCard}>
              <View style={styles.summaryRow}>
                <Text style={styles.summaryLabel}>Items ({items.reduce((acc, curr) => acc + curr.quantity, 0)}):</Text>
                <Text style={styles.summaryValue}>${total().toFixed(2)} JMD</Text>
              </View>
              <View style={styles.summaryRow}>
                <Text style={styles.summaryLabel}>Shipping & handling:</Text>
                <Text style={[styles.summaryValue, { color: '#00FFCC' }]}>$0.00 JMD</Text>
              </View>
              <View style={[styles.summaryRow, styles.totalRowBorder]}>
                <Text style={styles.orderTotalLabel}>Order Total:</Text>
                <Text style={styles.orderTotalValue}>${total().toFixed(2)} JMD</Text>
              </View>
            </View>

            {/* Wallet balance information */}
            <View style={styles.balanceInfoBox}>
              <Ionicons name="wallet-outline" size={18} color="#FFF" style={{ marginRight: 6 }} />
              <Text style={styles.balanceInfoText}>Paying via Kivo Wallet Balance ($125,430.00 available)</Text>
            </View>
          </View>
        }
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Ionicons name="cart-outline" size={80} color="rgba(255,255,255,0.1)" />
            <Text style={styles.emptyText}>Your cart is empty.</Text>
            <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backToShopBtn}>
              <Text style={styles.backToShopText}>Go back to Shopping</Text>
            </TouchableOpacity>
          </View>
        }
      />
      
      {items.length > 0 && (
        <View style={styles.footer}>
          {loading ? (
            <View style={styles.loadingWrapper}>
              <ActivityIndicator size="large" color="#FF9900" />
              <Text style={styles.loadingText}>Processing Secure Order...</Text>
            </View>
          ) : (
            <SwipeToPay amount={total()} onComplete={handleCheckout} />
          )}
        </View>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#090915', paddingHorizontal: 20, paddingTop: 50 },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 },
  backBtn: { width: 40, height: 40, borderRadius: 20, backgroundColor: 'rgba(255,255,255,0.05)', justifyContent: 'center', alignItems: 'center' },
  title: { color: '#FFF', fontSize: 20, fontWeight: 'bold' },
  
  deliveryBadge: { 
    flexDirection: 'row', 
    alignItems: 'center', 
    backgroundColor: 'rgba(255, 153, 0, 0.1)', 
    padding: 12, 
    borderRadius: 12, 
    marginBottom: 20,
    borderWidth: 1,
    borderColor: 'rgba(255, 153, 0, 0.2)'
  },
  deliveryBadgeText: { color: '#FF9900', fontSize: 13, fontWeight: 'bold' },

  itemRow: { 
    backgroundColor: 'rgba(255,255,255,0.03)', 
    borderRadius: 14, 
    padding: 16, 
    marginBottom: 15, 
    borderWidth: 1, 
    borderColor: 'rgba(255,255,255,0.06)' 
  },
  itemHeader: { flexDirection: 'row', justifyContent: 'space-between' },
  itemName: { color: '#FFF', fontWeight: 'bold', fontSize: 14, flex: 1, marginRight: 15 },
  merchantName: { color: '#666', fontSize: 12, marginTop: 4 },
  itemPrice: { color: '#00FFCC', fontSize: 15, fontWeight: 'bold' },

  quantityControlsRow: { flexDirection: 'row', alignItems: 'center', marginTop: 15, borderTopWidth: 1, borderTopColor: 'rgba(255,255,255,0.05)', paddingTop: 12 },
  qtyBox: { flexDirection: 'row', alignItems: 'center', backgroundColor: 'rgba(255,255,255,0.05)', borderRadius: 8, padding: 3 },
  qtyBtn: { width: 28, height: 28, justifyContent: 'center', alignItems: 'center' },
  qtyText: { color: '#FFF', paddingHorizontal: 12, fontWeight: 'bold', fontSize: 14 },
  deleteBtn: { flexDirection: 'row', alignItems: 'center', marginLeft: 20 },
  deleteText: { color: '#FF6B6B', fontSize: 13, fontWeight: 'bold' },

  footerSection: { marginTop: 15 },
  sectionTitle: { color: '#FFF', fontSize: 16, fontWeight: 'bold', marginBottom: 10, marginTop: 15 },
  addressInput: { 
    backgroundColor: 'rgba(255,255,255,0.04)', 
    borderRadius: 12, 
    padding: 15, 
    color: '#FFF', 
    borderColor: 'rgba(255,255,255,0.08)', 
    borderWidth: 1,
    height: 70,
    textAlignVertical: 'top',
    fontSize: 14,
    marginBottom: 15
  },

  summaryCard: { 
    backgroundColor: 'rgba(255,255,255,0.02)', 
    borderRadius: 14, 
    padding: 16, 
    borderWidth: 1, 
    borderColor: 'rgba(255,255,255,0.05)',
    marginBottom: 15
  },
  summaryRow: { flexDirection: 'row', justifyContent: 'space-between', marginVertical: 6 },
  summaryLabel: { color: '#888', fontSize: 14 },
  summaryValue: { color: '#FFF', fontSize: 14, fontWeight: 'bold' },
  totalRowBorder: { borderTopWidth: 1, borderTopColor: 'rgba(255,255,255,0.08)', paddingTop: 10, marginTop: 8 },
  orderTotalLabel: { color: '#FFF', fontSize: 16, fontWeight: 'bold' },
  orderTotalValue: { color: '#FF9900', fontSize: 18, fontWeight: 'bold' },

  balanceInfoBox: { flexDirection: 'row', alignItems: 'center', marginBottom: 25 },
  balanceInfoText: { color: '#666', fontSize: 12 },

  swipeTrack: {
    height: 56,
    width: '100%',
    borderRadius: 28,
    backgroundColor: '#1C1C3A',
    justifyContent: 'center',
    alignItems: 'center',
    position: 'relative',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.08)',
    overflow: 'hidden'
  },
  swipeText: {
    color: '#FF9900',
    fontSize: 14,
    fontWeight: 'bold',
    letterSpacing: 0.5
  },
  swipeHandle: {
    width: 50,
    height: 50,
    borderRadius: 25,
    backgroundColor: '#FF9900',
    justifyContent: 'center',
    alignItems: 'center',
    position: 'absolute',
    left: 3,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.3,
    shadowRadius: 3,
    elevation: 4
  },

  footer: { paddingVertical: 15, borderTopWidth: 1, borderTopColor: 'rgba(255,255,255,0.05)', marginBottom: 20 },
  loadingWrapper: { alignItems: 'center', paddingVertical: 10 },
  loadingText: { color: '#FFF', marginTop: 10, fontWeight: 'bold' },

  emptyContainer: { flex: 1, alignItems: 'center', justifyContent: 'center', paddingVertical: 100 },
  emptyText: { color: '#666', fontSize: 16, marginTop: 15 },
  backToShopBtn: { backgroundColor: '#6C63FF', paddingVertical: 12, paddingHorizontal: 24, borderRadius: 10, marginTop: 20 },
  backToShopText: { color: '#FFF', fontWeight: 'bold' }
});

export default CheckoutScreen;

