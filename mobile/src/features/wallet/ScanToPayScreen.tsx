import React, { useState } from 'react';
import { Text, View, StyleSheet, TouchableOpacity, Alert } from 'react-native';
import { CameraView, useCameraPermissions } from 'expo-camera';
import { Ionicons } from '@expo/vector-icons';

const ScanToPayScreen = ({ navigation }: any) => {
  const [permission, requestPermission] = useCameraPermissions();
  const [scanned, setScanned] = useState(false);

  // If permission has not loaded yet
  if (!permission) {
    return (
      <View style={styles.container}>
        <Text style={styles.text}>Requesting camera permission...</Text>
      </View>
    );
  }

  // If permission is not granted
  if (!permission.granted) {
    return (
      <View style={styles.container}>
        <Text style={styles.text}>KIVO needs camera access to scan QR codes.</Text>
        <TouchableOpacity style={styles.permissionBtn} onPress={requestPermission}>
          <Text style={styles.permissionBtnText}>Grant Camera Access</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const handleBarCodeScanned = ({ data }: { data: string }) => {
    setScanned(true);
    try {
      const qrData = JSON.parse(data);
      if (qrData.type === 'P2P_RECEIVE' || qrData.type === 'MERCHANT_PAY') {
        navigation.navigate('SendMoney', { recipient_id: qrData.id, amount: qrData.amount });
      } else {
        Alert.alert('Invalid QR', 'This QR code is not recognized by KIVO.', [
          { text: 'OK', onPress: () => setScanned(false) }
        ]);
      }
    } catch (e) {
      Alert.alert('Scan Error', 'Could not parse QR data.', [
        { text: 'OK', onPress: () => setScanned(false) }
      ]);
    }
  };

  return (
    <View style={styles.container}>
      <CameraView
        style={StyleSheet.absoluteFillObject}
        onBarcodeScanned={scanned ? undefined : handleBarCodeScanned}
        barcodeScannerSettings={{
          barcodeTypes: ['qr'],
        }}
      />
      <View style={styles.overlay}>
        <View style={styles.scanFrame} />
        <Text style={styles.instruction}>Align QR code within the frame</Text>
      </View>
      
      <TouchableOpacity style={styles.closeButton} onPress={() => navigation.goBack()}>
        <Ionicons name="close-circle" size={50} color="#FFF" />
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#000', justifyContent: 'center', alignItems: 'center' },
  text: { color: '#FFF', fontSize: 16, textAlign: 'center', marginHorizontal: 20 },
  overlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', width: '100%', justifyContent: 'center', alignItems: 'center' },
  scanFrame: { width: 250, height: 250, borderWidth: 2, borderColor: '#6C63FF', borderRadius: 20 },
  instruction: { color: '#FFF', marginTop: 20, fontSize: 16, fontWeight: 'bold' },
  closeButton: { position: 'absolute', bottom: 50 },
  permissionBtn: {
    marginTop: 20,
    backgroundColor: '#6C63FF',
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 25,
  },
  permissionBtnText: {
    color: '#FFF',
    fontWeight: 'bold',
    fontSize: 16,
  },
});

export default ScanToPayScreen;
