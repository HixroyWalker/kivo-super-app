import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/dark_theme.dart';
import '../../../core/services/wallet_provider.dart';
import '../../wallet/widgets/transfer_modal.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../ads/screens/ads_screen.dart';
import '../../merchant/screens/pos_cashier_screen.dart';
import '../../merchant/screens/merchant_kyc_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _showTopUpDialog(BuildContext context) => _showLynkAutoCreditModal(context);

  void _showLynkAutoCreditModal(BuildContext context) {
    final usernameController = TextEditingController(text: context.read<WalletProvider>().lynkUsername ?? '');
    final codeController = TextEditingController();
    bool isVerifyingStep = false;
    String? generatedCode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KivoDarkTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final wallet = context.watch<WalletProvider>();

          return Padding(
            padding: EdgeInsets.only(
              top: 24,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: KivoDarkTheme.primaryEmerald.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.account_balance, color: KivoDarkTheme.primaryEmerald, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Lynk Account Verification', style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('Bank of Jamaica Jam-Dex Gateway', style: TextStyle(color: KivoDarkTheme.primaryEmerald, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (wallet.isLynkVerified && !isVerifyingStep) ...[
                    // Verified Status Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: KivoDarkTheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: KivoDarkTheme.primaryEmerald.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified, color: KivoDarkTheme.primaryEmerald, size: 20),
                              const SizedBox(width: 8),
                              Text('Verified Lynk Account: ${wallet.lynkUsername ?? "@kivo_kingston"}',
                                  style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ownership confirmed on Jam-Dex ledger. All incoming transfers to your Lynk handle automatically credit your Kivo balance in real time.',
                            style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                isVerifyingStep = true;
                                usernameController.text = wallet.lynkUsername ?? '';
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: KivoDarkTheme.surfaceBorder),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Re-test / Change Handle', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.bolt, color: Colors.black, size: 16),
                            label: const Text('Test Auto-Credit', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KivoDarkTheme.primaryEmerald,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              wallet.processIncomingLynkCredit(
                                amount: 2500.0,
                                senderName: 'Lynk Network (${wallet.lynkUsername})',
                              );
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: KivoDarkTheme.surfaceElevated,
                                  content: Text(
                                    '⚡ Automatically received and credited JMD \$2,500.00 from Lynk!',
                                    style: TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Username Input & Verification Test Form
                    const Text('Enter your Lynk Username / Handle:', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: usernameController,
                      style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: KivoDarkTheme.surface,
                        prefixIcon: const Icon(Icons.alternate_email, color: KivoDarkTheme.accentCyan),
                        hintText: 'e.g. yourname or @merchant_ja',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (generatedCode == null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: KivoDarkTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: KivoDarkTheme.surfaceBorder),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.security, color: KivoDarkTheme.accentAmber, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Kivo will ping the Jam-Dex rail with a \$1.25 JMD test transaction containing a 4-digit security code to verify account ownership.',
                                style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: wallet.isVerifying
                              ? null
                              : () async {
                                  final uname = usernameController.text.trim();
                                  if (uname.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter your Lynk username.')),
                                    );
                                    return;
                                  }
                                  final res = await wallet.initiateLynkVerification(uname);
                                  setModalState(() {
                                    generatedCode = res['code'];
                                  });
                                },
                          icon: wallet.isVerifying
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : const Icon(Icons.send_to_mobile, color: Colors.black),
                          label: Text(
                            wallet.isVerifying ? 'Running Test Handshake...' : 'Run Handshake & Send Micro-Test Code',
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KivoDarkTheme.accentAmber,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Code Confirmation Step
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: KivoDarkTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: KivoDarkTheme.primaryEmerald.withOpacity(0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.mark_email_read, color: KivoDarkTheme.primaryEmerald, size: 18),
                                SizedBox(width: 8),
                                Text('Test Transaction Initiated!', style: TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Test code sent to Jam-Dex rail: #$generatedCode (in transaction reference memo).',
                              style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Enter 4-Digit Verification PIN:', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: KivoDarkTheme.surface,
                          hintText: '••••',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final success = wallet.confirmLynkVerificationCode(codeController.text.trim());
                            if (success) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: KivoDarkTheme.surfaceElevated,
                                  content: Text(
                                    '✅ Lynk Account ${wallet.lynkUsername} verified successfully! Real-time auto-crediting is active.',
                                    style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.redAccent,
                                  content: Text('Invalid verification code. Please check and try again.'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.check_circle, color: Colors.black),
                          label: const Text('Confirm Account Ownership', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KivoDarkTheme.primaryEmerald,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showTransferModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TransferModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: KivoDarkTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.flash_on, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kivo Super App', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Kingston, Jamaica 🇯🇲', style: TextStyle(fontSize: 11, color: KivoDarkTheme.textSecondary)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Fintech Hero Card
            _buildHeroCard(context, wallet),

            const SizedBox(height: 24),

            // 2. Spending Analytics Section
            _buildSpendingSection(wallet),

            const SizedBox(height: 24),

            // 3. Super App Quick Grid
            const Text(
              'Super App Services',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: KivoDarkTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            _buildServicesGrid(context),

            const SizedBox(height: 24),

            // 4. Live Activity Feed
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: KivoDarkTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/wallet'),
                  child: const Text('View All', style: TextStyle(color: KivoDarkTheme.primaryEmerald, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildActivityFeed(wallet),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, WalletProvider wallet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF132F27), Color(0xFF0F1E2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KivoDarkTheme.primaryEmerald.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: KivoDarkTheme.primaryEmerald.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Total Available Balance', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13)),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: wallet.toggleBalanceVisibility,
                    child: Icon(
                      wallet.isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 16,
                      color: KivoDarkTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: wallet.toggleCurrency,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    wallet.isJmd ? 'JMD (Switch USD)' : 'USD (Switch JMD)',
                    style: const TextStyle(color: KivoDarkTheme.accentCyan, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: wallet.toggleBalanceVisibility,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Text(
                    wallet.formattedBalance,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    wallet.isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 20,
                    color: KivoDarkTheme.accentCyan,
                  ),
                  if (!wallet.isBalanceVisible) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: KivoDarkTheme.accentCyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Tap to show',
                        style: TextStyle(color: KivoDarkTheme.accentCyan, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionButton(
                icon: Icons.add,
                label: 'Lynk Link',
                color: KivoDarkTheme.primaryEmerald,
                onTap: () => _showLynkAutoCreditModal(context),
              ),
              _buildActionButton(
                icon: Icons.arrow_upward,
                label: 'Send',
                color: KivoDarkTheme.accentCyan,
                onTap: () => _showTransferModal(context),
              ),
              _buildActionButton(
                icon: Icons.arrow_downward,
                label: 'Request',
                color: KivoDarkTheme.accentAmber,
                onTap: () => _showTransferModal(context),
              ),
              _buildActionButton(
                icon: Icons.qr_code_scanner,
                label: 'Scan & Pay',
                color: Colors.purpleAccent,
                onTap: () => Navigator.pushNamed(context, '/wallet'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSpendingSection(WalletProvider wallet) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KivoDarkTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KivoDarkTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Weekly Activity', style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
              Text('Past 7 Days', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 16000,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Text(days[value.toInt()], style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 10));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: wallet.weeklySpending[i],
                        color: i == 5 ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.accentCyan.withOpacity(0.6),
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid(BuildContext context) {
    final services = [
      {'title': 'Admin Hub', 'icon': Icons.admin_panel_settings, 'color': KivoDarkTheme.accentCyan, 'route': '/admin'},
      {'title': 'Social Feed', 'icon': Icons.dynamic_feed, 'color': const Color(0xFFFFD700), 'route': '/social_feed'},
      {'title': 'Standing Orders', 'icon': Icons.schedule_send, 'color': KivoDarkTheme.accentCyan, 'route': '/standing_orders'},
      {'title': 'P2P Wallet', 'icon': Icons.account_balance_wallet, 'color': KivoDarkTheme.primaryEmerald, 'route': '/wallet'},
      {'title': 'Marketplace', 'icon': Icons.storefront, 'color': Colors.orangeAccent, 'route': '/marketplace'},
      {'title': 'Message', 'icon': Icons.chat_bubble_outline, 'color': Colors.purpleAccent, 'route': '/messaging'},
      {'title': 'TAJ GCT Tax', 'icon': Icons.receipt_long, 'color': Colors.tealAccent, 'route': '/accounting'},
      {'title': 'Merchant POS', 'icon': Icons.point_of_sale, 'color': KivoDarkTheme.primaryEmerald, 'route': '/merchant_pos'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final s = services[index];
        return InkWell(
          onTap: () {
            if (s['route'] == '/ads') {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdsScreen()));
            } else if (s['route'] == '/merchant_pos') {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PosCashierScreen()));
            } else {
              Navigator.pushNamed(context, s['route'] as String);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: KivoDarkTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: KivoDarkTheme.surfaceBorder),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(s['icon'] as IconData, size: 28, color: s['color'] as Color),
                const SizedBox(height: 8),
                Text(
                  s['title'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: KivoDarkTheme.textPrimary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityFeed(WalletProvider wallet) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: wallet.transactions.take(4).length,
      itemBuilder: (context, index) {
        final tx = wallet.transactions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: KivoDarkTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: KivoDarkTheme.surfaceBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tx.iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(tx.icon, color: tx.iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.title, style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(tx.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Text(
                '${tx.isCredit ? '+' : '-'}JMD \$${tx.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: tx.isCredit ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
