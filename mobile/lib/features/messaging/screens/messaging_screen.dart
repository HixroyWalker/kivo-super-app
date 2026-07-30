import 'package:flutter/material.dart';
import 'chat_detail_screen.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  String _searchQuery = '';
  final List<Map<String, dynamic>> _chats = [
    {
      'name': 'Kingston Wholesale',
      'lastMessage': 'Sent JMD \$5,000.00',
      'type': 'MONEY_TRANSFER',
      'time': '2:35 PM',
      'unread': 2,
      'isOnline': true,
    },
    {
      'name': 'Appleton Estate Rep',
      'lastMessage': '🎤 Voice Note (0:14)',
      'type': 'VOICE',
      'time': '1:15 PM',
      'unread': 0,
      'isOnline': true,
    },
    {
      'name': 'Farm Fresh Produce',
      'lastMessage': '📷 Product Photo attached',
      'type': 'IMAGE',
      'time': 'Yesterday',
      'unread': 1,
      'isOnline': false,
    },
    {
      'name': 'Blue Mountain Coffee Co',
      'lastMessage': 'Your order has been shipped via Knutsford Express!',
      'type': 'TEXT',
      'time': 'Monday',
      'unread': 0,
      'isOnline': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _chats
        .where((c) => (c['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening WhatsApp QR scanner...')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search chats or merchants...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final chat = filtered[index];
                final isOnline = chat['isOnline'] as bool;
                final unread = chat['unread'] as int;

                IconData typeIcon = Icons.message;
                if (chat['type'] == 'VOICE') typeIcon = Icons.mic;
                if (chat['type'] == 'IMAGE') typeIcon = Icons.camera_alt;
                if (chat['type'] == 'MONEY_TRANSFER') typeIcon = Icons.attach_money;

                return ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green.shade700,
                        child: Text(
                          (chat['name'] as String)[0],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.shade400,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(chat['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Row(
                    children: [
                      Icon(typeIcon, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          chat['lastMessage'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(chat['time'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      if (unread > 0)
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.green.shade700,
                          child: Text(
                            '$unread',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(merchantName: chat['name']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Select contact to start a new chat')),
          );
        },
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.chat),
      ),
    );
  }
}
