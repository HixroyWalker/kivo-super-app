import 'package:flutter/material.dart';
import '../../../core/theme/dark_theme.dart';
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
      'name': 'Marcus Sterling',
      'lastMessage': 'Received! Thanks a lot man. See you at 1:00 PM!',
      'type': 'TEXT',
      'time': '2:35 PM',
      'unread': 1,
      'isOnline': true,
      'label': 'Friend',
      'labelColor': KivoDarkTheme.accentCyan,
    },
    {
      'name': 'Mavis Bank Coffee Co.',
      'lastMessage': 'Your order has been shipped via Knutsford Express!',
      'type': 'TEXT',
      'time': '1:15 PM',
      'unread': 0,
      'isOnline': false,
      'label': 'Merchant',
      'labelColor': KivoDarkTheme.primaryEmerald,
    },
    {
      'name': 'Shenseea P.',
      'lastMessage': '💸 Sent JMD \$45,000.00 Design Retainer',
      'type': 'MONEY_TRANSFER',
      'time': 'Yesterday',
      'unread': 0,
      'isOnline': true,
      'label': 'Client',
      'labelColor': Colors.purpleAccent,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _chats.where((c) {
      final nameMatches = (c['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      final labelMatches = _selectedLabel == 'All' || c['label'] == _selectedLabel;
      return nameMatches && labelMatches;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Message'),
        actions: [
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
              style: const TextStyle(color: KivoDarkTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search conversations or contacts...',
                prefixIcon: Icon(Icons.search, color: KivoDarkTheme.textSecondary),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['All', 'Friend', 'Merchant', 'Client'].map((label) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(label),
                    selected: _selectedLabel == label,
                    onSelected: (selected) {
                      setState(() {
                        _selectedLabel = label;
                      });
                    },
                    selectedColor: KivoDarkTheme.primaryEmerald.withOpacity(0.2),
                    backgroundColor: KivoDarkTheme.surface,
                    labelStyle: TextStyle(
                      color: _selectedLabel == label ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.textSecondary,
                      fontWeight: _selectedLabel == label ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final chat = filtered[index];
                final isOnline = chat['isOnline'] as bool;
                final unread = chat['unread'] as int;
                final labelColor = chat['labelColor'] as Color;

                return Container(
                  decoration: BoxDecoration(
                    color: KivoDarkTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: KivoDarkTheme.surfaceBorder),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: labelColor.withOpacity(0.2),
                          child: Text(
                            (chat['name'] as String)[0],
                            style: TextStyle(color: labelColor, fontWeight: FontWeight.bold),
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
                                color: KivoDarkTheme.primaryEmerald,
                                shape: BoxShape.circle,
                                border: Border.all(color: KivoDarkTheme.surface, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat['name'],
                            style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        chat['lastMessage'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12),
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(chat['time'], style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11)),
                        const SizedBox(height: 4),
                        if (unread > 0)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: KivoDarkTheme.primaryEmerald,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$unread',
                              style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Select recipient to start chat')),
          );
        },
        icon: const Icon(Icons.edit, color: Colors.black),
        label: const Text('New Message', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
