import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth_provider.dart';

class VendorProvider extends ChangeNotifier {
  final AuthProvider _authProvider;
  FirebaseFirestore? get _firestore => Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null;

  Map<String, dynamic>? _storefrontConfig;
  bool _isLoading = false;

  VendorProvider(this._authProvider) {
    if (_authProvider.isMerchant) {
      _loadStorefront();
    }
  }

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get storefrontConfig => _storefrontConfig;
  
  // Payout Configuration
  double get totalEarnings => _storefrontConfig?['totalEarnings'] ?? 0.0;
  double get pendingPayout => _storefrontConfig?['pendingPayout'] ?? 0.0;
  List<dynamic> get payoutHistory => _storefrontConfig?['payoutHistory'] ?? [];

  // Automated Messaging & CRM
  String? get greetingMessage => _storefrontConfig?['messaging']?['greetingMessage'];
  String? get awayMessage => _storefrontConfig?['messaging']?['awayMessage'];
  bool get isAway => _storefrontConfig?['messaging']?['isAway'] ?? false;
  Map<String, String> get quickReplies => Map<String, String>.from(_storefrontConfig?['messaging']?['quickReplies'] ?? {});

  Future<void> _loadStorefront() async {
    final uid = _authProvider.userId;
    if (uid == null || _firestore == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore!.collection('merchants').doc(uid).get();
      if (doc.exists) {
        _storefrontConfig = doc.data();
      } else {
        // Init default
        _storefrontConfig = {
          'merchantId': uid,
          'businessName': _authProvider.merchantBusinessName,
          'totalEarnings': 0.0,
          'pendingPayout': 0.0,
          'payoutHistory': [],
          'shippingConfig': {
            'flatRate': 650.0,
            'zones': ['All Island'],
          },
        };
      }
    } catch (e) {
      debugPrint('Error loading storefront: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateStorefront(Map<String, dynamic> data) async {
    final uid = _authProvider.userId;
    if (uid == null || _firestore == null) return;

    try {
      await _firestore!.collection('merchants').doc(uid).set(data, SetOptions(merge: true));
      _storefrontConfig = {...?_storefrontConfig, ...data};
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating storefront: $e');
      throw e;
    }
  }
}
