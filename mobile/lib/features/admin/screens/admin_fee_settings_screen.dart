import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/dark_theme.dart';
import '../../../core/services/admin_provider.dart';

class AdminFeeSettingsScreen extends StatefulWidget {
  const AdminFeeSettingsScreen({super.key});

  @override
  State<AdminFeeSettingsScreen> createState() => _AdminFeeSettingsScreenState();
}

class _AdminFeeSettingsScreenState extends State<AdminFeeSettingsScreen> {
  late TextEditingController _p2pController;
  late TextEditingController _merchantController;
  late TextEditingController _cashoutController;
  late TextEditingController _marketplaceController;
  late TextEditingController _gctController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final cfg = context.read<AdminProvider>().feeConfig;
    _p2pController = TextEditingController(text: cfg.p2pTransferFeePercent.toString());
    _merchantController = TextEditingController(text: cfg.merchantProcessingFeePercent.toString());
    _cashoutController = TextEditingController(text: cfg.cashoutFeePercent.toString());
    _marketplaceController = TextEditingController(text: cfg.marketplaceCommissionPercent.toString());
    _gctController = TextEditingController(text: cfg.gctTaxRatePercent.toString());
  }

  @override
  void dispose() {
    _p2pController.dispose();
    _merchantController.dispose();
    _cashoutController.dispose();
    _marketplaceController.dispose();
    _gctController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final p2p = double.tryParse(_p2pController.text) ?? 0.5;
    final merch = double.tryParse(_merchantController.text) ?? 1.5;
    final cashout = double.tryParse(_cashoutController.text) ?? 1.0;
    final market = double.tryParse(_marketplaceController.text) ?? 5.0;
    final gct = double.tryParse(_gctController.text) ?? 15.0;

    await context.read<AdminProvider>().updateFeeConfig(
      p2pPercent: p2p,
      merchantPercent: merch,
      cashoutPercent: cashout,
      marketplacePercent: market,
      gctPercent: gct,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: KivoDarkTheme.surfaceElevated,
          content: Text(
            '✅ Platform fee rates & charges updated successfully!',
            style: TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KivoDarkTheme.background,
      appBar: AppBar(
        title: const Text('Set Platform Charges', style: TextStyle(fontWeight: FontWeight.bold, color: KivoDarkTheme.textPrimary)),
        backgroundColor: KivoDarkTheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KivoDarkTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KivoDarkTheme.surfaceBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.tune, color: KivoDarkTheme.accentAmber, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dynamic Pricing & Tax Engine', style: TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('Adjust charges across transfers, marketplace sales, and statutory Jamaican GCT taxes.', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildFeeField(
              title: 'P2P Transfer Fee (%)',
              subtitle: 'Applies to peer-to-peer social wallet transfers',
              controller: _p2pController,
              icon: Icons.swap_horiz,
            ),
            _buildFeeField(
              title: 'Merchant QR / POS Processing Fee (%)',
              subtitle: 'Deducted from merchant QR cashier checkouts',
              controller: _merchantController,
              icon: Icons.point_of_sale,
            ),
            _buildFeeField(
              title: 'Lynk BOJ Instant Cashout Fee (%)',
              subtitle: 'Applies to withdrawals from Kivo to Lynk / NCB account',
              controller: _cashoutController,
              icon: Icons.account_balance,
            ),
            _buildFeeField(
              title: 'Marketplace Vendor Commission (%)',
              subtitle: 'Platform fee for sales through Kivo Jamaican marketplace',
              controller: _marketplaceController,
              icon: Icons.storefront,
            ),
            _buildFeeField(
              title: 'Tax Administration Jamaica (TAJ) GCT Rate (%)',
              subtitle: 'Statutory 15% General Consumption Tax rate applied on merchant sales',
              controller: _gctController,
              icon: Icons.receipt_long,
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveSettings,
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.check, color: Colors.black),
                label: Text(
                  _isSaving ? 'Saving Changes...' : 'Save & Enforce Charges',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KivoDarkTheme.primaryEmerald,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeField({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KivoDarkTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KivoDarkTheme.surfaceBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: KivoDarkTheme.accentCyan, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold, fontSize: 16),
              decoration: InputDecoration(
                suffixText: '%',
                suffixStyle: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                filled: true,
                fillColor: KivoDarkTheme.surfaceElevated,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
