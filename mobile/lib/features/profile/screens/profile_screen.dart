import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/dark_theme.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/services/wallet_provider.dart';
import '../../admin/screens/admin_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _biometricEnabled = true;
  bool _pushNotifications = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wallet = context.watch<WalletProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account & Security'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Avatar Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: KivoDarkTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: KivoDarkTheme.surfaceBorder),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          gradient: KivoDarkTheme.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const CircleAvatar(
                          radius: 44,
                          backgroundColor: KivoDarkTheme.surfaceElevated,
                          child: Icon(Icons.person, size: 50, color: KivoDarkTheme.primaryEmerald),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: KivoDarkTheme.primaryEmerald,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified, size: 16, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Hixroy Walker',
                    style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '@hixroy • Kingston, Jamaica 🇯🇲',
                    style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: KivoDarkTheme.primaryEmerald.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Tier 2 Verified Member • ${wallet.formattedBalance}',
                      style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Settings Group
            Container(
              decoration: BoxDecoration(
                color: KivoDarkTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KivoDarkTheme.surfaceBorder),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('FaceID / Biometric Login', style: TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Require biometric authentication for transfers', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
                    value: _biometricEnabled,
                    activeColor: KivoDarkTheme.primaryEmerald,
                    onChanged: (val) => setState(() => _biometricEnabled = val),
                    secondary: const Icon(Icons.fingerprint, color: KivoDarkTheme.primaryEmerald),
                  ),
                  const Divider(color: KivoDarkTheme.surfaceBorder, height: 1),
                  SwitchListTile(
                    title: const Text('Push Notifications', style: TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Real-time payment and order alerts', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
                    value: _pushNotifications,
                    activeColor: KivoDarkTheme.primaryEmerald,
                    onChanged: (val) => setState(() => _pushNotifications = val),
                    secondary: const Icon(Icons.notifications_active_outlined, color: KivoDarkTheme.accentCyan),
                  ),
                  const Divider(color: KivoDarkTheme.surfaceBorder, height: 1),
                  ListTile(
                    leading: const Icon(Icons.verified_user_outlined, color: Colors.purpleAccent),
                    title: const Text('KYC Verification Tier', style: TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('TRN & National ID Verified', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: KivoDarkTheme.textSecondary),
                    onTap: () => Navigator.pushNamed(context, '/merchant_kyc'),
                  ),
                  const Divider(color: KivoDarkTheme.surfaceBorder, height: 1),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings, color: KivoDarkTheme.accentAmber),
                    title: const Text('Master Admin Console', style: TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Set fee charges, credit/debit balances, verify KYCs', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: KivoDarkTheme.textSecondary),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logout Button
            OutlinedButton.icon(
              onPressed: () {
                auth.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
              icon: const Icon(Icons.logout, color: KivoDarkTheme.accentRose, size: 18),
              label: const Text('Sign Out of Kivo', style: TextStyle(color: KivoDarkTheme.accentRose, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: BorderSide(color: KivoDarkTheme.accentRose.withOpacity(0.4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
