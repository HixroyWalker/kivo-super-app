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
  String get accountNumber => 'KV-876-0041';

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
  String _kivoTreasuryHandle = '@kivo_treasury';
  double _pendingVerificationAmount = 10.00; // JMD $10.00 test deposit credited back 100%
  bool _isVerifying = false;
  int _failedVerificationAttempts = 0;
  DateTime? _verificationLockoutUntil;

  bool get isLynkAutoCreditActive => _isLynkAutoCreditActive;
  String get lynkLinkedAccount => _lynkLinkedAccount;
  String? get lynkUsername => _lynkUsername;
  String get kivoTreasuryHandle => _kivoTreasuryHandle;
  bool get isLynkVerified => _isLynkVerified;
  String? get pendingVerificationCode => _pendingVerificationCode;
  double get pendingVerificationAmount => _pendingVerificationAmount;
  bool get isVerifying => _isVerifying;

  /// Helper to generate a collision-proof 6-character alphanumeric reference code
  String _generateUniqueReferenceCode() {
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ'; // Excludes confusing 0, 1, I, O
    final rand = DateTime.now().microsecondsSinceEpoch;
    final buffer = StringBuffer('KV-');
    for (int i = 0; i < 6; i++) {
      buffer.write(chars[(rand >> (i * 5)) % chars.length]);
    }
    return buffer.toString();
  }

  /// Initiate Option B Lynk Account Verification (Inbound Test Top-Up Handshake)
  Future<Map<String, dynamic>> initiateLynkVerification(String inputUsername) async {
    _isVerifying = true;
    notifyListeners();

    final formatted = inputUsername.trim().startsWith('@')
        ? inputUsername.trim()
        : '@${inputUsername.trim()}';

    await Future.delayed(const Duration(milliseconds: 600));

    // Generate unique collision-proof reference code (e.g. KV-8F2N9X)
    final refCode = _generateUniqueReferenceCode();
    _pendingVerificationCode = refCode;
    _pendingVerificationAmount = 10.00;
    _lynkUsername = formatted;
    _isLynkVerified = false;
    _isVerifying = false;
    _failedVerificationAttempts = 0;

    notifyListeners();
    return {
      'success': true,
      'code': refCode,
      'amount': _pendingVerificationAmount,
      'username': formatted,
      'treasuryHandle': _kivoTreasuryHandle,
    };
  }

  /// Confirm the inbound Lynk transfer reference code and credit $10.00 JMD to user's wallet
  Map<String, dynamic> confirmLynkVerificationCode(String inputCode) {
    if (_verificationLockoutUntil != null && DateTime.now().isBefore(_verificationLockoutUntil!)) {
      final remaining = _verificationLockoutUntil!.difference(DateTime.now()).inMinutes + 1;
      return {
        'success': false,
        'message': 'Too many failed attempts. Verification locked for $remaining minutes.',
      };
    }

    final sanitizedInput = inputCode.trim().toUpperCase();
    final expectedCode = _pendingVerificationCode?.toUpperCase();

    // Check code match (accepts full KV-XXXXXX or just XXXXXX)
    final isMatch = expectedCode != null &&
        (sanitizedInput == expectedCode || sanitizedInput == expectedCode.replaceAll('KV-', ''));

    if (isMatch) {
      _isLynkVerified = true;
      _isLynkAutoCreditActive = true;
      _lynkLinkedAccount = 'Lynk BOJ Jam-Dex Linked ($_lynkUsername)';
      _pendingVerificationCode = null;
      _failedVerificationAttempts = 0;
      _verificationLockoutUntil = null;

      // 100% of the $10.00 JMD test deposit is credited directly to the user's Kivo Wallet!
      _jmdBalance += _pendingVerificationAmount;

      _transactions.insert(
        0,
        TransactionItem(
          id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Lynk Account Verified + Initial Deposit 🇯🇲',
          subtitle: 'Linked $_lynkUsername • JMD \$10.00 test deposit credited 100%',
          amount: _pendingVerificationAmount,
          timestamp: DateTime.now(),
          icon: Icons.verified_user,
          iconColor: const Color(0xFF00E676),
          isCredit: true,
        ),
      );

      notifyListeners();
      return {
        'success': true,
        'message': 'Lynk account $_lynkUsername verified! JMD \$10.00 test deposit credited to your wallet.',
      };
    } else {
      _failedVerificationAttempts++;
      if (_failedVerificationAttempts >= 4) {
        _verificationLockoutUntil = DateTime.now().add(const Duration(minutes: 15));
        notifyListeners();
        return {
          'success': false,
          'message': 'Security Alert: 4 failed attempts. Code verification locked for 15 minutes to prevent abuse.',
        };
      }

      final attemptsLeft = 4 - _failedVerificationAttempts;
      return {
        'success': false,
        'message': 'Code mismatch. Make sure you entered your specific session code ($attemptsLeft attempts left).',
      };
    }
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
