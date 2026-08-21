import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/recurring_transfer_model.dart';
import 'wallet_provider.dart';

class RecurringTransferService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<RecurringTransferModel> _schedules = [];
  bool _isLoading = false;

  List<RecurringTransferModel> get schedules => _schedules;
  List<RecurringTransferModel> get activeSchedules =>
      _schedules.where((s) => s.status == RecurringStatus.active).toList();
  bool get isLoading => _isLoading;

  RecurringTransferService() {
    _initSchedules();
  }

  void _initSchedules() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      _schedules = _generateSampleSchedules();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _firestore
          .collection('recurring_transfers')
          .where('senderId', isEqualTo: userId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isEmpty) {
          _schedules = [];
        } else {
          _schedules = snapshot.docs.map((d) => RecurringTransferModel.fromFirestore(d)).toList();
        }
        _isLoading = false;
        notifyListeners();
      }, onError: (e) {
        debugPrint("Firestore recurring transfer stream error: $e");
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      debugPrint("Error initializing recurring transfers listener: $e");
      _isLoading = false;
      notifyListeners();
    }
  }

  List<RecurringTransferModel> _generateSampleSchedules() {
    final now = DateTime.now();
    return [
      RecurringTransferModel(
        scheduleId: 'rec_sample_1',
        senderId: _auth.currentUser?.uid ?? 'guest_user',
        senderName: 'Hixroy Walker',
        recipientIdentifier: 'mom@kivowebb.app',
        recipientName: 'Mom (Family Allowance)',
        amount: 15000.0,
        frequency: RecurringFrequency.fortnightly,
        startDate: now.subtract(const Duration(days: 14)),
        nextExecutionDate: now.add(const Duration(days: 2)),
        status: RecurringStatus.active,
        note: 'Fortnightly Family Support',
        executionCount: 1,
        totalTransferred: 15000.0,
      ),
      RecurringTransferModel(
        scheduleId: 'rec_sample_2',
        senderId: _auth.currentUser?.uid ?? 'guest_user',
        senderName: 'Hixroy Walker',
        recipientIdentifier: 'landlord@kivowebb.app',
        recipientName: 'Apartment Rent',
        amount: 45000.0,
        frequency: RecurringFrequency.monthly,
        startDate: now.subtract(const Duration(days: 30)),
        nextExecutionDate: DateTime(now.year, now.month + 1, 1),
        status: RecurringStatus.active,
        note: 'Monthly New Kingston Apartment Rent',
        executionCount: 2,
        totalTransferred: 90000.0,
      ),
    ];
  }

  /// Create a new standing order schedule
  Future<void> createSchedule({
    required String recipientIdentifier,
    required String recipientName,
    required double amount,
    required RecurringFrequency frequency,
    required DateTime startDate,
    String note = '',
  }) async {
    final user = _auth.currentUser;
    final senderId = user?.uid ?? 'guest_user';
    final senderName = user?.displayName ?? 'Kivo User';

    final scheduleId = 'rec_${DateTime.now().millisecondsSinceEpoch}';
    final newSchedule = RecurringTransferModel(
      scheduleId: scheduleId,
      senderId: senderId,
      senderName: senderName,
      recipientIdentifier: recipientIdentifier,
      recipientName: recipientName,
      amount: amount,
      frequency: frequency,
      startDate: startDate,
      nextExecutionDate: startDate,
      status: RecurringStatus.active,
      note: note,
    );

    _schedules.insert(0, newSchedule);
    notifyListeners();

    try {
      await _firestore.collection('recurring_transfers').doc(scheduleId).set(newSchedule.toMap());
    } catch (e) {
      debugPrint("Error writing recurring transfer to Firestore: $e");
    }
  }

  /// Pause / Resume Schedule
  Future<void> toggleScheduleStatus(String scheduleId) async {
    final index = _schedules.indexWhere((s) => s.scheduleId == scheduleId);
    if (index == -1) return;

    final s = _schedules[index];
    final newStatus = s.status == RecurringStatus.active ? RecurringStatus.paused : RecurringStatus.active;

    _schedules[index] = RecurringTransferModel(
      scheduleId: s.scheduleId,
      senderId: s.senderId,
      senderName: s.senderName,
      recipientIdentifier: s.recipientIdentifier,
      recipientName: s.recipientName,
      amount: s.amount,
      frequency: s.frequency,
      startDate: s.startDate,
      nextExecutionDate: s.nextExecutionDate,
      status: newStatus,
      note: s.note,
      executionCount: s.executionCount,
      totalTransferred: s.totalTransferred,
      lastExecutionDate: s.lastExecutionDate,
    );
    notifyListeners();

    try {
      await _firestore.collection('recurring_transfers').doc(scheduleId).update({
        'status': newStatus.name,
      });
    } catch (e) {
      debugPrint("Error updating schedule status: $e");
    }
  }

  /// Cancel Schedule
  Future<void> cancelSchedule(String scheduleId) async {
    _schedules.removeWhere((s) => s.scheduleId == scheduleId);
    notifyListeners();

    try {
      await _firestore.collection('recurring_transfers').doc(scheduleId).update({
        'status': RecurringStatus.cancelled.name,
      });
    } catch (e) {
      debugPrint("Error cancelling schedule: $e");
    }
  }

  /// Execute Due Standing Orders
  Future<void> processDueTransfers(WalletProvider walletProvider) async {
    final now = DateTime.now();
    for (int i = 0; i < _schedules.length; i++) {
      final s = _schedules[i];
      if (s.status == RecurringStatus.active && s.nextExecutionDate.isBefore(now)) {
        final success = await walletProvider.transferFunds(
          recipientIdentifier: s.recipientIdentifier,
          amount: s.amount,
          note: 'Standing Order: ${s.note.isNotEmpty ? s.note : s.frequencyLabel}',
        );

        if (success) {
          final nextDate = s.calculateNextDate(s.nextExecutionDate);
          _schedules[i] = RecurringTransferModel(
            scheduleId: s.scheduleId,
            senderId: s.senderId,
            senderName: s.senderName,
            recipientIdentifier: s.recipientIdentifier,
            recipientName: s.recipientName,
            amount: s.amount,
            frequency: s.frequency,
            startDate: s.startDate,
            nextExecutionDate: nextDate,
            status: s.status,
            note: s.note,
            executionCount: s.executionCount + 1,
            totalTransferred: s.totalTransferred + s.amount,
            lastExecutionDate: now,
          );
          notifyListeners();

          try {
            await _firestore.collection('recurring_transfers').doc(s.scheduleId).update({
              'nextExecutionDate': Timestamp.fromDate(nextDate),
              'executionCount': FieldValue.increment(1),
              'totalTransferred': FieldValue.increment(s.amount),
              'lastExecutionDate': Timestamp.fromDate(now),
            });
          } catch (e) {
            debugPrint("Error recording executed schedule in Firestore: $e");
          }
        }
      }
    }
  }
}
