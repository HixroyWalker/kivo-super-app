import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/theme/dark_theme.dart';
import '../../../core/services/admob_service.dart';
import '../../../core/services/wallet_provider.dart';

class AdsScreen extends StatefulWidget {
  const AdsScreen({super.key});

  @override
  State<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends State<AdsScreen> {
  RewardedAd? _rewardedAd;
  bool _isLoadingAd = false;
  bool _isClaimingReward = false;
  String? _statusMessage;
  double _todayEarned = 15.0;

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
  }

  void _loadRewardedAd() {
    setState(() => _isLoadingAd = true);
    AdMobService.loadRewardedAd(
      onAdLoaded: (ad) {
        setState(() {
          _rewardedAd = ad;
          _isLoadingAd = false;
        });
      },
      onAdFailedToLoad: (error) {
        setState(() {
          _rewardedAd = null;
          _isLoadingAd = false;
        });
        debugPrint('Rewarded ad failed to load: $error');
      },
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd == null) {
      _loadRewardedAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewardedAd();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        _handleRewardClaim();
      },
    );
  }

  void _handleRewardClaim() {
    setState(() {
      _isClaimingReward = true;
      _todayEarned += 5.0;
    });

    // Credit 5.00 JMD to WalletProvider
    final wallet = context.read<WalletProvider>();
    wallet.topUpLynk(5.0);

    setState(() {
      _isClaimingReward = false;
      _statusMessage = '🎉 +JMD \$5.00 successfully added to your Kivo Wallet!';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 +JMD \$5.00 credited to your Kivo Wallet!'),
        backgroundColor: KivoDarkTheme.primaryEmerald,
      ),
    );
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch & Earn'),
        backgroundColor: KivoDarkTheme.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Hero Earnings Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: KivoDarkTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: KivoDarkTheme.primaryEmerald.withOpacity(0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Ad Earnings Today',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'JMD \$${_todayEarned.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, color: Colors.black, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'JMD \$5.00 per video ad completed',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Partner Network Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: KivoDarkTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: KivoDarkTheme.accentCyan.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.ads_click, color: KivoDarkTheme.accentCyan, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Google AdMob Partner Network',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Watch 15-30 second sponsor videos to earn instant JMD cash back directly into your closed-loop balance.',
                    style: TextStyle(fontSize: 13, color: KivoDarkTheme.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 20),

                  if (_statusMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: KivoDarkTheme.primaryEmerald.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: KivoDarkTheme.primaryEmerald.withOpacity(0.3)),
                      ),
                      child: Text(
                        _statusMessage!,
                        style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),

                  ElevatedButton.icon(
                    onPressed: (_isLoadingAd || _isClaimingReward) ? null : _showRewardedAd,
                    icon: _isLoadingAd
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const Icon(Icons.play_circle_fill, size: 24),
                    label: Text(_isLoadingAd ? 'Loading Google Ad...' : 'Watch Sponsor Video (+JMD \$5.00)'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
