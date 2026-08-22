import 'package:flutter/material.dart';
import 'wallet_provider.dart';

class ChatMessage {
  final String id;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isMe;
  final bool isPayment;
  final double? paymentAmount;
  final String? paymentNote;
  final String paymentStatus; // 'COMPLETED', 'PENDING'

  ChatMessage({
    required this.id,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.isPayment = false,
    this.paymentAmount,
    this.paymentNote,
    this.paymentStatus = 'COMPLETED',
  });
}

class ChatThread {
  final String id;
  final String peerName;
  final String peerAvatar;
  final bool isOnline;
  final int unreadCount;
  final List<ChatMessage> messages;
  final List<String> crmTags;

  ChatThread({
    required this.id,
    required this.peerName,
    required this.peerAvatar,
    this.isOnline = false,
    this.unreadCount = 0,
    required this.messages,
    this.crmTags = const [],
  });

  ChatMessage get lastMessage => messages.last;
}

class ChatProvider extends ChangeNotifier {
  final List<ChatThread> _threads = [
    ChatThread(
      id: 'thread-1',
      peerName: 'Marcus Sterling',
      peerAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      isOnline: true,
      unreadCount: 1,
      messages: [
        ChatMessage(
          id: 'msg-1',
          senderName: 'Marcus Sterling',
          text: 'Hey! Are we still grabbing lunch at Marketplace today?',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          isMe: false,
        ),
        ChatMessage(
          id: 'msg-2',
          senderName: 'You',
          text: 'Yeah definitely! I just sent you my share for the reservations.',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          isMe: true,
        ),
        ChatMessage(
          id: 'msg-3',
          senderName: 'You',
          text: 'P2P Transfer Sent',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          isMe: true,
          isPayment: true,
          paymentAmount: 4500.00,
          paymentNote: 'Devon House Lunch & Drinks 🍦🍹',
        ),
        ChatMessage(
          id: 'msg-4',
          senderName: 'Marcus Sterling',
          text: 'Received! Thanks a lot man. See you at 1:00 PM!',
          timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
          isMe: false,
        ),
      ],
    ),
    ChatThread(
      id: 'thread-2',
      peerName: 'Mavis Bank Coffee Co.',
      peerAvatar: 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=150',
      isOnline: false,
      unreadCount: 0,
      messages: [
        ChatMessage(
          id: 'msg-5',
          senderName: 'Mavis Bank Support',
          text: 'Good day! Your order for 2x Blue Mountain Coffee beans has been shipped via Knutsford Express.',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          isMe: false,
        ),
      ],
    ),
    ChatThread(
      id: 'thread-3',
      peerName: 'Shenseea P.',
      peerAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
      isOnline: true,
      unreadCount: 0,
      messages: [
        ChatMessage(
          id: 'msg-6',
          senderName: 'Shenseea P.',
          text: 'Thank you for the quick turnaround on the branding assets!',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          isMe: false,
        ),
        ChatMessage(
          id: 'msg-7',
          senderName: 'Shenseea P.',
          text: 'Retainer Payment Sent',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          isMe: false,
          isPayment: true,
          paymentAmount: 45000.00,
          paymentNote: 'Design Retainer 🎨',
        ),
      ],
    ),
  ];

  List<ChatThread> get threads => _threads;

  ChatThread getThread(String threadId) {
    return _threads.firstWhere((t) => t.id == threadId);
  }

  void sendMessage(String threadId, String text) {
    final thread = _threads.firstWhere((t) => t.id == threadId);
    thread.messages.add(
      ChatMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        senderName: 'You',
        text: text,
        timestamp: DateTime.now(),
        isMe: true,
      ),
    );
    notifyListeners();
  }

  void sendPaymentInChat(String threadId, double amount, String note, WalletProvider wallet) {
    final success = wallet.sendMoney(getThread(threadId).peerName, amount, note);
    if (success) {
      final thread = _threads.firstWhere((t) => t.id == threadId);
      thread.messages.add(
        ChatMessage(
          id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
          senderName: 'You',
          text: 'Payment Sent',
          timestamp: DateTime.now(),
          isMe: true,
          isPayment: true,
          paymentAmount: amount,
          paymentNote: note,
          paymentStatus: 'COMPLETED',
        ),
      );
      notifyListeners();
    }
  }
}
