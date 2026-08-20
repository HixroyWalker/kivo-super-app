import 'package:flutter/material.dart';

class TransactionItem {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final String currency;
  final DateTime timestamp;
  final IconData icon;
  final Color iconColor;
  final bool isCredit;
  int likes;
  bool isLiked;
  final List<String> comments;

  TransactionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.currency = 'JMD',
    required this.timestamp,
    required this.icon,
    required this.iconColor,
    required this.isCredit,
    this.likes = 0,
    this.isLiked = false,
    List<String>? comments,
  }) : comments = comments ?? [];
}

class WalletProvider extends ChangeNotifier {
  double _jmdBalance = 124500.50;
  double _usdBalance = 820.00;
  bool _isJmd = true;
  bool _isBalanceVisible = true;

  double get jmdBalance => _jmdBalance;
  double get usdBalance => _usdBalance;
  bool get isJmd => _isJmd;
  bool get isBalanceVisible => _isBalanceVisible;

  String get formattedBalance {
    if (!_isBalanceVisible) return '••••••••';
    if (_isJmd) {
      return 'JMD \$${_jmdBalance.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    } else {
      return 'USD \$${_usdBalance.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    }
  }

  void toggleCurrency() {
    _isJmd = !_isJmd;
    notifyListeners();
  }

  void toggleBalanceVisibility() {
    _isBalanceVisible = !_isBalanceVisible;
    notifyListeners();
  }

  final List<TransactionItem> _transactions = [
    TransactionItem(
      id: 'tx-1',
      title: 'Lynk Wallet Top-Up',
      subtitle: 'Instant Bank Transfer • Bank of Jamaica Rail',
      amount: 15000.00,
      timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
      icon: Icons.account_balance,
      iconColor: const Color(0xFF00E676),
      isCredit: true,
      likes: 3,
    ),
    TransactionItem(
      id: 'tx-2',
      title: 'Sent to Marcus Sterling',
      subtitle: 'Dinner & Drinks at Devon House 🍦🍹',
      amount: 4500.00,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      icon: Icons.arrow_upward,
      iconColor: const Color(0xFFFF5252),
      isCredit: false,
      likes: 12,
      comments: ['Great times bro!', 'Next one on me 🙌'],
    ),
    TransactionItem(
      id: 'tx-3',
      title: 'Kivo Marketplace Purchase',
      subtitle: 'Blue Mountain Coffee (Medium Roast 1lb)',
      amount: 2800.00,
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      icon: Icons.shopping_bag,
      iconColor: const Color(0xFF00E5FF),
      isCredit: false,
      likes: 1,
    ),
    TransactionItem(
      id: 'tx-4',
      title: 'Received from Shenseea P.',
      subtitle: 'Freelance Design Retainer 🎨',
      amount: 45000.00,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      icon: Icons.arrow_downward,
      iconColor: const Color(0xFF00E676),
      isCredit: true,
      likes: 8,
    ),
    TransactionItem(
      id: 'tx-5',
      title: 'TAJ GCT Payment',
      subtitle: 'Tax Administration Jamaica • Ref #89302',
      amount: 6750.00,
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      icon: Icons.receipt_long,
      iconColor: const Color(0xFFFFB300),
      isCredit: false,
    ),
  ];

  List<TransactionItem> get transactions => _transactions;

  // Weekly spending chart data (Mon -> Sun)
  final List<double> weeklySpending = [4200, 7800, 2500, 11200, 6400, 14500, 5100];

  void topUpLynk(double amount) {
    _jmdBalance += amount;
    _transactions.insert(
      0,
      TransactionItem(
        id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Lynk Instant Top-Up',
        subtitle: 'Processed via Lynk Jamaica Gateway',
        amount: amount,
        timestamp: DateTime.now(),
        icon: Icons.account_balance,
        iconColor: const Color(0xFF00E676),
        isCredit: true,
      ),
    );
    notifyListeners();
  }

  bool sendMoney(String recipient, double amount, String note) {
    if (_jmdBalance < amount) return false;
    _jmdBalance -= amount;
    _transactions.insert(
      0,
      TransactionItem(
        id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Sent to $recipient',
        subtitle: note.isNotEmpty ? note : 'P2P Transfer',
        amount: amount,
        timestamp: DateTime.now(),
        icon: Icons.arrow_upward,
        iconColor: const Color(0xFFFF5252),
        isCredit: false,
      ),
    );
    notifyListeners();
    return true;
  }

  void toggleLike(String txId) {
    final tx = _transactions.firstWhere((t) => t.id == txId);
    if (tx.isLiked) {
      tx.likes--;
      tx.isLiked = false;
    } else {
      tx.likes++;
      tx.isLiked = true;
    }
    notifyListeners();
  }

  void addComment(String txId, String comment) {
    final tx = _transactions.firstWhere((t) => t.id == txId);
    tx.comments.add(comment);
    notifyListeners();
  }
}
