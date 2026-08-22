import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/dark_theme.dart';
import '../../../core/services/wallet_provider.dart';
import '../../../core/services/marketplace_provider.dart';
import '../../marketplace/screens/marketplace_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final String? merchantName;
  final String? contactName;
  final bool isOnline;
  const ChatDetailScreen({super.key, this.merchantName, this.contactName, this.isOnline = true});

  String get effectiveName => contactName ?? merchantName ?? 'Chat';

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isRecordingVoice = false;
  bool _showQuickReplySuggestions = false;
  bool _isMuted = false;

  final List<Map<String, dynamic>> _quickReplies = [
    {'shortcut': '/hours', 'text': 'We are open Mon-Fri: 8:00 AM - 6:00 PM, Sat: 9:00 AM - 4:00 PM.'},
    {'shortcut': '/thanks', 'text': 'Thank you for choosing Kivo! Let us know if you need anything else.'},
    {'shortcut': '/delivery', 'text': 'We deliver nationwide across Jamaica via Knutsford Express & Zipmail!'},
    {'shortcut': '/lynk', 'text': 'You can also pay via Lynk / Jam-Dex to our verified handle @kivo_merchant.'},
  ];

  final List<Map<String, dynamic>> _messages = [
    {
      'id': 'm1',
      'sender': 'them',
      'type': 'TEXT',
      'content': 'Hi! Welcome to our store! Let me know if you need any products or delivery.',
      'time': '2:15 PM',
      'status': 'READ',
    },
    {
      'id': 'm2',
      'sender': 'me',
      'type': 'PRODUCT',
      'productTitle': 'Blue Mountain Coffee (1kg)',
      'price': 3200.0,
      'imageUrl': 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=500',
      'content': 'Is this freshly roasted batch currently in stock?',
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

  void _sendMessage({
    String type = 'TEXT',
    String? content,
    double? amount,
    String? duration,
    String? productTitle,
    String? imageUrl,
    String? imagePath,
  }) {
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
        'price': amount,
        'imageUrl': imageUrl,
        'imagePath': imagePath,
        'duration': duration ?? '0:10',
        'isPlaying': false,
        'time': 'Just now',
        'status': 'SENT',
      });
      if (type == 'TEXT') {
        _controller.clear();
        _showQuickReplySuggestions = false;
      }
    });
  }

  // Pick Image from Camera or Gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (photo != null) {
        _sendMessage(
          type: 'IMAGE',
          imagePath: photo.path,
          content: source == ImageSource.camera ? 'Photo from camera' : 'Photo from gallery',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access camera/gallery: $e')),
        );
      }
    }
  }

  // Open Store Product Picker Modal
  void _showProductPicker() {
    final marketplace = context.read<MarketplaceProvider>();
    final products = marketplace.products;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KivoDarkTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.shopping_bag_outlined, color: Colors.orangeAccent),
                SizedBox(width: 10),
                Text(
                  'Attach Product from Store',
                  style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                itemCount: products.length,
                separatorBuilder: (_, __) => const Divider(color: KivoDarkTheme.surfaceBorder),
                itemBuilder: (context, i) {
                  final p = products[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: p.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(p.name, style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(
                      'JMD \$${p.price.toStringAsFixed(2)} • ${p.sellerName}',
                      style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _sendMessage(
                          type: 'PRODUCT',
                          productTitle: p.name,
                          amount: p.price,
                          imageUrl: p.imageUrl,
                          content: p.description,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KivoDarkTheme.primaryEmerald,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      child: const Text('Attach', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
          spacing: 20,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: [
            _buildAttachmentOption(Icons.attach_money, KivoDarkTheme.primaryEmerald, 'Send Money', () {
              Navigator.pop(context);
              _showSendMoneyDialog();
            }),
            _buildAttachmentOption(Icons.shopping_bag, Colors.orangeAccent, 'Product Card', () {
              Navigator.pop(context);
              _showProductPicker();
            }),
            _buildAttachmentOption(Icons.camera_alt, Colors.pinkAccent, 'Camera', () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            }),
            _buildAttachmentOption(Icons.photo_library, Colors.purpleAccent, 'Gallery Photo', () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            }),
            _buildAttachmentOption(Icons.mic, KivoDarkTheme.accentCyan, 'Voice Note', () {
              Navigator.pop(context);
              _toggleVoiceRecording();
            }),
          ],
        ),
      ),
    );
  }

  void _toggleVoiceRecording() {
    setState(() {
      _isRecordingVoice = !_isRecordingVoice;
    });

    if (!_isRecordingVoice) {
      _sendMessage(type: 'VOICE', duration: '0:08');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice note recorded and sent! 🎙️')),
      );
    }
  }

  void _showSendMoneyDialog() {
    final amountController = TextEditingController();
    final wallet = context.read<WalletProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KivoDarkTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Transfer to ${widget.effectiveName}', style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available Balance: ${wallet.formattedBalance}', style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                  wallet.sendMoney(widget.effectiveName, amt, 'In-Chat Transfer');
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
              child: Text(widget.effectiveName.isNotEmpty ? widget.effectiveName[0] : 'C', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(widget.effectiveName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, color: KivoDarkTheme.accentCyan, size: 16),
                  ],
                ),
                Text(
                  _isMuted ? 'Muted Notifications' : 'Verified Merchant • Online',
                  style: TextStyle(fontSize: 11, color: _isMuted ? Colors.white54 : KivoDarkTheme.primaryEmerald),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Functional 3-Dots Overflow Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: KivoDarkTheme.surfaceElevated,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (action) {
              if (action == 'clear') {
                setState(() => _messages.clear());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat history cleared.')),
                );
              } else if (action == 'storefront') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MarketplaceScreen()));
              } else if (action == 'mute') {
                setState(() => _isMuted = !_isMuted);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_isMuted ? 'Notifications muted for this conversation.' : 'Notifications unmuted.')),
                );
              } else if (action == 'export') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exported chat transcript to PDF/Text.')),
                );
              } else if (action == 'block') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${widget.effectiveName} blocked and reported to Admin.')),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'storefront',
                child: Row(
                  children: [
                    Icon(Icons.storefront, color: Colors.orangeAccent, size: 18),
                    SizedBox(width: 10),
                    Text('View Storefront', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'mute',
                child: Row(
                  children: [
                    Icon(_isMuted ? Icons.notifications : Icons.notifications_off, color: KivoDarkTheme.accentCyan, size: 18),
                    SizedBox(width: 10),
                    Text(_isMuted ? 'Unmute Notifications' : 'Mute Notifications', style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, color: KivoDarkTheme.primaryEmerald, size: 18),
                    SizedBox(width: 10),
                    Text('Export Transcript', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: KivoDarkTheme.accentRose, size: 18),
                    SizedBox(width: 10),
                    Text('Clear Chat History', style: TextStyle(color: KivoDarkTheme.accentRose)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.redAccent, size: 18),
                    SizedBox(width: 10),
                    Text('Block / Report User', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text('No messages yet. Send a greeting or order inquiry!', style: TextStyle(color: KivoDarkTheme.textSecondary)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['sender'] == 'me';

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
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
    if (type == 'IMAGE') {
      final imagePath = msg['imagePath'] as String?;
      final imageUrl = msg['imageUrl'] as String?;

      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imagePath != null
                ? Image.file(
                    File(imagePath),
                    width: 220,
                    height: 200,
                    fit: BoxFit.cover,
                  )
                : CachedNetworkImage(
                    imageUrl: imageUrl ?? 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=500',
                    width: 220,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
          ),
          if (msg['content'] != null && (msg['content'] as String).isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(msg['content'], style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 13)),
          ],
        ],
      );
    } else if (type == 'PRODUCT') {
      final title = msg['productTitle'] ?? 'Product';
      final price = (msg['price'] as num?)?.toDouble() ?? 0.0;
      final imgUrl = msg['imageUrl'] as String?;

      body = Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: KivoDarkTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imgUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imgUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text('JMD \$${price.toStringAsFixed(2)}', style: const TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold, fontSize: 15)),
            if (msg['content'] != null) ...[
              const SizedBox(height: 4),
              Text(msg['content'], style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final wallet = context.read<WalletProvider>();
                  if (wallet.jmdBalance >= price) {
                    wallet.sendMoney(widget.effectiveName, price, 'Purchase: $title');
                    _sendMessage(type: 'MONEY_TRANSFER', amount: price, content: 'Paid for $title');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Insufficient balance to pay for this item.')),
                    );
                  }
                },
                icon: const Icon(Icons.payment, size: 16),
                label: const Text('Pay with Kivo Balance', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KivoDarkTheme.primaryEmerald,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (type == 'VOICE') {
      body = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(msg['isPlaying'] == true ? Icons.pause_circle : Icons.play_circle, color: KivoDarkTheme.accentCyan, size: 34),
            onPressed: () {
              setState(() {
                msg['isPlaying'] = !(msg['isPlaying'] ?? false);
              });
            },
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: KivoDarkTheme.accentCyan,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Voice Note (${msg['duration']})', style: const TextStyle(fontSize: 11, color: KivoDarkTheme.textSecondary)),
                    const Icon(Icons.graphic_eq, color: KivoDarkTheme.accentCyan, size: 16),
                  ],
                ),
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
              'JMD \$${((msg['amount'] ?? 0.0) as double).toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(msg['note'] ?? msg['content'] ?? 'Direct Transfer', style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12)),
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(msg['time'] ?? '', style: const TextStyle(fontSize: 10, color: KivoDarkTheme.textSecondary)),
            if (isMe) ...[
              const SizedBox(width: 4),
              const Icon(Icons.done_all, size: 12, color: KivoDarkTheme.accentCyan),
            ],
          ],
        ),
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
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, color: Colors.pinkAccent),
            onPressed: () => _pickImage(ImageSource.camera),
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
                hintText: 'Type a message or / for replies...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isRecordingVoice ? Icons.stop_circle : Icons.mic,
              color: _isRecordingVoice ? KivoDarkTheme.accentRose : KivoDarkTheme.accentCyan,
            ),
            onPressed: _toggleVoiceRecording,
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
