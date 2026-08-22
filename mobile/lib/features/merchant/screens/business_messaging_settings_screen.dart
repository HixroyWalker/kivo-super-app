import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/vendor_provider.dart';

class BusinessMessagingSettingsScreen extends StatefulWidget {
  const BusinessMessagingSettingsScreen({super.key});

  @override
  State<BusinessMessagingSettingsScreen> createState() => _BusinessMessagingSettingsScreenState();
}

class _BusinessMessagingSettingsScreenState extends State<BusinessMessagingSettingsScreen> {
  final _greetingController = TextEditingController();
  final _awayController = TextEditingController();
  bool _isAway = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final vendor = context.read<VendorProvider>();
    _greetingController.text = vendor.greetingMessage ?? '';
    _awayController.text = vendor.awayMessage ?? '';
    _isAway = vendor.isAway;
  }

  @override
  void dispose() {
    _greetingController.dispose();
    _awayController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final vendor = context.read<VendorProvider>();
      final messagingConfig = {
        'messaging': {
          'greetingMessage': _greetingController.text.trim(),
          'awayMessage': _awayController.text.trim(),
          'isAway': _isAway,
          'quickReplies': vendor.quickReplies,
        }
      };
      
      await vendor.updateStorefront(messagingConfig);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF00C853),
          content: Text('Messaging settings saved!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save settings: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Automated Messaging'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Away Mode'),
            subtitle: const Text('Automatically reply with your Away Message'),
            value: _isAway,
            activeColor: const Color(0xFFFFD700),
            onChanged: (val) => setState(() => _isAway = val),
          ),
          const SizedBox(height: 16),
          const Text('Greeting Message', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _greetingController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Welcome to our store! How can we help you?',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Away Message', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _awayController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'We are currently closed. We will reply as soon as we open.',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}
