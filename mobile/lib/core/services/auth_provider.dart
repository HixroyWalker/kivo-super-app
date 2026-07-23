import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String? _sessionToken;
  String? _userId;

  bool get isAuthenticated => _sessionToken != null;
  String? get sessionToken => _sessionToken;
  String? get userId => _userId;

  void setSession(String token, String uid) {
    _sessionToken = token;
    _userId = uid;
    notifyListeners();
  }

  void logout() {
    _sessionToken = null;
    _userId = null;
    notifyListeners();
  }
}
