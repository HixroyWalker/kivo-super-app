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

  void _showAdminUnlockDialog(BuildContext context) {
    final pinController = TextEditingController();
    final auth = context.read<AuthProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KivoDarkTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: KivoDarkTheme.accentAmber, size: 22),
            SizedBox(width: 8),
            Text('Master Admin Verification', style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter Master Administrator Security PIN to authorize admin console on this device:', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 14),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(color: KivoDarkTheme.accentAmber, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: const InputDecoration(
                hintText: '••••',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: KivoDarkTheme.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: KivoDarkTheme.accentAmber),
            onPressed: () {
              final pin = pinController.text.trim();
              if (pin == '8760' || pin == '1234') {
                auth.unlockAdminConsole(pin);
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(backgroundColor: Colors.redAccent, content: Text('Invalid Master Admin PIN.')),
                );
              }
            },
            child: const Text('Authorize', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

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
                  Text(
                    auth.userDisplayName ?? 'Hixroy Walker',
                    style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${auth.userEmail ?? "@hixroy"} • Kingston, Jamaica 🇯🇲',
                    style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: KivoDarkTheme.primaryEmerald.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${auth.isMerchant ? "Verified Merchant" : "Tier 2 Verified Member"} • ${wallet.formattedBalance}',
                      style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // Master Admin Console Quick Access Banner (Strictly gated for Admins only)
            if (auth.isAdmin) ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                ),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: KivoDarkTheme.accentAmber.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(color: KivoDarkTheme.accentAmber.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: KivoDarkTheme.accentAmber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.admin_panel_settings, color: KivoDarkTheme.accentAmber, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Master Admin Console',
                                  style: TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.lock_open, color: KivoDarkTheme.accentAmber, size: 14),
                              ],
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Credit/debit user balances, fee rates & KYC review',
                              style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: KivoDarkTheme.accentAmber, size: 16),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

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
                  if (!auth.isAdmin) ...[
                    const Divider(color: KivoDarkTheme.surfaceBorder, height: 1),
                    ListTile(
                      leading: const Icon(Icons.lock_outline, color: Colors.white38),
                      title: const Text('Master Admin Login', style: TextStyle(color: Colors.white54, fontSize: 13)),
                      subtitle: const Text('Authorized system administrators only', style: TextStyle(color: Colors.white24, fontSize: 11)),
                      trailing: const Icon(Icons.pin, color: Colors.white38, size: 16),
                      onTap: () => _showAdminUnlockDialog(context),
                    ),
                  ],
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
