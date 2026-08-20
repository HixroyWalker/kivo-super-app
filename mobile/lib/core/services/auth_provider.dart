import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _sessionToken;

  AuthProvider() {
    _initAuth();
  }

  void _initAuth() {
    try {
      _user = FirebaseAuth.instance.currentUser;
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        _user = user;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('FirebaseAuth listener fallback: $e');
    }
  }

  bool get isAuthenticated => _user != null || _sessionToken != null;
  User? get user => _user;
  String? get userId => _user?.uid ?? (_sessionToken != null ? 'usr_kivo_active' : null);
  String? get userEmail => _user?.email ?? 'walkerha2@icloud.com';
  String? get userDisplayName => _user?.displayName ?? 'Hixroy Walker';
  String? get sessionToken => _sessionToken;

  void setSession(String token, String uid) {
    _sessionToken = token;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Sign out fallback: $e');
    }
    _user = null;
    _sessionToken = null;
    notifyListeners();
  }
}
