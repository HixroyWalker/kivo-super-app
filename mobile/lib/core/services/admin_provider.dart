import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'wallet_provider.dart';

class KYCSubmission {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String accountType; // 'individual' or 'business'
  final String trnNumber;
  final String? businessName;
  final String? businessRegNumber;
  final String documentType;
  final String documentUrl;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime submittedAt;
  final String? reviewNote;

  KYCSubmission({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.accountType,
    required this.trnNumber,
    this.businessName,
    this.businessRegNumber,
    required this.documentType,
    required this.documentUrl,
    required this.status,
    required this.submittedAt,
    this.reviewNote,
  });

  factory KYCSubmission.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return KYCSubmission(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      userName: data['userName']?.toString() ?? 'Applicant',
      userEmail: data['userEmail']?.toString() ?? '',
      accountType: data['accountType']?.toString() ?? 'individual',
      trnNumber: data['trnNumber']?.toString() ?? '',
      businessName: data['businessName']?.toString(),
      businessRegNumber: data['businessRegNumber']?.toString(),
      documentType: data['documentType']?.toString() ?? 'National ID',
      documentUrl: data['documentUrl']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
      submittedAt: parseDate(data['submittedAt']),
      reviewNote: data['reviewNote']?.toString(),
    );
  }
}

class AdminFeeConfig {
  double p2pTransferFeePercent;
  double merchantProcessingFeePercent;
  double cashoutFeePercent;
  double marketplaceCommissionPercent;
  double gctTaxRatePercent;

  AdminFeeConfig({
    this.p2pTransferFeePercent = 0.5,
    this.merchantProcessingFeePercent = 1.5,
    this.cashoutFeePercent = 1.0,
    this.marketplaceCommissionPercent = 5.0,
    this.gctTaxRatePercent = 15.0,
  });
}

class AdminUserAccount {
  final String userId;
  final String name;
  final String handle;
  final String email;
  final String phone;
  final String accountType; // 'Personal' or 'Merchant'
  double balanceJMD;
  final bool isCurrentUser;

  AdminUserAccount({
    required this.userId,
    required this.name,
    required this.handle,
    required this.email,
    required this.phone,
    required this.accountType,
    required this.balanceJMD,
    this.isCurrentUser = false,
  });
}

class AdminAuditLog {
  final String id;
  final String userIdentifier;
  final String userName;
  final String action; // 'CREDIT' or 'DEBIT'
  final double amount;
  final String reason;
  final DateTime timestamp;

  AdminAuditLog({
    required this.id,
    required this.userIdentifier,
    required this.userName,
    required this.action,
    required this.amount,
    required this.reason,
    required this.timestamp,
  });
}

class AdminProvider extends ChangeNotifier {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  AdminFeeConfig _feeConfig = AdminFeeConfig();
  List<KYCSubmission> _kycSubmissions = [];
  List<AdminUserAccount> _registeredUsers = [];
  List<AdminAuditLog> _auditLogs = [];
  bool _isLoading = false;

  AdminFeeConfig get feeConfig => _feeConfig;
  List<KYCSubmission> get kycSubmissions => _kycSubmissions;
  List<KYCSubmission> get pendingKYCs => _kycSubmissions.where((k) => k.status == 'pending').toList();
  List<AdminUserAccount> get registeredUsers => _registeredUsers;
  List<AdminAuditLog> get auditLogs => _auditLogs;
  bool get isLoading => _isLoading;

  AdminProvider() {
    _initAdminData();
  }

  void _initAdminData() {
    _kycSubmissions = _generateDefaultKYCSubmissions();
    _registeredUsers = _generateDefaultUserAccounts();
    _auditLogs = _generateDefaultAuditLogs();
    _loadFeeConfigFromFirestore();
    _listenToKYCSubmissions();
    _listenToAuditLogs();
  }

