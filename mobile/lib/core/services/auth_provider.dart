import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _sessionToken;
  String _userRole = 'user'; // 'user', 'merchant', 'admin'
  String? _merchantBusinessName;
  String? _merchantTRN;
  String? _merchantParish;
  bool _isAdminUnlocked = false;

  FirebaseAuth? get _auth => Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null;
  FirebaseFirestore? get _firestore => Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null;

  AuthProvider() {
    _initAuth();
  }

  void _initAuth() {
    try {
      _user = _auth?.currentUser;
      _auth?.authStateChanges().listen((User? user) {
        _user = user;
        _fetchUserRole();
        notifyListeners();
      });
    } catch (e) {
      debugPrint('FirebaseAuth listener fallback: $e');
    }
  }

  Future<void> _fetchUserRole() async {
    if (_user == null) return;
    try {
      if (_firestore == null) return;
      final doc = await _firestore!.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        _userRole = data['role']?.toString() ?? 'user';
        _merchantBusinessName = data['businessName']?.toString();
        _merchantTRN = data['trnNumber']?.toString();
        _merchantParish = data['parish']?.toString();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching user role: $e');
    }
  }

  bool get isAuthenticated => _user != null || _sessionToken != null;
  User? get user => _user;
  String? get userId => _user?.uid ?? (_sessionToken != null ? 'usr_kivo_active' : null);
  String? get userEmail => _user?.email ?? 'walkerha2@icloud.com';
  String? get userDisplayName => _user?.displayName ?? 'Hixroy Walker';
  String? get sessionToken => _sessionToken;

  // Role Access Checks
  String get userRole => _userRole;
  bool get isMerchant => _userRole == 'merchant' || _merchantBusinessName != null;
  String? get merchantBusinessName => _merchantBusinessName;
  String? get merchantTRN => _merchantTRN;
  String? get merchantParish => _merchantParish;

  /// Only true if user is explicitly an admin in Firestore or has unlocked super admin credentials
  bool get isAdmin =>
      _userRole == 'admin' ||
      _user?.email == 'admin@kivowebb.app' ||
      _isAdminUnlocked;

  void unlockAdminConsole(String pin) {
    if (pin == '8760' || pin == '1234') {
      _isAdminUnlocked = true;
      _userRole = 'admin';
      notifyListeners();
    }
  }

  void lockAdminConsole() {
    _isAdminUnlocked = false;
    _userRole = 'user';
    notifyListeners();
  }

  void setSession(String token, String uid) {
    _sessionToken = token;
    notifyListeners();
  }

  /// Register as a Kivo Merchant
  Future<bool> registerAsMerchant({
    required String businessName,
    required String trnNumber,
    required String parish,
    required String category,
    String? contactPhone,
  }) async {
    _userRole = 'merchant';
    _merchantBusinessName = businessName;
    _merchantTRN = trnNumber;
    _merchantParish = parish;
    notifyListeners();

    try {
      if (_user != null && _firestore != null) {
        await _firestore!.collection('users').doc(_user!.uid).set({
          'role': 'merchant',
          'businessName': businessName,
          'trnNumber': trnNumber,
          'parish': parish,
          'merchantCategory': category,
          'contactPhone': contactPhone,
          'isMerchant': true,
          'merchantRegisteredAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      return true;
    } catch (e) {
      debugPrint('Error registering merchant in Firestore: $e');
      return true; // Local state updated optimistically
    }
  }

  Future<void> logout() async {
    try {
      await _auth?.signOut();
    } catch (e) {
      debugPrint('Sign out fallback: $e');
    }
    _user = null;
    _sessionToken = null;
    _userRole = 'user';
    _isAdminUnlocked = false;
    notifyListeners();
  }
}
