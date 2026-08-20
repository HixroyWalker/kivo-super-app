import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/dark_theme.dart';
import '../../../core/services/wallet_provider.dart';

class ChatDetailScreen extends StatefulWidget {
  final String merchantName;
  const ChatDetailScreen({super.key, required this.merchantName});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isRecordingVoice = false;
  bool _showQuickReplySuggestions = false;

  final List<Map<String, dynamic>> _quickReplies = [
    {'shortcut': '/hours', 'text': 'We are open Mon-Fri: 8:00 AM - 6:00 PM, Sat: 9:00 AM - 4:00 PM.'},
    {'shortcut': '/thanks', 'text': 'Thank you for choosing Kivo! Let us know if you need anything else.'},
    {'shortcut': '/delivery', 'text': 'We deliver nationwide across Jamaica via Knutsford Express & Zipmail!'},
  ];

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
      'type': 'PRODUCT',
      'productTitle': 'Blue Mountain Coffee (1kg)',
      'price': 3200.0,
      'content': 'Freshly roasted batch in stock!',
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
      'note': 'Coffee Order Payment',
      'time': '2:20 PM',
      'status': 'READ',
    },
  ];

  void _sendMessage({String type = 'TEXT', String? content, double? amount, String? duration, String? productTitle}) {
    final text = content ?? _controller.text.trim();
    if (type == 'TEXT' && text.isEmpty) return;

    setState(() {
      _messages.add({
        'id': 'm${_messages.length + 1}',
        'sender': 'me',
        'type': type,
        'content': text,
        'amount': amount,
        'productTitle': productTitle,
        'price': amount ?? 3200.0,
        'duration': duration ?? '0:10',
        'isPlaying': false,
        'time': 'Just now',
        'status': 'READ',
      });
      if (type == 'TEXT') {
        _controller.clear();
        _showQuickReplySuggestions = false;
      }
    });
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: KivoDarkTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Wrap(
          spacing: 24,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          children: [
            _buildAttachmentOption(Icons.attach_money, KivoDarkTheme.primaryEmerald, 'Send Money', () {
              Navigator.pop(context);
              _showSendMoneyDialog();
            }),
            _buildAttachmentOption(Icons.shopping_bag, Colors.orangeAccent, 'Product Card', () {
              Navigator.pop(context);
              _sendMessage(type: 'PRODUCT', productTitle: 'Appleton Estate Rum 750ml', amount: 4500.0, content: 'Special Reserve Rum');
            }),
            _buildAttachmentOption(Icons.camera_alt, Colors.pinkAccent, 'Camera', () {
              Navigator.pop(context);
              _sendMessage(type: 'IMAGE', content: '📷 Photo attached');
            }),
            _buildAttachmentOption(Icons.mic, KivoDarkTheme.accentCyan, 'Voice Note', () {
              Navigator.pop(context);
              _sendMessage(type: 'VOICE', duration: '0:15');
            }),
          ],
        ),
      ),
    );
  }

  void _showSendMoneyDialog() {
    final amountController = TextEditingController();
    final wallet = context.read<WalletProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KivoDarkTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Transfer to ${widget.merchantName}', style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available Balance: ${wallet.formattedBalance}', style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Amount (JMD)',
                prefixText: 'JMD \$ ',
                prefixStyle: TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: KivoDarkTheme.textSecondary))),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amountController.text.trim());
              if (amt != null && amt > 0) {
                if (wallet.jmdBalance >= amt) {
                  wallet.sendMoney(widget.merchantName, amt, 'In-Chat Transfer');
                  Navigator.pop(context);
                  _sendMessage(type: 'MONEY_TRANSFER', amount: amt);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Insufficient wallet balance.')),
                  );
                }
              }
            },
            child: const Text('Send Money Now'),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
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
              backgroundColor: KivoDarkTheme.primaryEmerald,
              child: Text(widget.merchantName[0], style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(widget.merchantName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, color: KivoDarkTheme.accentCyan, size: 16),
                  ],
                ),
                const Text('Verified Merchant • Online', style: TextStyle(fontSize: 11, color: KivoDarkTheme.primaryEmerald)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
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
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF1B382B) : KivoDarkTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isMe ? KivoDarkTheme.primaryEmerald.withOpacity(0.3) : KivoDarkTheme.surfaceBorder,
                      ),
                    ),
                    child: _buildMessageContent(msg, isMe),
                  ),
                );
              },
            ),
          ),
          if (_showQuickReplySuggestions) _buildQuickReplyOverlay(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildQuickReplyOverlay() {
    return Container(
      color: KivoDarkTheme.surfaceElevated,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Quick Reply Suggestions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: KivoDarkTheme.textSecondary)),
          const SizedBox(height: 4),
          ..._quickReplies.map((qr) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Text(qr['shortcut'], style: const TextStyle(fontWeight: FontWeight.bold, color: KivoDarkTheme.primaryEmerald)),
                title: Text(qr['text'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: KivoDarkTheme.textPrimary)),
                onTap: () {
                  _sendMessage(type: 'TEXT', content: qr['text']);
                },
              )),
        ],
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
            icon: Icon(msg['isPlaying'] == true ? Icons.pause_circle : Icons.play_circle, color: KivoDarkTheme.accentCyan, size: 32),
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
                Container(height: 4, decoration: BoxDecoration(color: KivoDarkTheme.accentCyan, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 4),
                Text('Voice Note (${msg['duration']})', style: const TextStyle(fontSize: 12, color: KivoDarkTheme.textSecondary)),
              ],
            ),
          ),
        ],
      );
    } else if (type == 'MONEY_TRANSFER') {
      body = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: KivoDarkTheme.primaryEmerald.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KivoDarkTheme.primaryEmerald.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance_wallet, color: KivoDarkTheme.primaryEmerald, size: 18),
                SizedBox(width: 8),
                Text('Kivo In-Chat Transfer', style: TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'JMD \$${(msg['amount'] as double).toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(msg['note'] ?? 'Direct Transfer', style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
          ],
        ),
      );
    } else {
      body = Text(msg['content'] ?? '', style: const TextStyle(fontSize: 15, color: KivoDarkTheme.textPrimary));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        body,
        const SizedBox(height: 4),
        Text(msg['time'] ?? '', style: const TextStyle(fontSize: 10, color: KivoDarkTheme.textSecondary)),
      ],
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: KivoDarkTheme.surface,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: KivoDarkTheme.accentCyan),
            onPressed: _showAttachmentMenu,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: KivoDarkTheme.textPrimary),
              onChanged: (val) {
                setState(() {
                  _showQuickReplySuggestions = val.startsWith('/');
                });
              },
              decoration: const InputDecoration(
                hintText: 'Type a message or / for quick replies...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          IconButton(
            icon: Icon(_isRecordingVoice ? Icons.stop_circle : Icons.mic, color: _isRecordingVoice ? KivoDarkTheme.accentRose : KivoDarkTheme.textSecondary),
            onPressed: () {
              setState(() => _isRecordingVoice = !_isRecordingVoice);
              if (!_isRecordingVoice) {
                _sendMessage(type: 'VOICE', duration: '0:08');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.send, color: KivoDarkTheme.primaryEmerald),
            onPressed: () => _sendMessage(type: 'TEXT'),
          ),
        ],
      ),
    );
  }
}