  void _loadFeeConfigFromFirestore() {
    try {
      _firestore.collection('admin_settings').doc('fees').snapshots().listen((doc) {
        if (doc.exists) {
          final data = doc.data() ?? {};
          _feeConfig = AdminFeeConfig(
            p2pTransferFeePercent: (data['p2pTransferFeePercent'] as num?)?.toDouble() ?? 0.5,
            merchantProcessingFeePercent: (data['merchantProcessingFeePercent'] as num?)?.toDouble() ?? 1.5,
            cashoutFeePercent: (data['cashoutFeePercent'] as num?)?.toDouble() ?? 1.0,
            marketplaceCommissionPercent: (data['marketplaceCommissionPercent'] as num?)?.toDouble() ?? 5.0,
            gctTaxRatePercent: (data['gctTaxRatePercent'] as num?)?.toDouble() ?? 15.0,
          );
          notifyListeners();
        } else {
          _firestore.collection('admin_settings').doc('fees').set({
            'p2pTransferFeePercent': 0.5,
            'merchantProcessingFeePercent': 1.5,
            'cashoutFeePercent': 1.0,
            'marketplaceCommissionPercent': 5.0,
            'gctTaxRatePercent': 15.0,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }, onError: (e) {
        debugPrint('Admin fee config stream fallback: $e');
      });
    } catch (e) {
      debugPrint('Error loading fee config: $e');
    }
  }

  void _listenToKYCSubmissions() {
    try {
      _firestore.collection('kyc_submissions').orderBy('submittedAt', descending: true).limit(50).snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          _kycSubmissions = snap.docs.map((d) => KYCSubmission.fromFirestore(d)).toList();
        } else {
          _kycSubmissions = _generateDefaultKYCSubmissions();
        }
        notifyListeners();
      }, onError: (e) {
        debugPrint('KYC stream error: $e');
        _kycSubmissions = _generateDefaultKYCSubmissions();
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error listening to KYC submissions: $e');
      _kycSubmissions = _generateDefaultKYCSubmissions();
    }
  }

  void _listenToAuditLogs() {
    try {
      _firestore.collection('admin_audit_logs').orderBy('timestamp', descending: true).limit(30).snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          _auditLogs = snap.docs.map((d) {
            final data = d.data();
            DateTime dt = DateTime.now();
            if (data['timestamp'] is Timestamp) {
              dt = (data['timestamp'] as Timestamp).toDate();
            }
            return AdminAuditLog(
              id: d.id,
              userIdentifier: data['userIdentifier']?.toString() ?? '',
              userName: data['userName']?.toString() ?? data['userIdentifier']?.toString() ?? 'User',
              action: data['action']?.toString() ?? 'CREDIT',
              amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
              reason: data['reason']?.toString() ?? 'Admin Adjustment',
              timestamp: dt,
            );
          }).toList();
        }
        notifyListeners();
      }, onError: (e) {
        debugPrint('Audit logs stream error: $e');
      });
    } catch (e) {
      debugPrint('Error listening to audit logs: $e');
    }
  }

  List<AdminUserAccount> _generateDefaultUserAccounts() {
    return [
      AdminUserAccount(
        userId: 'current_user',
        name: 'My Active Wallet (Super Admin)',
        handle: '@admin',
        email: 'admin@kivowebb.app',
        phone: '+1 (876) 555-0100',
        accountType: 'Super Admin',
        balanceJMD: 250000.0,
        isCurrentUser: true,
      ),
      AdminUserAccount(
        userId: 'usr_merch_4821',
        name: 'Damian Clarke',
        handle: '@damianclarke',
        email: 'damian@jamaicacrafts.com',
        phone: '+1 (876) 701-4492',
        accountType: 'Merchant',
        balanceJMD: 84500.0,
      ),
      AdminUserAccount(
        userId: 'usr_ind_9921',
        name: 'Shanique Campbell',
        handle: '@shaniquec',
        email: 'shanique.c@gmail.com',
        phone: '+1 (876) 812-3309',
        accountType: 'Personal',
        balanceJMD: 12850.0,
      ),
      AdminUserAccount(
        userId: 'usr_merch_1102',
        name: 'Romaine Green (Blue Mtn Coffee)',
        handle: '@bluemtnroast',
        email: 'romaine@bluemountaincoffee.ja',
        phone: '+1 (876) 993-2210',
        accountType: 'Merchant',
        balanceJMD: 142000.0,
      ),
      AdminUserAccount(
        userId: 'usr_ind_3310',
        name: 'Marcus Bailey',
        handle: '@marcuscrafts',
        email: 'marcus.b@outlook.com',
        phone: '+1 (876) 620-8811',
        accountType: 'Personal',
        balanceJMD: 5320.0,
      ),
      AdminUserAccount(
        userId: 'usr_merch_7701',
        name: 'Keisha Kingston Bakes',
        handle: '@keishabakes',
        email: 'keisha@kingstonbakes.com',
        phone: '+1 (876) 431-7788',
        accountType: 'Merchant',
        balanceJMD: 67300.0,
      ),
    ];
  }

  List<AdminAuditLog> _generateDefaultAuditLogs() {
    final now = DateTime.now();
    return [
      AdminAuditLog(
        id: 'aud_1',
        userIdentifier: 'usr_merch_4821',
        userName: 'Damian Clarke',
        action: 'CREDIT',
        amount: 25000.0,
        reason: 'Merchant Settlement Payout Top-up',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      AdminAuditLog(
        id: 'aud_2',
        userIdentifier: 'usr_ind_9921',
        userName: 'Shanique Campbell',
        action: 'CREDIT',
        amount: 5000.0,
        reason: 'Administrative Top-up Grant',
        timestamp: now.subtract(const Duration(hours: 5)),
      ),
      AdminAuditLog(
        id: 'aud_3',
        userIdentifier: 'usr_merch_1102',
        userName: 'Romaine Green',
        action: 'DEBIT',
        amount: 1500.0,
        reason: 'TAJ Tax Adjustment Correction',
        timestamp: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  List<KYCSubmission> _generateDefaultKYCSubmissions() {
    final now = DateTime.now();
    return [
      KYCSubmission(
        id: 'kyc_101',
        userId: 'usr_merch_4821',
        userName: 'Damian Clarke',
        userEmail: 'damian@jamaicacrafts.com',
        accountType: 'business',
        trnNumber: '124-582-901',
        businessName: 'Kingston Artisan Crafts Ltd',
        businessRegNumber: 'COJ-94821-B',
        documentType: 'Companies Office of Jamaica Certificate + TCC',
        documentUrl: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=600',
        status: 'pending',
        submittedAt: now.subtract(const Duration(hours: 3)),
      ),
      KYCSubmission(
        id: 'kyc_102',
        userId: 'usr_ind_9921',
        userName: 'Shanique Campbell',
        userEmail: 'shanique.c@gmail.com',
        accountType: 'individual',
        trnNumber: '982-143-552',
        documentType: 'Jamaican Passport & Utility Bill',
        documentUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=600',
        status: 'pending',
        submittedAt: now.subtract(const Duration(hours: 6)),
      ),
      KYCSubmission(
        id: 'kyc_103',
        userId: 'usr_merch_1102',
        userName: 'Romaine Green',
        userEmail: 'romaine@bluemountaincoffee.ja',
        accountType: 'business',
        trnNumber: '331-902-114',
        businessName: 'Blue Mountain Roastmasters',
        businessRegNumber: 'COJ-11029-A',
        documentType: 'COJ Certificate of Incorporation',
        documentUrl: 'https://images.unsplash.com/photo-1450133064473-71024230f91b?w=600',
        status: 'approved',
        submittedAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  /// Update platform charges & fee rates
  Future<bool> updateFeeConfig({
    required double p2pPercent,
    required double merchantPercent,
    required double cashoutPercent,
    required double marketplacePercent,
    required double gctPercent,
  }) async {
    _feeConfig = AdminFeeConfig(
      p2pTransferFeePercent: p2pPercent,
      merchantProcessingFeePercent: merchantPercent,
      cashoutFeePercent: cashoutPercent,
      marketplaceCommissionPercent: marketplacePercent,
      gctTaxRatePercent: gctPercent,
    );
    notifyListeners();

    try {
      await _firestore.collection('admin_settings').doc('fees').set({
        'p2pTransferFeePercent': p2pPercent,
        'merchantProcessingFeePercent': merchantPercent,
        'cashoutFeePercent': cashoutPercent,
        'marketplaceCommissionPercent': marketplacePercent,
        'gctTaxRatePercent': gctPercent,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error saving fee config: $e');
      return true;
    }
  }

  /// Credit or Debit user balance from Admin Console
  Future<bool> adjustUserBalance({
    required String userIdentifier,
    required double amount,
    required bool isCredit,
    required String reason,
    required WalletProvider walletProvider,
    String? targetUserName,
  }) async {
    if (amount <= 0) return false;

    final resolvedName = targetUserName ?? userIdentifier;

    // 1. If modifying active wallet
    final isCurrent = userIdentifier == 'current_user' ||
        userIdentifier.toLowerCase() == 'my active wallet' ||
        userIdentifier == walletProvider.accountNumber ||
        userIdentifier == walletProvider.lynkUsername;

    if (isCurrent) {
      if (isCredit) {
        walletProvider.processIncomingLynkCredit(
          amount: amount,
          senderName: 'Admin Credit: $reason',
          referenceCode: 'ADM-CR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        );
      } else {
        walletProvider.sendMoney('Admin Debit ($reason)', amount, 'Admin Manual Adjustment: $reason');
      }
    }

    // 2. Update registered user cache if exists
    final userIdx = _registeredUsers.indexWhere((u) => u.userId == userIdentifier || u.name == userIdentifier || u.email == userIdentifier);
    if (userIdx != -1) {
      final oldUser = _registeredUsers[userIdx];
      final newBal = isCredit ? oldUser.balanceJMD + amount : (oldUser.balanceJMD - amount).clamp(0.0, double.infinity);
      _registeredUsers[userIdx] = AdminUserAccount(
        userId: oldUser.userId,
        name: oldUser.name,
        handle: oldUser.handle,
        email: oldUser.email,
        phone: oldUser.phone,
        accountType: oldUser.accountType,
        balanceJMD: newBal,
        isCurrentUser: oldUser.isCurrentUser,
      );
    }

    // 3. Record Audit Log in memory
    final newLog = AdminAuditLog(
      id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
      userIdentifier: userIdentifier,
      userName: resolvedName,
      action: isCredit ? 'CREDIT' : 'DEBIT',
      amount: amount,
      reason: reason,
      timestamp: DateTime.now(),
    );
    _auditLogs.insert(0, newLog);
    notifyListeners();

    // 4. Persist to Firestore
    try {
      await _firestore.collection('admin_audit_logs').doc(newLog.id).set({
        'userIdentifier': userIdentifier,
        'userName': resolvedName,
        'action': isCredit ? 'CREDIT' : 'DEBIT',
        'amount': amount,
        'currency': 'JMD',
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update Firestore user document
      if (userIdentifier != 'current_user') {
        await _firestore.collection('users').doc(userIdentifier).set({
          'balance': FieldValue.increment(isCredit ? amount : -amount),
          'lastBalanceAdjustment': {
            'action': isCredit ? 'CREDIT' : 'DEBIT',
            'amount': amount,
            'reason': reason,
            'timestamp': FieldValue.serverTimestamp(),
          }
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Audit log write error: $e');
    }

    return true;
  }

  /// Approve or Reject KYC Submission
  Future<void> reviewKYC({
    required String kycId,
    required bool approve,
    String? note,
  }) async {
    final idx = _kycSubmissions.indexWhere((k) => k.id == kycId);
    if (idx != -1) {
      final old = _kycSubmissions[idx];
      _kycSubmissions[idx] = KYCSubmission(
        id: old.id,
        userId: old.userId,
        userName: old.userName,
        userEmail: old.userEmail,
        accountType: old.accountType,
        trnNumber: old.trnNumber,
        businessName: old.businessName,
        businessRegNumber: old.businessRegNumber,
        documentType: old.documentType,
        documentUrl: old.documentUrl,
        status: approve ? 'approved' : 'rejected',
        submittedAt: old.submittedAt,
        reviewNote: note ?? (approve ? 'Verified by Administrator' : 'Rejected - please re-upload'),
      );
      notifyListeners();

      try {
        await _firestore.collection('kyc_submissions').doc(kycId).update({
          'status': approve ? 'approved' : 'rejected',
          'reviewNote': note,
          'reviewedAt': FieldValue.serverTimestamp(),
        });
        if (old.userId.isNotEmpty) {
          await _firestore.collection('users').doc(old.userId).set({
            'isVerified': approve,
            'kycStatus': approve ? 'approved' : 'rejected',
          }, SetOptions(merge: true));
        }
      } catch (e) {
        debugPrint('Error updating KYC status in Firestore: $e');
      }
    }
  }
}
