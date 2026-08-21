import 'package:cloud_firestore/cloud_firestore.dart';

enum RecurringFrequency { daily, weekly, fortnightly, monthly }

enum RecurringStatus { active, paused, cancelled }

class RecurringTransferModel {
  final String scheduleId;
  final String senderId;
  final String senderName;
  final String recipientIdentifier;
  final String recipientName;
  final double amount;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime nextExecutionDate;
  final RecurringStatus status;
  final String note;
  final int executionCount;
  final double totalTransferred;
  final DateTime? lastExecutionDate;

  RecurringTransferModel({
    required this.scheduleId,
    required this.senderId,
    required this.senderName,
    required this.recipientIdentifier,
    required this.recipientName,
    required this.amount,
    required this.frequency,
    required this.startDate,
    required this.nextExecutionDate,
    this.status = RecurringStatus.active,
    this.note = '',
    this.executionCount = 0,
    this.totalTransferred = 0.0,
    this.lastExecutionDate,
  });

  String get frequencyLabel {
    switch (frequency) {
      case RecurringFrequency.daily:
        return 'Daily';
      case RecurringFrequency.weekly:
        return 'Weekly';
      case RecurringFrequency.fortnightly:
        return 'Fortnightly (Every 2 Wks)';
      case RecurringFrequency.monthly:
        return 'Monthly';
    }
  }

  factory RecurringTransferModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    RecurringFrequency freq = RecurringFrequency.monthly;
    final freqStr = data['frequency'] as String? ?? 'monthly';
    if (freqStr == 'daily') freq = RecurringFrequency.daily;
    if (freqStr == 'weekly') freq = RecurringFrequency.weekly;
    if (freqStr == 'fortnightly') freq = RecurringFrequency.fortnightly;

    RecurringStatus st = RecurringStatus.active;
    final statusStr = data['status'] as String? ?? 'active';
    if (statusStr == 'paused') st = RecurringStatus.paused;
    if (statusStr == 'cancelled') st = RecurringStatus.cancelled;

    return RecurringTransferModel(
      scheduleId: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      recipientIdentifier: data['recipientIdentifier'] ?? '',
      recipientName: data['recipientName'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      frequency: freq,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      nextExecutionDate: (data['nextExecutionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: st,
      note: data['note'] ?? '',
      executionCount: data['executionCount'] ?? 0,
      totalTransferred: (data['totalTransferred'] ?? 0).toDouble(),
      lastExecutionDate: (data['lastExecutionDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'recipientIdentifier': recipientIdentifier,
      'recipientName': recipientName,
      'amount': amount,
      'frequency': frequency.name,
      'startDate': Timestamp.fromDate(startDate),
      'nextExecutionDate': Timestamp.fromDate(nextExecutionDate),
      'status': status.name,
      'note': note,
      'executionCount': executionCount,
      'totalTransferred': totalTransferred,
      'lastExecutionDate': lastExecutionDate != null ? Timestamp.fromDate(lastExecutionDate!) : null,
    };
  }

  DateTime calculateNextDate(DateTime fromDate) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return fromDate.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return fromDate.add(const Duration(days: 7));
      case RecurringFrequency.fortnightly:
        return fromDate.add(const Duration(days: 14));
      case RecurringFrequency.monthly:
        return DateTime(fromDate.year, fromDate.month + 1, fromDate.day);
    }
  }
}
