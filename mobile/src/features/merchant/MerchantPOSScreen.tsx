import React, { useState, useEffect } from 'react';
import { 
  View, 
  Text, 
  TextInput, 
  TouchableOpacity, 
  StyleSheet, 
  Modal, 
  FlatList, 
  Image, 
  Alert, 
  ActivityIndicator,
  Dimensions,
  SafeAreaView
} from 'react-native';
import QRCode from 'react-native-qrcode-svg';
import { Ionicons } from '@expo/vector-icons';
import { router } from 'expo-router';
import * as ImagePicker from 'expo-image-picker';
import { CameraView, useCameraPermissions } from 'expo-camera';
import api from '@/src/utils/api';

const { width, height } = Dimensions.get('window');

interface Product {
  id: string;
  name: string;
  price: string;
  image_url: string;
  barcode?: string;
  stock_quantity?: number;
}

interface Transaction {
  id: string;
  amount: string;
  status: string;
  created_at: string;
}

const MerchantPOSScreen = () => {
  // PIN Verification States
  const [isPinVerified, setIsPinVerified] = useState(false);
  const [enteredPin, setEnteredPin] = useState('');
  const [pinError, setPinError] = useState('');
  const [verifyingPin, setVerifyingPin] = useState(false);

  // Amount & QR
  const [amount, setAmount] = useState('0.00');
  const [showQR, setShowQR] = useState(false);
  const [qrValue, setQrValue] = useState('');

  // Catalog / Inventory States
  const [products, setProducts] = useState<Product[]>([]);
  const [loadingProducts, setLoadingProducts] = useState(false);
  const [showInventoryModal, setShowInventoryModal] = useState(false);

  // New Inventory Item States
  const [newItemName, setNewItemName] = useState('');
  const [newItemPrice, setNewItemPrice] = useState('');
  const [newItemImage, setNewItemImage] = useState<string | null>(null);
  const [newItemBarcode, setNewItemBarcode] = useState('');
  const [newItemStock, setNewItemStock] = useState('');
  const [creatingItem, setCreatingItem] = useState(false);

  // Camera & Barcode States
  const [permission, requestPermission] = useCameraPermissions();
  const [scanningMode, setScanningMode] = useState<'NONE' | 'POS' | 'INVENTORY'>('NONE');

  // Order History & Refunds
  const [showOrderHistoryModal, setShowOrderHistoryModal] = useState(false);
  const [orders, setOrders] = useState<Transaction[]>([]);
  const [loadingOrders, setLoadingOrders] = useState(false);
  const [refundingTx, setRefundingTx] = useState<string | null>(null);

  // Loyalty Settings
  const [showLoyaltyModal, setShowLoyaltyModal] = useState(false);
  const [loyaltyRate, setLoyaltyRate] = useState('1');

  const handleBarcodeScanned = ({ type, data }: any) => {
    if (scanningMode === 'POS') {
      const prod = products.find(p => p.barcode === data);
      if (prod) {
        handleProductTap(prod);
        Alert.alert('Scanned', `Added ${prod.name} to cart.`);
      } else {
        Alert.alert('Not Found', 'Product with this barcode not found in inventory.');
      }
      setScanningMode('NONE');
    } else if (scanningMode === 'INVENTORY') {
      setNewItemBarcode(data);
      setScanningMode('NONE');
    }
  };

  const handleVerifyPin = async (pinValue: string) => {
    setVerifyingPin(true);
    setPinError('');
    try {
      const res = await api.post('/api/wallet/staff/verify-pin', { pin: pinValue });
      if (res.data.success) {
        setIsPinVerified(true);
      }
    } catch (err: any) {
      setPinError(err.response?.data?.error || 'Invalid PIN. Try 1234.');
      setEnteredPin('');
    } finally {
      setVerifyingPin(false);
    }
  };

  const handleKeyPress = (num: string) => {
    if (enteredPin.length >= 4) return;
    const nextPin = enteredPin + num;
    setEnteredPin(nextPin);
    if (nextPin.length === 4) {
      handleVerifyPin(nextPin);
    }
  };

  const handleDeletePress = () => {
    setEnteredPin(enteredPin.slice(0, -1));
  };

  // Fetch Products Catalog
  const fetchProducts = async () => {
    setLoadingProducts(true);
    try {
      const res = await api.get('/api/wallet/products');
      setProducts(res.data);
    } catch (err) {
      console.error('Error fetching catalog:', err);
    } finally {
      setLoadingProducts(false);
    }
  };

  const fetchOrders = async () => {
    setLoadingOrders(true);
    try {
      const res = await api.get('/api/wallet/transactions');
      setOrders(res.data);
    } catch (err) {
      console.error('Error fetching orders:', err);
    } finally {
      setLoadingOrders(false);
    }
  };

  const handleRefund = async (txId: string) => {
    setRefundingTx(txId);
    try {
      await api.post(`/api/wallet/transactions/${txId}/refund`);
      Alert.alert('Success', 'Transaction successfully refunded.');
      fetchOrders();
      fetchProducts(); // Refresh stock
    } catch (err: any) {
      Alert.alert('Refund Error', err.response?.data?.error || 'Failed to refund transaction.');
    } finally {
      setRefundingTx(null);
    }
  };

  const [updatingLoyalty, setUpdatingLoyalty] = useState(false);
  const handleUpdateLoyalty = async () => {
    setUpdatingLoyalty(true);
    try {
      await api.post('/api/wallet/merchant/loyalty', { loyalty_rate: loyaltyRate });
      Alert.alert('Success', `Loyalty rate updated to ${loyaltyRate} points per $100`);
      setShowLoyaltyModal(false);
    } catch (err: any) {
      Alert.alert('Error', err.response?.data?.error || 'Failed to update loyalty rate.');
    } finally {
      setUpdatingLoyalty(false);
    }
  };

  useEffect(() => {
    fetchProducts();
  }, []);

  // Image Picking
  const pickImage = async () => {
    const { status } = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (status !== 'granted') {
      Alert.alert('Permission Required', 'Permissions to access camera roll are required to select a product picture.');
      return;
    }

    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      allowsEditing: true,
      aspect: [1, 1],
      quality: 0.8,
    });

    if (!result.canceled && result.assets && result.assets.length > 0) {
      setNewItemImage(result.assets[0].uri);
    }
  };

  // Add Item to POS Amount
  const handleProductTap = (prod: Product) => {
    const itemPrice = parseFloat(prod.price) || 0;
    const currentAmt = parseFloat(amount) || 0;
    setAmount((currentAmt + itemPrice).toFixed(2));
  };

  // Reset Total Amount
  const handleClearTotal = () => {
    setAmount('0.00');
  };

  // Create Product Submit
  const handleCreateProduct = async () => {
    if (!newItemName.trim()) {
      Alert.alert('Name Required', 'Please enter a product name.');
      return;
    }
    if (isNaN(parseFloat(newItemPrice)) || parseFloat(newItemPrice) <= 0) {
      Alert.alert('Invalid Price', 'Please enter a valid price greater than zero.');
      return;
    }

    setCreatingItem(true);
    try {
      const payload = {
        name: newItemName,
        price: parseFloat(newItemPrice),
        image_url: newItemImage || 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=300&q=80',
        barcode: newItemBarcode || undefined,
        stock_quantity: parseInt(newItemStock, 10) || 0
      };

      await api.post('/api/wallet/products', payload);
      Alert.alert('Success', 'Product successfully created and added to inventory catalog.');
      
      // Reset & Refresh
      setNewItemName('');
      setNewItemPrice('');
      setNewItemImage(null);
      setNewItemBarcode('');
      setNewItemStock('');
      setShowInventoryModal(false);
      fetchProducts();
    } catch (err: any) {
      Alert.alert('Error', err.response?.data?.error || 'Failed to create inventory item.');
    } finally {
      setCreatingItem(false);
    }
  };

  // Generate Payment QR for Customer
  const generatePaymentQR = () => {
    const numAmt = parseFloat(amount);
    if (isNaN(numAmt) || numAmt <= 0) {
      Alert.alert('Invalid Amount', 'Please input a total amount before generating QR payment code.');
      return;
    }
    
    const data = JSON.stringify({
      type: 'MERCHANT_PAY',
      id: 'merchant-id-123', // Hardcoded merchant ID for the demonstration
      amount: numAmt,
      timestamp: Date.now()
    });
    
    setQrValue(data);
    setShowQR(true);
  };

  if (!isPinVerified) {
    return (
      <SafeAreaView style={styles.pinContainer}>
        {/* Header with exit option */}
        <View style={styles.pinHeader}>
          <TouchableOpacity style={styles.backButton} onPress={() => {
          if (router.canGoBack()) {
            router.back();
          } else {
            router.replace('/');
          }
        }}>
            <Ionicons name="chevron-back" size={24} color="#FFF" />
            <Text style={styles.backButtonText}>Exit</Text>
          </TouchableOpacity>
        </View>

        <View style={styles.pinContent}>
          <Ionicons name="lock-closed-outline" size={48} color="#6C63FF" style={{ marginBottom: 15 }} />
          <Text style={styles.pinTitle}>Merchant Staff Lock</Text>
          <Text style={styles.pinSubtitle}>Enter cashier or manager authorization PIN</Text>

          {/* Dots indicating pin length */}
          <View style={styles.dotsContainer}>
            {[1, 2, 3, 4].map((i) => (
              <View 
                key={i} 
                style={[
                  styles.dot, 
                  enteredPin.length >= i ? styles.activeDot : null,
                  pinError ? styles.errorDot : null
                ]} 
              />
            ))}
          </View>

          {pinError ? (
            <Text style={styles.pinErrorText}>{pinError}</Text>
          ) : verifyingPin ? (
            <ActivityIndicator size="small" color="#00FFCC" style={{ marginVertical: 10 }} />
          ) : (
            <Text style={styles.pinHelpText}>Default simulation PIN: 1234</Text>
          )}

          {/* Keypad */}
          <View style={styles.keypadGrid}>
            {['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((num) => (
              <TouchableOpacity 
                key={num} 
                style={styles.keypadButton}
                onPress={() => handleKeyPress(num)}
              >
                <Text style={styles.keypadButtonText}>{num}</Text>
              </TouchableOpacity>
            ))}
            <TouchableOpacity 
              style={styles.keypadButton} 
              onPress={() => setEnteredPin('')}
            >
              <Text style={styles.keypadActionText}>C</Text>
            </TouchableOpacity>
            <TouchableOpacity 
              style={styles.keypadButton}
              onPress={() => handleKeyPress('0')}
            >
              <Text style={styles.keypadButtonText}>0</Text>
            </TouchableOpacity>
            <TouchableOpacity 
              style={styles.keypadButton}
              onPress={handleDeletePress}
            >
              <Ionicons name="backspace-outline" size={24} color="#FFF" />
            </TouchableOpacity>
          </View>
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      {/* Premium Navigation Header */}
      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={() => {
          if (router.canGoBack()) {
            router.back();
          } else {
            router.replace('/');
          }
        }}>
          <Ionicons name="chevron-back" size={24} color="#FFF" />
          <Text style={styles.backButtonText}>Back</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Merchant Terminal</Text>
        <View style={{ flexDirection: 'row', gap: 10 }}>
          <TouchableOpacity style={styles.addInventoryBtn} onPress={() => router.push('/MerchantLocations')}>
            <Ionicons name="business-outline" size={22} color="#FF9900" />
          </TouchableOpacity>
          <TouchableOpacity style={styles.addInventoryBtn} onPress={() => router.push('/MerchantStaff')}>
            <Ionicons name="people-outline" size={22} color="#6C63FF" />
          </TouchableOpacity>
          <TouchableOpacity style={styles.addInventoryBtn} onPress={() => setShowLoyaltyModal(true)}>
            <Ionicons name="star" size={22} color="#00FFCC" />
            <Text style={styles.addInventoryBtnText}>Loyalty</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.addInventoryBtn} onPress={() => { setShowOrderHistoryModal(true); fetchOrders(); }}>
            <Ionicons name="list" size={22} color="#00FFCC" />
            <Text style={styles.addInventoryBtnText}>Orders</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.addInventoryBtn} onPress={() => setShowInventoryModal(true)}>
            <Ionicons name="add" size={22} color="#00FFCC" />
            <Text style={styles.addInventoryBtnText}>Item</Text>
          </TouchableOpacity>
        </View>
      </View>

      {/* POS Amount Display Panel */}
      <View style={styles.displayArea}>
        <View style={styles.displayRow}>
          <Text style={styles.currencyLabel}>JMD</Text>
          <TouchableOpacity onPress={handleClearTotal} style={styles.clearBtn}>
            <Text style={styles.clearBtnText}>CLEAR</Text>
          </TouchableOpacity>
        </View>
        <TextInput
          style={styles.amountInput}
          value={amount}
          onChangeText={setAmount}
          placeholder="0.00"
          placeholderTextColor="#444"
          keyboardType="decimal-pad"
        />
      </View>

      {/* Dynamic Products Grid Section */}
      <View style={styles.catalogSection}>
        <Text style={styles.sectionHeading}>Fast Catalog Selector (Tap to Add)</Text>
        {loadingProducts ? (
          <View style={styles.loadingContainer}>
            <ActivityIndicator size="small" color="#6C63FF" />
            <Text style={styles.loadingText}>Fetching inventory...</Text>
          </View>
        ) : (
          <FlatList
            data={products}
            keyExtractor={(item) => item.id}
            numColumns={3}
            contentContainerStyle={styles.gridContainer}
            ListEmptyComponent={
              <View style={styles.emptyCatalogContainer}>
                <Ionicons name="cube-outline" size={32} color="rgba(255,255,255,0.2)" />
                <Text style={styles.emptyCatalogText}>Catalog empty. Add items using the top-right button.</Text>
              </View>
            }
            renderItem={({ item }) => (
              <TouchableOpacity 
                style={styles.gridCard}
                onPress={() => handleProductTap(item)}
              >
                <Image 
                  source={{ uri: item.image_url || 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=300&q=80' }} 
                  style={styles.gridImage}
                  resizeMode="cover"
                />
                <View style={styles.gridCardDetails}>
                  <Text style={styles.gridCardName} numberOfLines={1}>{item.name}</Text>
                  <Text style={styles.gridCardPrice}>${parseFloat(item.price).toFixed(0)}</Text>
                </View>
              </TouchableOpacity>
            )}
          />
        )}
      </View>

      {/* Action Row */}
      <View style={styles.actionSection}>
        <TouchableOpacity style={styles.scanButton} onPress={() => {
          if (!permission?.granted) requestPermission();
          else setScanningMode('POS');
        }}>
          <Ionicons name="barcode-outline" size={24} color="#FFF" />
          <Text style={styles.scanButtonText}>Scan Barcode</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.payButton} onPress={generatePaymentQR}>
          <Ionicons name="qr-code-outline" size={24} color="#000" />
          <Text style={styles.payButtonText}>Generate Payment QR</Text>
        </TouchableOpacity>
      </View>

      {/* Customer QR Scan Modal */}
      <Modal visible={showQR} transparent animationType="slide">
        <View style={styles.modalBgContainer}>
          <View style={styles.qrCard}>
            <Text style={styles.qrTitle}>Customer Scan</Text>
            <Text style={styles.qrAmount}>${amount} JMD</Text>
            <View style={styles.qrWrapper}>
              <QRCode value={qrValue} size={200} color="#000" backgroundColor="#FFF" />
            </View>
            <TouchableOpacity style={styles.closeQRButton} onPress={() => setShowQR(false)}>
              <Text style={styles.closeQRButtonText}>Close Payment Window</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>

      {/* Order History & Refunds Modal */}
      <Modal visible={showOrderHistoryModal} transparent animationType="slide">
        <View style={styles.modalBgContainer}>
          <View style={styles.inventoryDrawer}>
            <View style={styles.drawerHeader}>
              <Text style={styles.drawerTitle}>Order History & Refunds</Text>
              <TouchableOpacity 
                style={styles.drawerCloseIconButton} 
                onPress={() => setShowOrderHistoryModal(false)}
                activeOpacity={0.7}
              >
                <Ionicons name="close-circle" size={32} color="#FF6B6B" />
              </TouchableOpacity>
            </View>

            {loadingOrders ? (
              <ActivityIndicator size="large" color="#6C63FF" style={{ marginVertical: 20 }} />
            ) : (
              <FlatList
                data={orders}
                keyExtractor={(item) => item.id}
                style={{ maxHeight: height * 0.6 }}
                ListEmptyComponent={<Text style={{ color: '#888', textAlign: 'center', marginTop: 20 }}>No recent orders found.</Text>}
                renderItem={({ item }) => (
                  <View style={{ backgroundColor: 'rgba(255,255,255,0.05)', padding: 15, borderRadius: 12, marginBottom: 10, flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
                    <View>
                      <Text style={{ color: '#FFF', fontWeight: 'bold' }}>${parseFloat(item.amount).toFixed(2)} JMD</Text>
                      <Text style={{ color: '#888', fontSize: 12, marginTop: 4 }}>{new Date(item.created_at).toLocaleString()}</Text>
                      <Text style={{ color: item.status === 'COMPLETED' ? '#00FFCC' : '#FF6B6B', fontSize: 12, marginTop: 4, fontWeight: 'bold' }}>{item.status}</Text>
                    </View>
                    {item.status === 'COMPLETED' && (
                      <TouchableOpacity 
                        style={{ backgroundColor: 'rgba(255, 107, 107, 0.2)', paddingHorizontal: 12, paddingVertical: 8, borderRadius: 8 }}
                        onPress={() => handleRefund(item.id)}
                        disabled={refundingTx === item.id}
                      >
                        {refundingTx === item.id ? (
                          <ActivityIndicator size="small" color="#FF6B6B" />
                        ) : (
                          <Text style={{ color: '#FF6B6B', fontWeight: 'bold', fontSize: 12 }}>REFUND</Text>
                        )}
                      </TouchableOpacity>
                    )}
                  </View>
                )}
              />
            )}
          </View>
        </View>
      </Modal>

      {/* Loyalty Settings Modal */}
      <Modal visible={showLoyaltyModal} transparent animationType="slide">
        <View style={styles.modalBgContainer}>
          <View style={styles.inventoryDrawer}>
            <View style={styles.drawerHeader}>
              <Text style={styles.drawerTitle}>Loyalty Settings</Text>
              <TouchableOpacity 
                style={styles.drawerCloseIconButton} 
                onPress={() => setShowLoyaltyModal(false)}
                activeOpacity={0.7}
              >
                <Ionicons name="close-circle" size={32} color="#FF6B6B" />
              </TouchableOpacity>
            </View>
            <Text style={{ color: '#888', marginBottom: 15 }}>
              Set how many Unity Points customers earn per $100 spent. Remember, you will be debited $1 JMD for each point awarded to fund the program.
            </Text>

            <Text style={styles.label}>Points per $100 Spent</Text>
            <TextInput
              style={styles.drawerInput}
              value={loyaltyRate}
              onChangeText={setLoyaltyRate}
              keyboardType="number-pad"
              placeholder="1"
              placeholderTextColor="#555"
            />
            
            <TouchableOpacity 
              style={[styles.createBtn, updatingLoyalty && styles.disabled]}
              onPress={handleUpdateLoyalty}
              disabled={updatingLoyalty}
            >
              {updatingLoyalty ? (
                <ActivityIndicator size="small" color="#000" />
              ) : (
                <Text style={styles.createBtnText}>Save Settings</Text>
              )}
            </TouchableOpacity>
          </View>
        </View>
      </Modal>

      {/* Inventory Input Drawer / Modal */}
      <Modal visible={showInventoryModal} transparent animationType="slide">
        <View style={styles.modalBgContainer}>
          <View style={styles.inventoryDrawer}>
            {/* Modal Header equipped with VERY visible Close Circle Icon Button */}
            <View style={styles.drawerHeader}>
              <Text style={styles.drawerTitle}>Create Inventory Item</Text>
              <TouchableOpacity 
                style={styles.drawerCloseIconButton} 
                onPress={() => setShowInventoryModal(false)}
                activeOpacity={0.7}
              >
                <Ionicons name="close-circle" size={32} color="#FF6B6B" />
              </TouchableOpacity>
            </View>

            {/* Picture Pick/Upload Flow */}
            <Text style={styles.label}>Product Image</Text>
            <View style={styles.imageUploadRow}>
              {newItemImage ? (
                <View style={styles.thumbnailContainer}>
                  <Image source={{ uri: newItemImage }} style={styles.thumbnail} />
                  <TouchableOpacity style={styles.removeImageBtn} onPress={() => setNewItemImage(null)}>
                    <Ionicons name="close" size={14} color="#FFF" />
                  </TouchableOpacity>
                </View>
              ) : (
                <View style={styles.placeholderThumbnail}>
                  <Ionicons name="image-outline" size={28} color="#666" />
                </View>
              )}
              <TouchableOpacity style={styles.pickImageBtn} onPress={pickImage}>
                <Ionicons name="camera-outline" size={18} color="#00FFCC" />
                <Text style={styles.pickImageBtnText}>Select Product Photo</Text>
              </TouchableOpacity>
            </View>

            {/* Inputs */}
            <Text style={styles.label}>Barcode (Optional)</Text>
            <View style={styles.barcodeInputRow}>
              <TextInput
                style={[styles.drawerInput, { flex: 1, marginBottom: 0 }]}
                value={newItemBarcode}
                onChangeText={setNewItemBarcode}
                placeholder="Scan or type..."
                placeholderTextColor="#555"
              />
              <TouchableOpacity style={styles.scanIconBtn} onPress={() => {
                if (!permission?.granted) requestPermission();
                else setScanningMode('INVENTORY');
              }}>
                <Ionicons name="barcode" size={22} color="#00FFCC" />
              </TouchableOpacity>
            </View>

            <Text style={styles.label}>Item Name</Text>
            <TextInput
              style={styles.drawerInput}
              value={newItemName}
              onChangeText={setNewItemName}
              placeholder="e.g. Energy Drink"
              placeholderTextColor="#555"
            />

            <Text style={styles.label}>Item Price (JMD)</Text>
            <TextInput
              style={styles.drawerInput}
              value={newItemPrice}
              onChangeText={setNewItemPrice}
              keyboardType="decimal-pad"
              placeholder="0.00"
              placeholderTextColor="#555"
            />

            <Text style={styles.label}>Initial Stock Quantity</Text>
            <TextInput
              style={styles.drawerInput}
              value={newItemStock}
              onChangeText={setNewItemStock}
              keyboardType="number-pad"
              placeholder="0"
              placeholderTextColor="#555"
            />

            {/* Double Action Button: Create and highly visible Cancel/Close footer button */}
            <TouchableOpacity 
              style={[styles.createBtn, creatingItem && styles.disabled]}
              onPress={handleCreateProduct}
              disabled={creatingItem}
            >
              {creatingItem ? (
                <ActivityIndicator size="small" color="#000" />
              ) : (
                <Text style={styles.createBtnText}>Add Item to Catalog</Text>
              )}
            </TouchableOpacity>

            <TouchableOpacity 
              style={styles.drawerCloseFooterBtn}
              onPress={() => setShowInventoryModal(false)}
            >
              <Text style={styles.drawerCloseFooterText}>Close Drawer</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>

      {/* Full Screen Scanner */}
      {scanningMode !== 'NONE' && permission?.granted && (
        <Modal visible transparent animationType="slide">
          <View style={styles.scannerOverlay}>
            <CameraView 
              style={StyleSheet.absoluteFillObject} 
              facing="back"
              onBarcodeScanned={handleBarcodeScanned}
              barcodeScannerSettings={{
                barcodeTypes: ["qr", "ean13", "ean8", "upc_a", "upc_e", "code39", "code128"],
              }}
            />
            <SafeAreaView style={styles.scannerHeader}>
              <TouchableOpacity onPress={() => setScanningMode('NONE')} style={styles.closeScannerBtn}>
                <Ionicons name="close" size={28} color="#FFF" />
              </TouchableOpacity>
              <Text style={styles.scannerTitle}>Scan Barcode</Text>
            </SafeAreaView>
          </View>
        </Modal>
      )}
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0A0A15' },
  header: { 
    flexDirection: 'row', 
    justifyContent: 'space-between', 
    alignItems: 'center', 
    paddingHorizontal: 15, 
    paddingTop: 15,
    paddingBottom: 15,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255,255,255,0.05)'
  },
  backButton: { flexDirection: 'row', alignItems: 'center' },
  backButtonText: { color: '#FFF', fontSize: 16, marginLeft: 4, fontWeight: 'bold' },
  headerTitle: { color: '#FFF', fontSize: 18, fontWeight: 'bold' },
  addInventoryBtn: { 
    flexDirection: 'row', 
    alignItems: 'center', 
    backgroundColor: 'rgba(0,255,204,0.1)', 
    paddingHorizontal: 10, 
    paddingVertical: 5, 
    borderRadius: 8 
  },
  addInventoryBtnText: { color: '#00FFCC', fontSize: 12, fontWeight: 'bold', marginLeft: 2 },
  
  displayArea: { 
    backgroundColor: 'rgba(255,255,255,0.03)', 
    borderRadius: 18, 
    margin: 15, 
    padding: 20, 
    alignItems: 'center',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.05)'
  },
  displayRow: { 
    flexDirection: 'row', 
    justifyContent: 'space-between', 
    width: '100%', 
    alignItems: 'center',
    marginBottom: 5
  },
  currencyLabel: { color: '#6C63FF', fontSize: 15, fontWeight: 'bold' },
  clearBtn: { backgroundColor: 'rgba(255, 107, 107, 0.15)', paddingHorizontal: 10, paddingVertical: 4, borderRadius: 6 },
  clearBtnText: { color: '#FF6B6B', fontSize: 11, fontWeight: 'bold' },
  amountInput: { color: '#FFF', fontSize: 44, fontWeight: 'bold', textAlign: 'center', width: '100%' },

  catalogSection: { flex: 1, paddingHorizontal: 15 },
  sectionHeading: { color: '#888', fontSize: 13, fontWeight: 'bold', marginBottom: 10, textTransform: 'uppercase', letterSpacing: 1 },
  loadingContainer: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  loadingText: { color: '#666', marginTop: 8 },
  
  gridContainer: { paddingBottom: 20 },
  gridCard: { 
    flex: 1/3, 
    backgroundColor: 'rgba(255,255,255,0.02)', 
    borderRadius: 12, 
    margin: 4, 
    borderWidth: 1, 
    borderColor: 'rgba(255,255,255,0.04)',
    overflow: 'hidden',
    alignItems: 'center'
  },
  gridImage: { width: '100%', height: 60, backgroundColor: '#111' },
  gridCardDetails: { padding: 6, alignItems: 'center', width: '100%' },
  gridCardName: { color: '#FFF', fontSize: 11, fontWeight: 'bold' },
  gridCardPrice: { color: '#00FFCC', fontSize: 11, fontWeight: 'bold', marginTop: 2 },
  
  emptyCatalogContainer: { flex: 1, alignItems: 'center', justifyContent: 'center', paddingVertical: 40 },
  emptyCatalogText: { color: '#555', fontSize: 11, textAlign: 'center', marginTop: 6, paddingHorizontal: 20 },

  actionSection: { padding: 15, borderTopWidth: 1, borderTopColor: 'rgba(255,255,255,0.05)', flexDirection: 'row', justifyContent: 'space-between' },
  scanButton: { backgroundColor: 'rgba(255,255,255,0.1)', flexDirection: 'row', padding: 16, borderRadius: 12, alignItems: 'center', justifyContent: 'center', flex: 0.45 },
  scanButtonText: { color: '#FFF', fontSize: 14, fontWeight: 'bold', marginLeft: 8 },
  payButton: { backgroundColor: '#00FFCC', flexDirection: 'row', padding: 16, borderRadius: 12, alignItems: 'center', justifyContent: 'center', flex: 0.5 },
  payButtonText: { color: '#000', fontSize: 14, fontWeight: 'bold', marginLeft: 8 },

  modalBgContainer: { flex: 1, backgroundColor: 'rgba(0,0,0,0.85)', justifyContent: 'center', alignItems: 'center', padding: 20 },
  
  // QR Card Styling
  qrCard: { backgroundColor: '#FFF', padding: 25, borderRadius: 25, alignItems: 'center', width: '85%' },
  qrTitle: { fontSize: 16, fontWeight: 'bold', color: '#777', marginBottom: 5 },
  qrAmount: { fontSize: 32, fontWeight: 'bold', color: '#6C63FF', marginBottom: 15 },
  qrWrapper: { padding: 10, backgroundColor: '#FFF', borderRadius: 10, borderWidth: 1, borderColor: '#EEE' },
  closeQRButton: { marginTop: 25, padding: 14, backgroundColor: '#0F0F1E', borderRadius: 10, width: '100%', alignItems: 'center' },
  closeQRButtonText: { color: '#FFF', fontWeight: 'bold' },

  // Inventory Drawer Modal Styling
  inventoryDrawer: { 
    backgroundColor: '#131326', 
    width: '100%', 
    borderRadius: 25, 
    padding: 24, 
    borderWidth: 1, 
    borderColor: 'rgba(255,255,255,0.08)' 
  },
  drawerHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 },
  drawerTitle: { color: '#FFF', fontSize: 20, fontWeight: 'bold' },
  drawerCloseIconButton: { padding: 4 },
  
  label: { color: '#888', fontSize: 12, fontWeight: 'bold', marginBottom: 6, marginTop: 12 },
  imageUploadRow: { flexDirection: 'row', alignItems: 'center', marginBottom: 10 },
  thumbnailContainer: { width: 60, height: 60, borderRadius: 10, overflow: 'hidden', marginRight: 15, position: 'relative' },
  thumbnail: { width: '100%', height: '100%' },
  removeImageBtn: { 
    position: 'absolute', 
    top: 2, 
    right: 2, 
    backgroundColor: 'rgba(255,107,107,0.8)', 
    borderRadius: 8, 
    width: 16, 
    height: 16, 
    alignItems: 'center', 
    justifyContent: 'center' 
  },
  placeholderThumbnail: { 
    width: 60, 
    height: 60, 
    borderRadius: 10, 
    backgroundColor: 'rgba(255,255,255,0.05)', 
    borderWidth: 1, 
    borderColor: 'rgba(255,255,255,0.1)', 
    justifyContent: 'center', 
    alignItems: 'center', 
    marginRight: 15 
  },
  pickImageBtn: { 
    flexDirection: 'row', 
    alignItems: 'center', 
    backgroundColor: 'rgba(255,255,255,0.05)', 
    paddingVertical: 10, 
    paddingHorizontal: 15, 
    borderRadius: 10,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.08)'
  },
  pickImageBtnText: { color: '#FFF', fontSize: 13, fontWeight: 'bold', marginLeft: 6 },

  drawerInput: { 
    backgroundColor: 'rgba(255,255,255,0.05)', 
    borderRadius: 12, 
    color: '#FFF', 
    fontSize: 14, 
    padding: 12, 
    borderWidth: 1, 
    borderColor: 'rgba(255,255,255,0.05)',
    marginBottom: 8
  },
  barcodeInputRow: { flexDirection: 'row', alignItems: 'center', marginBottom: 8 },
  scanIconBtn: { backgroundColor: 'rgba(0,255,204,0.1)', padding: 12, borderRadius: 12, marginLeft: 10, borderWidth: 1, borderColor: 'rgba(0,255,204,0.2)' },
  createBtn: { 
    backgroundColor: '#00FFCC', 
    borderRadius: 12, 
    paddingVertical: 14, 
    alignItems: 'center', 
    justifyContent: 'center', 
    marginTop: 20 
  },
  createBtnText: { color: '#000', fontSize: 15, fontWeight: 'bold' },
  drawerCloseFooterBtn: { 
    backgroundColor: 'rgba(255,255,255,0.05)', 
    borderRadius: 12, 
    paddingVertical: 14, 
    alignItems: 'center', 
    justifyContent: 'center', 
    marginTop: 10,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.05)'
  },
  drawerCloseFooterText: { color: '#888', fontSize: 15, fontWeight: 'bold' },
  disabled: { backgroundColor: '#444' },

  // Cashier PIN Lock Styles
  pinContainer: { flex: 1, backgroundColor: '#090915', paddingHorizontal: 25 },
  pinHeader: { paddingTop: 20, flexDirection: 'row' },
  pinContent: { flex: 1, justifyContent: 'center', alignItems: 'center', paddingBottom: 50 },
  pinTitle: { color: '#FFF', fontSize: 22, fontWeight: 'bold', marginBottom: 6 },
  pinSubtitle: { color: '#888', fontSize: 13, textAlign: 'center', marginBottom: 30 },
  dotsContainer: { flexDirection: 'row', justifyContent: 'center', alignItems: 'center', marginBottom: 20 },
  dot: { width: 14, height: 14, borderRadius: 7, backgroundColor: 'rgba(255,255,255,0.1)', marginHorizontal: 12, borderWidth: 1, borderColor: 'rgba(255,255,255,0.05)' },
  activeDot: { backgroundColor: '#00FFCC', transform: [{ scale: 1.2 }] },
  errorDot: { backgroundColor: '#FF6B6B' },
  pinErrorText: { color: '#FF6B6B', fontSize: 13, fontWeight: 'bold', marginVertical: 10 },
  pinHelpText: { color: '#555', fontSize: 12, marginVertical: 10 },
  keypadGrid: { width: 280, flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'center', marginTop: 20 },
  keypadButton: { width: 80, height: 80, borderRadius: 40, backgroundColor: 'rgba(255,255,255,0.03)', justifyContent: 'center', alignItems: 'center', margin: 6, borderWidth: 1, borderColor: 'rgba(255,255,255,0.04)' },
  keypadButtonText: { color: '#FFF', fontSize: 26, fontWeight: 'bold' },
  keypadActionText: { color: '#FF6B6B', fontSize: 20, fontWeight: 'bold' },

  scannerOverlay: { flex: 1, backgroundColor: '#000' },
  scannerHeader: { position: 'absolute', top: 0, left: 0, right: 0, flexDirection: 'row', alignItems: 'center', padding: 20, backgroundColor: 'rgba(0,0,0,0.5)' },
  closeScannerBtn: { marginRight: 20 },
  scannerTitle: { color: '#FFF', fontSize: 18, fontWeight: 'bold' }
});

export default MerchantPOSScreen;
