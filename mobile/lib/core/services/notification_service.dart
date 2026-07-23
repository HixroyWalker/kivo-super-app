import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ApiClient _apiClient;

  NotificationService(this._apiClient);

  Future<void> initialize() async {
    // 1. Request Permission (Required for iOS)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) print('User granted permission');
      
      // 2. Get the FCM Token
      String? token = await _messaging.getToken();
      if (token != null) {
        await _registerTokenWithBackend(token);
      }

      // 3. Listen for Token refreshes
      _messaging.onTokenRefresh.listen(_registerTokenWithBackend);

      // 4. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Got a message whilst in the foreground!');
          print('Message data: ${message.data}');
        }
        if (message.notification != null) {
          if (kDebugMode) print('Message also contained a notification: ${message.notification}');
          // Note: In a real app, you might show a local SnackBar or Toast here.
        }
      });
    } else {
      if (kDebugMode) print('User declined or has not accepted permission');
    }
  }

  Future<void> _registerTokenWithBackend(String token) async {
    try {
      final deviceType = Platform.isIOS ? 'ios' : Platform.isAndroid ? 'android' : 'web';
      await _apiClient.post('/notifications/register-token', {
        'fcmToken': token,
        'deviceType': deviceType
      });
      if (kDebugMode) print('Successfully registered FCM token with backend');
    } catch (e) {
      if (kDebugMode) print('Failed to register FCM token: $e');
    }
  }
}
