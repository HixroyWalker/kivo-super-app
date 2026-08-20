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
        'balance': 'JMD \$35,000.00',
        'tag': 'BOJ Jam-Dex Linked',
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
          return Container(
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
                Text(c['balance'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(c['tag'] as String, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ],
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
