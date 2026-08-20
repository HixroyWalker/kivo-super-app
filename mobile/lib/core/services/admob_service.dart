import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static bool _isInitialized = false;

  // Google AdMob Test App IDs
  static String get appId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544~3347511713';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544~1458002511';
    }
    throw UnsupportedError('Unsupported platform');
  }

  // Rewarded Video Ad Unit IDs
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    throw UnsupportedError('Unsupported platform');
  }

  // Banner Ad Unit IDs
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    throw UnsupportedError('Unsupported platform');
  }

  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('Google AdMob initialized successfully');
    } catch (e) {
      debugPrint('AdMob initialization fallback: $e');
    }
  }

  static void loadRewardedAd({
    required Function(RewardedAd ad) onAdLoaded,
    required Function(LoadAdError error) onAdFailedToLoad,
  }) {
    try {
      RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: onAdLoaded,
          onAdFailedToLoad: onAdFailedToLoad,
        ),
      );
    } catch (e) {
      debugPrint('AdMob load error: $e');
    }
  }
}
