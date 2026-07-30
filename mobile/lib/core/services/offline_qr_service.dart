import 'dart:convert';
import 'package:crypto/crypto.dart';

class OfflineQrService {
  static const String _secretSalt = 'Kivo_Offline_Mesh_Secret_2026_Secure_Key';

  /// Generate a cryptographically signed offline QR payload
  static String createSignedOfflinePayload({
    required String merchantId,
    required double amount,
    required String currency,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nonce = (timestamp % 10000).toString();
    final rawData = '$merchantId:$amount:$currency:$timestamp:$nonce';
    
    final hmac = Hmac(sha256, utf8.encode(_secretSalt));
    final digest = hmac.convert(utf8.encode(rawData));

    final payload = {
      'mId': merchantId,
      'amt': amount,
      'cur': currency,
      'ts': timestamp,
      'sig': digest.toString().substring(0, 16),
      'off': true
    };

    return jsonEncode(payload);
  }

  /// Verify and decode signed offline QR payload
  static Map<String, dynamic>? verifyAndDecodeOfflinePayload(String payloadString) {
    try {
      final Map<String, dynamic> data = jsonDecode(payloadString);
      if (data['off'] != true) return null;

      final merchantId = data['mId'];
      final amount = data['amt'];
      final currency = data['cur'];
      final timestamp = data['ts'];
      final signature = data['sig'];

      final nonce = (timestamp % 10000).toString();
      final rawData = '$merchantId:$amount:$currency:$timestamp:$nonce';
      
      final hmac = Hmac(sha256, utf8.encode(_secretSalt));
      final digest = hmac.convert(utf8.encode(rawData));
      final expectedSig = digest.toString().substring(0, 16);

      if (signature == expectedSig) {
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
