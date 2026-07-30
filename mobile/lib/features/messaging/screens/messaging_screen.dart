import 'package:flutter/material.dart';
import 'chat_detail_screen.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  String _searchQuery = '';
  String _selectedLabel = 'All';

  final List<Map<String, dynamic>> _chats = [
    {
      'name': 'Kingston Wholesale',
      'lastMessage': 'Sent JMD \$5,000.00',
      'type': 'MONEY_TRANSFER',
      'time': '2:35 PM',
      'unread': 2,
      'isOnline': true,
      'label': 'Pending Payment',
      'labelColor': Colors.orange,
    },
    {
      'name': 'Appleton Estate Rep',
      'lastMessage': '🎤 Voice Note (0:14)',
      'type': 'VOICE',
      'time': '1:15 PM',
      'unread': 0,
      'isOnline': true,
      'label': 'VIP Customer',
      'labelColor': Colors.purple,
    },
    {
      'name': 'Farm Fresh Produce',
      'lastMessage': '📷 Product Photo attached',
      'type': 'IMAGE',
      'time': 'Yesterday',
      'unread': 1,
      'isOnline': false,
      'label': 'New Lead',
      'labelColor': Colors.blue,
    },
    {
      'name': 'Blue Mountain Coffee Co',
      'lastMessage': 'Your order has been shipped via Knutsford Express!',
      'type': 'TEXT',
      'time': 'Monday',
      'unread': 0,
      'isOnline': false,
      'label': 'Order Shipped',
      'labelColor': Colors.green,
    },
  ];

  void _showBusinessToolsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.store, color: Colors.green),
            SizedBox(width: 8),
            Text('WhatsApp Business Tools'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flash_on, color: Colors.amber),
              title: const Text('Quick Replies (/thanks, /hours)'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Manage canned Quick Replies...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.mark_email_read, color: Colors.blue),
              title: const Text('Automated Away & Greeting Message'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Auto-reply set to: "Welcome to Kivo Store!"')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.label, color: Colors.purple),
              title: const Text('Customer Label Categories'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _chats.where((c) {
      final nameMatches = (c['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      final labelMatches = _selectedLabel == 'All' || c['label'] == _selectedLabel;
      return nameMatches && labelMatches;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Business Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront, color: Colors.green),
            tooltip: 'Business Tools',
            onPressed: _showBusinessToolsDialog,
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
                hintText: 'Search chats or customer labels...',
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
          // WhatsApp Business Labels Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: ['All', 'Pending Payment', 'VIP Customer', 'New Lead', 'Order Shipped']
                  .map((label) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(label),
                          selected: _selectedLabel == label,
                          onSelected: (selected) {
                            setState(() => _selectedLabel = label);
                          },
                          selectedColor: Colors.green.shade100,
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final chat = filtered[index];
                final isOnline = chat['isOnline'] as bool;
                final unread = chat['unread'] as int;
                final labelColor = chat['labelColor'] as Color;

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
                  title: Row(
                    children: [
                      Expanded(child: Text(chat['name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: labelColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          chat['label'],
                          style: TextStyle(fontSize: 10, color: labelColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
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
