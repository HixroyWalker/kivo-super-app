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

class AdminProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AdminFeeConfig _feeConfig = AdminFeeConfig();
  List<KYCSubmission> _kycSubmissions = [];
  bool _isLoading = false;

  AdminFeeConfig get feeConfig => _feeConfig;
  List<KYCSubmission> get kycSubmissions => _kycSubmissions;
  List<KYCSubmission> get pendingKYCs => _kycSubmissions.where((k) => k.status == 'pending').toList();
  bool get isLoading => _isLoading;

  AdminProvider() {
    _initAdminData();
  }

  void _initAdminData() {
    _kycSubmissions = [];
    _loadFeeConfigFromFirestore();
    _listenToKYCSubmissions();
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
          // Initialize default document in Firestore if absent
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
          _kycSubmissions = [];
        }
        notifyListeners();
      }, onError: (e) {
        debugPrint('KYC stream error: $e');
        _kycSubmissions = [];
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error listening to KYC submissions: $e');
    }
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
      return true; // Optimistically updated
    }
  }

  /// Credit or Debit user balance from Admin Console
  Future<bool> adjustUserBalance({
    required String userIdentifier,
    required double amount,
    required bool isCredit,
    required String reason,
    required WalletProvider walletProvider,
  }) async {
    if (amount <= 0) return false;

    if (isCredit) {
      walletProvider.processIncomingLynkCredit(
        amount: amount,
        senderName: 'Admin Credit Adjustment ($reason)',
        referenceCode: 'ADM-CR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      );
    } else {
      walletProvider.sendMoney('Admin Debit ($reason)', amount, 'Administrative Adjustment: $reason');
    }

    try {
      await _firestore.collection('admin_audit_logs').add({
        'userIdentifier': userIdentifier,
        'action': isCredit ? 'CREDIT' : 'DEBIT',
        'amount': amount,
        'currency': 'JMD',
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Audit log write error: $e');
    }

    notifyListeners();
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
