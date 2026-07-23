import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/auth_provider.dart';

class AdsScreen extends StatefulWidget {
  const AdsScreen({super.key});

  @override
  State<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends State<AdsScreen> {
  bool _isWatching = false;
  String? _message;

  Future<void> _watchAdAndEarn() async {
    setState(() {
      _isWatching = true;
      _message = 'Simulating 5-second video ad...';
    });

    // Mock waiting for a video ad to finish playing
    await Future.delayed(const Duration(seconds: 5));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final apiClient = ApiClient(baseUrl: 'https://your-kivo-backend.com/api', authProvider: authProvider);

    try {
      final response = await apiClient.post('/ads/reward', {'adId': 'ad_campaign_123'});
      
      if (response.statusCode == 200) {
        setState(() {
          _message = 'Success! 5 JMD has been credited to your wallet.';
        });
      } else {
        setState(() {
          _message = 'Failed to claim reward.';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isWatching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Watch & Earn')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on, size: 100, color: Colors.amber),
              const SizedBox(height: 24),
              const Text(
                'Earn JMD by watching short ads from our partners!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: _message!.contains('Success') ? Colors.green : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ElevatedButton.icon(
                onPressed: _isWatching ? null : _watchAdAndEarn,
                icon: _isWatching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.play_arrow),
                label: Text(_isWatching ? 'Watching Ad...' : 'Watch Ad & Earn 5 JMD'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
