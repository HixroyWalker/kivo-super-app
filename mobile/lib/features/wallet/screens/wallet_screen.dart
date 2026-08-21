import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/dark_theme.dart';
import '../../../core/services/wallet_provider.dart';
import '../widgets/transfer_modal.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showTransferModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TransferModal(),
    );
  }

  void _showReceiveQRModal(BuildContext context, WalletProvider wallet) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: KivoDarkTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Personal Receive QR',
              style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan to pay @hixroy instantly via Kivo or Lynk',
              style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.qr_code_2, size: 180, color: Colors.black),
            ),
            const SizedBox(height: 20),
            Text(
              'Kivo Handle: @hixroy • ${wallet.formattedBalance}',
              style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showCommentDialog(BuildContext context, TransactionItem tx, WalletProvider wallet) {
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KivoDarkTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Comments (${tx.title})', style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tx.comments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No comments yet. Be the first!', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13)),
              )
            else
              ...tx.comments.map((c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.comment, size: 14, color: KivoDarkTheme.accentCyan),
                        const SizedBox(width: 8),
                        Expanded(child: Text(c, style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 13))),
                      ],
                    ),
                  )),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              style: const TextStyle(color: KivoDarkTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Add a reply or emoji...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: KivoDarkTheme.textSecondary))),
          ElevatedButton(
            onPressed: () {
              if (commentController.text.trim().isNotEmpty) {
                wallet.addComment(tx.id, commentController.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('P2P Wallet & Social'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            onPressed: () => _showReceiveQRModal(context, wallet),
          ),
        ],
      ),
      body: Column(
        children: [
          // Bank Accounts & Cards Carousel
          _buildBankCardsCarousel(wallet),

          const SizedBox(height: 12),

          // Quick Action Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showTransferModal(context),
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Send / Pay'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showReceiveQRModal(context, wallet),
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: const Text('Receive QR'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tab Bar
          TabBar(
            controller: _tabController,
            indicatorColor: KivoDarkTheme.primaryEmerald,
            indicatorWeight: 3,
            labelColor: KivoDarkTheme.primaryEmerald,
            unselectedLabelColor: KivoDarkTheme.textSecondary,
            tabs: const [
              Tab(text: 'Social Feed 💬'),
              Tab(text: 'My Transactions 🧾'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Social Feed Tab
                _buildSocialFeed(wallet),
                // 2. Personal Statements Tab
                _buildPersonalStatements(wallet),
              ],
            ),
          ),
        ],
      ),
    );
  }


  void _showLynkVerificationSheet(BuildContext context, WalletProvider wallet) {
    final usernameController = TextEditingController(text: wallet.lynkUsername ?? '');
    final codeController = TextEditingController();
    String? generatedCode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KivoDarkTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(top: 24, left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
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
                          Text('Bank of Jamaica Jam-Dex Rail', style: TextStyle(color: KivoDarkTheme.primaryEmerald, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white54)),
                  ],
                ),
                const SizedBox(height: 18),
                if (wallet.isLynkVerified && generatedCode == null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: KivoDarkTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: KivoDarkTheme.primaryEmerald.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, color: KivoDarkTheme.primaryEmerald, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Verified Handle: ${wallet.lynkUsername}\nAutomatic direct-crediting active.',
                            style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        setModalState(() {
                          usernameController.text = wallet.lynkUsername ?? '';
                          generatedCode = '';
                        });
                      },
                      child: const Text('Re-test / Change Lynk Handle'),
                    ),
                  ),
                ] else ...[
                  const Text('Enter Lynk Handle to Verify Ownership:', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: usernameController,
                    style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: KivoDarkTheme.surface,
                      prefixIcon: const Icon(Icons.alternate_email, color: KivoDarkTheme.accentCyan),
                      hintText: '@username',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (generatedCode == null || generatedCode!.isEmpty) ...[
                    ElevatedButton.icon(
                      onPressed: () async {
                        final res = await wallet.initiateLynkVerification(usernameController.text.trim());
                        setModalState(() => generatedCode = res['code']);
                      },
                      icon: const Icon(Icons.send, color: Colors.black),
                      label: const Text('Send Micro-Test PIN to Jam-Dex Rail', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KivoDarkTheme.accentAmber,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: KivoDarkTheme.surface, borderRadius: BorderRadius.circular(10)),
                      child: Text('Test code sent: #$generatedCode (in transaction reference memo).', style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontSize: 12)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 6),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: KivoDarkTheme.surface,
                        hintText: 'PIN',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        final ok = wallet.confirmLynkVerificationCode(codeController.text.trim());
                        if (ok) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Lynk Account ownership verified successfully!')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invalid code. Please try again.')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KivoDarkTheme.primaryEmerald,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Confirm Ownership', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBankCardsCarousel(WalletProvider wallet) {
    final cards = [
      {
        'title': 'Kivo Main Wallet',
        'balance': wallet.formattedBalance,
        'tag': 'Primary Rail',
        'colors': [const Color(0xFF00E676), const Color(0xFF00B0FF)],
        'icon': Icons.account_balance_wallet,
      },
      {
        'title': 'Lynk Jamaica',
        'balance': wallet.isLynkVerified ? (wallet.lynkUsername ?? '@kivo_kingston') : 'Tap to Verify Handle',
        'tag': wallet.isLynkVerified ? 'Verified • Auto-Credit ON' : 'Unverified • Tap to Link',
        'colors': [const Color(0xFF00C853), const Color(0xFF1B5E20)],
        'icon': Icons.link,
      },
      {
        'title': 'Scotiabank Chequing',
        'balance': 'JMD \$88,400.00',
        'tag': 'Account **4821',
        'colors': [const Color(0xFFD50000), const Color(0xFF880E4F)],
        'icon': Icons.credit_card,
      },
    ];

    return SizedBox(
      height: 150,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final c = cards[index];
          return GestureDetector(
            onTap: () {
              if (c['title'] == 'Lynk Jamaica') {
                _showLynkVerificationSheet(context, wallet);
              }
            },
            child: Container(
              width: 260,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: c['colors'] as List<Color>,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (c['colors'] as List<Color>).first.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(c['title'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      Icon(c['icon'] as IconData, color: Colors.white, size: 20),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['balance'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(c['tag'] as String, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSocialFeed(WalletProvider wallet) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: wallet.transactions.length,
      itemBuilder: (context, index) {
        final tx = wallet.transactions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: tx.iconColor.withOpacity(0.15),
                      child: Icon(tx.icon, color: tx.iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tx.title, style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('25 mins ago • Kingston, JM', style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11)),
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
                const SizedBox(height: 12),
                Text(tx.subtitle, style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 13)),
                const SizedBox(height: 12),
                const Divider(color: KivoDarkTheme.surfaceBorder, height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: () => wallet.toggleLike(tx.id),
                      child: Row(
                        children: [
                          Icon(
                            tx.isLiked ? Icons.favorite : Icons.favorite_border,
                            color: tx.isLiked ? KivoDarkTheme.accentRose : KivoDarkTheme.textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text('${tx.likes}', style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    InkWell(
                      onTap: () => _showCommentDialog(context, tx, wallet),
                      child: Row(
                        children: [
                          const Icon(Icons.mode_comment_outlined, color: KivoDarkTheme.textSecondary, size: 18),
                          const SizedBox(width: 4),
                          Text('${tx.comments.length}', style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonalStatements(WalletProvider wallet) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: wallet.transactions.length,
      itemBuilder: (context, index) {
        final tx = wallet.transactions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: KivoDarkTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: KivoDarkTheme.surfaceBorder),
          ),
          child: Row(
            children: [
              Icon(tx.icon, color: tx.iconColor, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.title, style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(tx.subtitle, style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${tx.isCredit ? '+' : '-'}JMD \$${tx.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: tx.isCredit ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Text('Completed', style: TextStyle(color: KivoDarkTheme.primaryEmerald, fontSize: 10)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
