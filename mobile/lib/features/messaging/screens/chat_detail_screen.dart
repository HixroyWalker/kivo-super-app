import 'package:flutter/material.dart';

class ChatDetailScreen extends StatefulWidget {
  final String merchantName;
  const ChatDetailScreen({super.key, required this.merchantName});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isRecordingVoice = false;

  final List<Map<String, dynamic>> _messages = [
    {
      'id': 'm1',
      'sender': 'them',
      'type': 'TEXT',
      'content': 'Hi! Is the Blue Mountain Coffee still in stock?',
      'time': '2:15 PM',
      'status': 'READ',
    },
    {
      'id': 'm2',
      'sender': 'me',
      'type': 'TEXT',
      'content': 'Yes! Freshly roasted batch arrived today. JMD \$3,200/kg.',
      'time': '2:16 PM',
      'status': 'READ',
    },
    {
      'id': 'm3',
      'sender': 'them',
      'type': 'VOICE',
      'duration': '0:12',
      'isPlaying': false,
      'time': '2:18 PM',
      'status': 'READ',
    },
    {
      'id': 'm4',
      'sender': 'me',
      'type': 'MONEY_TRANSFER',
      'amount': 3200.0,
      'note': 'Coffee Order Payment Request',
      'time': '2:20 PM',
      'status': 'READ',
    },
  ];

  void _sendMessage({String type = 'TEXT', String? content, double? amount, String? duration}) {
    final text = content ?? _controller.text.trim();
    if (type == 'TEXT' && text.isEmpty) return;

    setState(() {
      _messages.add({
        'id': 'm${_messages.length + 1}',
        'sender': 'me',
        'type': type,
        'content': text,
        'amount': amount,
        'duration': duration ?? '0:10',
        'isPlaying': false,
        'time': 'Just now',
        'status': 'READ',
      });
      if (type == 'TEXT') _controller.clear();
    });
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Wrap(
          spacing: 24,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          children: [
            _buildAttachmentOption(Icons.attach_money, Colors.green, 'Send Money', () {
              Navigator.pop(context);
              _showSendMoneyDialog();
            }),
            _buildAttachmentOption(Icons.camera_alt, Colors.pink, 'Camera', () {
              Navigator.pop(context);
              _sendMessage(type: 'IMAGE', content: '📷 Photo attached');
            }),
            _buildAttachmentOption(Icons.mic, Colors.orange, 'Voice Note', () {
              Navigator.pop(context);
              _sendMessage(type: 'VOICE', duration: '0:15');
            }),
            _buildAttachmentOption(Icons.insert_drive_file, Colors.purple, 'Document', () {
              Navigator.pop(context);
              _sendMessage(type: 'TEXT', content: '📄 Invoice_Kivo_2026.pdf');
            }),
          ],
        ),
      ),
    );
  }

  void _showSendMoneyDialog() {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Transfer Money to ${widget.merchantName}'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount (JMD \$)',
            prefixText: '\$',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isEmpty) return;
              final amt = double.tryParse(amountController.text) ?? 0.0;
              Navigator.pop(context);
              _sendMessage(type: 'MONEY_TRANSFER', amount: amt);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Transferred JMD \$$amt in chat!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Send Money Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, Color color, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _triggerVoiceCall() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.phone_in_talk, color: Colors.green),
            const SizedBox(width: 8),
            Text('Calling ${widget.merchantName}...'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 40, backgroundColor: Colors.green, child: Icon(Icons.person, size: 40, color: Colors.white)),
            SizedBox(height: 16),
            Text('WhatsApp Voice Call Ringing...', style: TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_end, color: Colors.red, size: 36),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.green.shade700,
              child: Text(widget.merchantName[0], style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.merchantName, style: const TextStyle(fontSize: 16)),
                const Text('Online', style: TextStyle(fontSize: 12, color: Colors.greenAccent)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.green),
            tooltip: 'Audio Voice Call',
            onPressed: _triggerVoiceCall,
          ),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMe = msg['sender'] == 'me';

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.green.shade100 : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: _buildMessageContent(msg, isMe),
                    ),
                  );
                },
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(Map<String, dynamic> msg, bool isMe) {
    final type = msg['type'];

    Widget body;
    if (type == 'VOICE') {
      body = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(msg['isPlaying'] == true ? Icons.pause_circle : Icons.play_circle, color: Colors.green.shade800, size: 32),
            onPressed: () {
              setState(() {
                msg['isPlaying'] = !(msg['isPlaying'] ?? false);
              });
            },
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 4, color: Colors.green.shade300),
                const SizedBox(height: 4),
                Text('Voice Note (${msg['duration']})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      );
    } else if (type == 'MONEY_TRANSFER') {
      body = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade700,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Kivo In-Chat Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'JMD \$${msg['amount']}',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(msg['note'] ?? 'Direct Transfer', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      );
    } else if (type == 'IMAGE') {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: Icon(Icons.image, size: 48, color: Colors.grey)),
          ),
          const SizedBox(height: 4),
          Text(msg['content'] ?? '', style: const TextStyle(fontSize: 14)),
        ],
      );
    } else {
      body = Text(msg['content'] ?? '', style: const TextStyle(fontSize: 15));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        body,
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(msg['time'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            if (isMe) ...[
              const SizedBox(width: 4),
              const Icon(Icons.done_all, size: 14, color: Colors.blue),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.grey),
            onPressed: _showAttachmentMenu,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.grey),
            onPressed: () => _sendMessage(type: 'IMAGE', content: '📷 Photo attached'),
          ),
          IconButton(
            icon: Icon(_isRecordingVoice ? Icons.stop_circle : Icons.mic, color: _isRecordingVoice ? Colors.red : Colors.green.shade700),
            onPressed: () {
              setState(() => _isRecordingVoice = !_isRecordingVoice);
              if (!_isRecordingVoice) {
                _sendMessage(type: 'VOICE', duration: '0:08');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recording Voice Note... Tap again to send')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.green),
            onPressed: () => _sendMessage(type: 'TEXT'),
          ),
        ],
      ),
    );
  }
}
