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
  double _jmdBalance = 0.00;
  double _usdBalance = 0.00;
  bool _isJmd = true;
  bool _isBalanceVisible = true;

  double get jmdBalance => _jmdBalance;
  double get usdBalance => _usdBalance;
  bool get isJmd => _isJmd;
  bool get isBalanceVisible => _isBalanceVisible;
  String get userEmail => 'user@kivo.app';

  Future<bool> transferFunds({
    String? recipient,
    String? recipientIdentifier,
    required double amount,
    String note = '',
    String category = 'P2P',
  }) async {
    final target = recipientIdentifier ?? recipient ?? 'Recipient';
    return sendMoney(target, amount, note);
  }

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

  final List<TransactionItem> _transactions = [];

  List<TransactionItem> get transactions => _transactions;

  // Weekly spending chart data (Mon -> Sun)
  final List<double> weeklySpending = [0, 0, 0, 0, 0, 0, 0];

  bool _isLynkAutoCreditActive = false;
  String _lynkLinkedAccount = 'No Lynk Account Linked';
  String? _lynkUsername;
  bool _isLynkVerified = false;
  String? _pendingVerificationCode;
  double _pendingVerificationAmount = 0.0;
  bool _isVerifying = false;

  bool get isLynkAutoCreditActive => _isLynkAutoCreditActive;
  String get lynkLinkedAccount => _lynkLinkedAccount;
  String? get lynkUsername => _lynkUsername;
  bool get isLynkVerified => _isLynkVerified;
  String? get pendingVerificationCode => _pendingVerificationCode;
  double get pendingVerificationAmount => _pendingVerificationAmount;
  bool get isVerifying => _isVerifying;

  /// Initiate Lynk account verification test handshake
  Future<Map<String, dynamic>> initiateLynkVerification(String inputUsername) async {
    _isVerifying = true;
    notifyListeners();

    final formatted = inputUsername.trim().startsWith('@')
        ? inputUsername.trim()
        : '@${inputUsername.trim()}';

    await Future.delayed(const Duration(milliseconds: 1200));

    // Generate deterministic 4-digit verification code
    final code = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
    _pendingVerificationCode = code;
    _pendingVerificationAmount = 1.25;
    _lynkUsername = formatted;
    _isLynkVerified = false;
    _isVerifying = false;

    // Send micro-credit test transfer to prove ownership on Jamaican rail
    processIncomingLynkCredit(
      amount: _pendingVerificationAmount,
      senderName: 'Lynk BOJ Jam-Dex Test Rail ($formatted)',
      referenceCode: 'LNK-AUTH-$code',
    );

    notifyListeners();
    return {
      'success': true,
      'code': code,
      'amount': _pendingVerificationAmount,
      'username': formatted,
    };
  }

  /// Confirm the 4-digit security code received in the Lynk test transaction
  bool confirmLynkVerificationCode(String inputCode) {
    if (_pendingVerificationCode != null && inputCode.trim() == _pendingVerificationCode) {
      _isLynkVerified = true;
      _isLynkAutoCreditActive = true;
      _lynkLinkedAccount = 'Lynk BOJ Jam-Dex Linked ($_lynkUsername)';
      _pendingVerificationCode = null;

      _transactions.insert(
        0,
        TransactionItem(
          id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Lynk Account Ownership Verified 🇯🇲',
          subtitle: 'Linked $_lynkUsername • Real-time auto-crediting enabled',
          amount: 0.0,
          timestamp: DateTime.now(),
          icon: Icons.verified_user,
          iconColor: const Color(0xFF00E676),
          isCredit: true,
        ),
      );

      notifyListeners();
      return true;
    }
    return false;
  }

  /// Unlink Lynk account
  void unlinkLynkAccount() {
    _lynkUsername = null;
    _isLynkVerified = false;
    _isLynkAutoCreditActive = false;
    _lynkLinkedAccount = 'Not Linked';
    notifyListeners();
  }

  /// Automatically process incoming Lynk transfers without manual user top-up
  void processIncomingLynkCredit({
    required double amount,
    required String senderName,
    String? referenceCode,
  }) {
    _jmdBalance += amount;
    final ref = referenceCode ?? 'LNK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    _transactions.insert(
      0,
      TransactionItem(
        id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Lynk Auto-Credit Received',
        subtitle: 'Auto-credited from $senderName • Ref: $ref',
        amount: amount,
        timestamp: DateTime.now(),
        icon: Icons.account_balance,
        iconColor: const Color(0xFF00E676),
        isCredit: true,
      ),
    );
    notifyListeners();
  }

  /// Legacy manual helper maintained for backwards compatibility
  void topUpLynk(double amount) {
    processIncomingLynkCredit(
      amount: amount,
      senderName: 'Lynk Digital Gateway',
      referenceCode: 'AUTO-TOPUP',
    );
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
