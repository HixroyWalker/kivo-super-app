import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/dark_theme.dart';
import '../../../core/services/admin_provider.dart';
import '../../../core/services/wallet_provider.dart';
import '../../../core/services/auth_provider.dart';
import 'admin_fee_settings_screen.dart';
import 'admin_balance_adjustment_screen.dart';
import 'admin_kyc_verification_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final admin = context.watch<AdminProvider>();
    final wallet = context.watch<WalletProvider>();

    if (!auth.isAdmin) {
      return Scaffold(
        backgroundColor: KivoDarkTheme.background,
        appBar: AppBar(title: const Text('Access Restricted')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: KivoDarkTheme.accentRose),
                const SizedBox(height: 16),
                const Text('Master Admin Privileges Required', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Your current account is not registered with system administrator permissions.', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: KivoDarkTheme.primaryEmerald, foregroundColor: Colors.black),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Return to Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: KivoDarkTheme.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: KivoDarkTheme.primaryEmerald),
            SizedBox(width: 10),
            Text('Master Admin Console', style: TextStyle(fontWeight: FontWeight.bold, color: KivoDarkTheme.textPrimary)),
          ],
        ),
        backgroundColor: KivoDarkTheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Treasury & Platform Stats
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: KivoDarkTheme.cardGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: KivoDarkTheme.primaryEmerald.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('PLATFORM TREASURY & LIQUIDITY', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      Icon(Icons.account_balance, color: KivoDarkTheme.primaryEmerald, size: 20),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'JMD \$${wallet.jmdBalance.toStringAsFixed(2)}',
                    style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: KivoDarkTheme.surfaceBorder),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricItem('Active Rates', '${admin.feeConfig.p2pTransferFeePercent}% P2P', Icons.percent),
                      _buildMetricItem('Pending KYCs', '${admin.pendingKYCs.length} Pending', Icons.pending_actions),
                      _buildMetricItem('TAJ GCT Rate', '${admin.feeConfig.gctTaxRatePercent}% GCT', Icons.receipt_long),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            const Text(
              'Administrative Management Tools',
              style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Tool 1: Set Platform Charges
            _buildAdminActionCard(
              context: context,
              icon: Icons.tune,
              iconColor: KivoDarkTheme.accentAmber,
              title: 'Set Platform Charges & Fee Rates',
              subtitle: 'Configure P2P fees (${admin.feeConfig.p2pTransferFeePercent}%), Merchant POS rate (${admin.feeConfig.merchantProcessingFeePercent}%), Lynk cashouts, and TAJ GCT (15%).',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminFeeSettingsScreen()),
              ),
            ),

            // Tool 2: Credit / Debit User Balances
            _buildAdminActionCard(
              context: context,
              icon: Icons.account_balance_wallet,
              iconColor: KivoDarkTheme.primaryEmerald,
              title: 'Credit / Debit User Balances',
              subtitle: 'Manually credit or debit individual / merchant balances with mandatory audit memo logs.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminBalanceAdjustmentScreen()),
              ),
            ),

            // Tool 3: Verify Business & Individual KYC
            _buildAdminActionCard(
              context: context,
              icon: Icons.verified_user,
              iconColor: KivoDarkTheme.accentCyan,
              title: 'Verify Business & Individual KYC',
              subtitle: 'Review government IDs, TRN tax certificates, Companies Office of Jamaica records, and approve verified status.',
              badgeText: admin.pendingKYCs.isNotEmpty ? '${admin.pendingKYCs.length} Pending' : null,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminKYCVerificationScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: KivoDarkTheme.primaryEmerald, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 10)),
            Text(value, style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminActionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: KivoDarkTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KivoDarkTheme.surfaceBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                      if (badgeText != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: KivoDarkTheme.accentAmber,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(badgeText, style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}
