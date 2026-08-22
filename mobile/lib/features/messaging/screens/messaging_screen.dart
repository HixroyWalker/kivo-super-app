import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/dark_theme.dart';
import '../../../core/services/social_feed_provider.dart';
import '../../../core/services/marketplace_provider.dart';
import '../../../ui/screens/social/social_feed_screen.dart';
import '../../../ui/screens/social/create_post_screen.dart';
import 'chat_detail_screen.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  // Active ongoing chat threads
  final List<Map<String, dynamic>> _chats = [
    {
      'name': 'Marcus Sterling',
      'handle': '@marcus',
      'lastMessage': 'Received! Thanks a lot man. See you at 1:00 PM!',
      'type': 'TEXT',
      'time': '2:35 PM',
      'unread': 1,
      'isOnline': true,
      'isBusiness': false,
      'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
    },
    {
      'name': 'Mavis Bank Agro Co.',
      'handle': '@mavisbankagro',
      'lastMessage': 'Your Blue Mountain Coffee order has shipped via Knutsford Express!',
      'type': 'TEXT',
      'time': '1:15 PM',
      'unread': 0,
      'isOnline': true,
      'isBusiness': true,
      'avatar': 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=150',
    },
    {
      'name': 'Shenseea P.',
      'handle': '@shenseea',
      'lastMessage': '💸 Sent JMD \$45,000.00 Design Retainer',
      'type': 'MONEY_TRANSFER',
      'time': 'Yesterday',
      'unread': 0,
      'isOnline': false,
      'isBusiness': false,
      'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    },
  ];

  // 24-hour Status / Broadcast stories
  final List<Map<String, dynamic>> _statusStories = [
    {
      'name': 'My Status',
      'handle': '@hixroy',
      'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      'isMyStatus': true,
      'caption': 'Tap + to share an update or broadcast to followers',
      'time': 'Tap to Add',
    },
    {
      'name': 'Keisha Bakes',
      'handle': '@keishabakes',
      'avatar': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      'isMyStatus': false,
      'caption': 'Fresh spiced patties out of the oven! 50 boxes left in New Kingston 🔥',
      'time': '15m ago',
    },
    {
      'name': 'Mavis Bank Agro',
      'handle': '@mavisbankagro',
      'avatar': 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=150',
      'isMyStatus': false,
      'caption': 'Peaberry reserve now available for all-island delivery ☕⛰️',
      'time': '1h ago',
    },
    {
      'name': 'Marcus Crafts',
      'handle': '@marcuscrafts',
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      'isMyStatus': false,
      'caption': 'New Blue Mahoe cedar carvings completed today! 🎨',
      'time': '3h ago',
    },
  ];

  // All searchable platform directory contacts
  final List<Map<String, dynamic>> _directoryContacts = [
    {
      'name': 'Mavis Bank Agro Co.',
      'handle': '@mavisbankagro',
      'category': 'Verified Jamaican Merchant',
      'isBusiness': true,
      'avatar': 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=150',
    },
    {
      'name': 'Keisha Kingston Bakes',
      'handle': '@keishabakes',
      'category': 'Bakery & Food Merchant',
      'isBusiness': true,
      'avatar': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
    },
    {
      'name': 'Trench Town Artisans',
      'handle': '@trenchtowncrafts',
      'category': 'Leathercraft & Art Merchant',
      'isBusiness': true,
      'avatar': 'https://images.unsplash.com/photo-1627123424574-724758594e93?w=150',
    },
    {
      'name': 'Island Tech Depot',
      'handle': '@islandtech',
      'category': 'Electronics & Solar Merchant',
      'isBusiness': true,
      'avatar': 'https://images.unsplash.com/photo-1609091839311-d5368f9bc14a?w=150',
    },
    {
      'name': 'Mama Grace Spices',
      'handle': '@mamagracespices',
      'category': 'Hot Sauces & Seasonings Merchant',
      'isBusiness': true,
      'avatar': 'https://images.unsplash.com/photo-1588854337236-6889d631faa8?w=150',
    },
    {
      'name': 'Damian Clarke',
      'handle': '@damianclarke',
      'category': 'Individual Member',
      'isBusiness': false,
      'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
    },
    {
      'name': 'Shanique Campbell',
      'handle': '@shaniquec',
      'category': 'Individual Member',
      'isBusiness': false,
      'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    },
    {
      'name': 'Romaine Green',
      'handle': '@bluemtnroast',
      'category': 'Coffee Merchant & Roaster',
      'isBusiness': true,
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
    },
    {
      'name': 'Marcus Bailey',
      'handle': '@marcuscrafts',
      'category': 'Individual Member',
      'isBusiness': false,
      'avatar': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showStatusUpdateComposer() {
    final statusController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KivoDarkTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.campaign, color: Color(0xFFFFD700), size: 24),
                    SizedBox(width: 10),
                    Text('Post Status / Broadcast Update', style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Share a 24-hour status update or broadcast to all your customers & contacts.',
              style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: statusController,
              maxLines: 3,
              style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'What\'s happening? Share product arrivals, store discounts, or updates...',
                filled: true,
                fillColor: KivoDarkTheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: KivoDarkTheme.surfaceBorder)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: KivoDarkTheme.primaryEmerald),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera photo attached to status.')));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.photo_library, color: KivoDarkTheme.accentCyan),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Media selected for status.')));
                  },
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    if (statusController.text.trim().isEmpty) return;
                    setState(() {
                      _statusStories.insert(1, {
                        'name': 'My Status',
                        'handle': '@hixroy',
                        'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
                        'isMyStatus': true,
                        'caption': statusController.text.trim(),
                        'time': 'Just now',
                      });
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: KivoDarkTheme.surfaceElevated,
                        content: Text('Status & Broadcast update posted successfully!', style: TextStyle(color: KivoDarkTheme.primaryEmerald, fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send, color: Colors.black, size: 16),
                  label: const Text('POST UPDATE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KivoDarkTheme.primaryEmerald,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDirectorySearchModal() {
    String modalSearch = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KivoDarkTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final results = _directoryContacts.where((c) {
            final q = modalSearch.toLowerCase();
            return (c['name'] as String).toLowerCase().contains(q) ||
                (c['handle'] as String).toLowerCase().contains(q) ||
                (c['category'] as String).toLowerCase().contains(q);
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Start New Conversation', style: TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (val) => setModalState(() => modalSearch = val),
                  autofocus: true,
                  style: const TextStyle(color: KivoDarkTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Search businesses, merchants & individuals...',
                    prefixIcon: Icon(Icons.search, color: KivoDarkTheme.primaryEmerald),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const Divider(color: KivoDarkTheme.surfaceBorder, height: 1),
                    itemBuilder: (context, i) {
                      final item = results[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(item['avatar']),
                              radius: 22,
                            ),
                            if (item['isBusiness'] == true)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: KivoDarkTheme.primaryEmerald, shape: BoxShape.circle),
                                  child: const Icon(Icons.store, color: Colors.black, size: 10),
                                ),
                              ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Text(item['name'], style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                            if (item['isBusiness'] == true) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, color: KivoDarkTheme.primaryEmerald, size: 14),
                            ],
                          ],
                        ),
                        subtitle: Text('${item['handle']} • ${item['category']}', style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11)),
                        trailing: const Icon(Icons.chat_bubble_outline, color: KivoDarkTheme.primaryEmerald, size: 20),
                        onTap: () {
                          Navigator.pop(ctx);
                          // Start or open chat
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatDetailScreen(
                                contactName: item['name'],
                                isOnline: true,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _viewStatus(Map<String, dynamic> status) {
    if (status['isMyStatus'] == true) {
      _showStatusUpdateComposer();
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: KivoDarkTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: KivoDarkTheme.primaryEmerald.withOpacity(0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(status['avatar']),
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(status['name'], style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(status['time'], style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: KivoDarkTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  status['caption'],
                  style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 14, height: 1.4),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              contactName: status['name'],
                              isOnline: true,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.reply, color: Colors.black, size: 18),
                      label: const Text('Reply in Chat', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KivoDarkTheme.primaryEmerald,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KivoDarkTheme.background,
      appBar: AppBar(
        title: const Text('Messages & Social 💬'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search, color: KivoDarkTheme.primaryEmerald),
            tooltip: 'Directory Search',
            onPressed: _showDirectorySearchModal,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: KivoDarkTheme.surfaceElevated,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (action) {
              if (action == 'new_chat') {
                _showDirectorySearchModal();
              } else if (action == 'status_update') {
                _showStatusUpdateComposer();
              } else if (action == 'mark_read') {
                setState(() {
                  for (var chat in _chats) {
                    chat['unread'] = 0;
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All messages marked as read.')),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new_chat',
                child: Row(
                  children: [
                    Icon(Icons.add_comment_outlined, color: KivoDarkTheme.accentCyan, size: 18),
                    SizedBox(width: 10),
                    Text('New Conversation', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'status_update',
                child: Row(
                  children: [
                    Icon(Icons.campaign_outlined, color: Color(0xFFFFD700), size: 18),
                    SizedBox(width: 10),
                    Text('Post Status / Broadcast', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'mark_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all, color: KivoDarkTheme.primaryEmerald, size: 18),
                    SizedBox(width: 10),
                    Text('Mark All as Read', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: KivoDarkTheme.primaryEmerald,
          labelColor: KivoDarkTheme.primaryEmerald,
          unselectedLabelColor: KivoDarkTheme.textSecondary,
          tabs: const [
            Tab(text: 'Chats 💬'),
            Tab(text: 'Social Feed & Status 📱'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Clean Chats Tab
          _buildChatsTab(),

          // 2. Embedded Social Feed & Status Tab
          const SocialFeedScreen(isEmbedded: true),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showDirectorySearchModal,
        backgroundColor: KivoDarkTheme.primaryEmerald,
        child: const Icon(Icons.message, color: Colors.black),
      ),
    );
  }

  Widget _buildChatsTab() {
    final filtered = _chats.where((c) {
      final nameMatches = (c['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      final handleMatches = (c['handle'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatches || handleMatches;
    }).toList();

    return Column(
      children: [
        // 1. Search Bar for Active Chats & Directory Trigger
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(color: KivoDarkTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search active chats or tap icon to find users...',
              prefixIcon: const Icon(Icons.search, color: KivoDarkTheme.textSecondary),
              suffixIcon: IconButton(
                icon: const Icon(Icons.person_add_alt_1, color: KivoDarkTheme.primaryEmerald),
                onPressed: _showDirectorySearchModal,
              ),
            ),
          ),
        ),

        // 2. Status / Broadcast Stories Carousel
        SizedBox(
          height: 105,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _statusStories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final story = _statusStories[i];
              final isMe = story['isMyStatus'] == true;

              return GestureDetector(
                onTap: () => _viewStatus(story),
                child: SizedBox(
                  width: 72,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isMe
                                  ? const LinearGradient(colors: [Colors.white24, Colors.white10])
                                  : const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFF00E676)]),
                            ),
                            child: CircleAvatar(
                              radius: 26,
                              backgroundImage: CachedNetworkImageProvider(story['avatar']),
                            ),
                          ),
                          if (isMe)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: KivoDarkTheme.primaryEmerald,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add, color: Colors.black, size: 14),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        story['name'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: KivoDarkTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const Divider(color: KivoDarkTheme.surfaceBorder, height: 1),

        // 3. Active Conversation Threads List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.white24),
                      const SizedBox(height: 12),
                      const Text('No conversations found', style: TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 14)),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _showDirectorySearchModal,
                        icon: const Icon(Icons.search, size: 16, color: Colors.black),
                        label: const Text('Find Businesses & Individuals', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KivoDarkTheme.primaryEmerald,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(color: KivoDarkTheme.surfaceBorder, height: 1),
                  itemBuilder: (context, index) {
                    final chat = filtered[index];
                    final isMoney = chat['type'] == 'MONEY_TRANSFER';
                    final isBiz = chat['isBusiness'] == true;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: CachedNetworkImageProvider(chat['avatar']),
                          ),
                          if (chat['isOnline'] == true)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: KivoDarkTheme.primaryEmerald,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: KivoDarkTheme.surfaceElevated, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Row(
                        children: [
                          Text(chat['name'], style: const TextStyle(color: KivoDarkTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                          if (isBiz) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: KivoDarkTheme.primaryEmerald, size: 14),
                          ],
                          const Spacer(),
                          Text(chat['time'], style: const TextStyle(color: KivoDarkTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                chat['lastMessage'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isMoney ? KivoDarkTheme.primaryEmerald : KivoDarkTheme.textSecondary,
                                  fontSize: 13,
                                  fontWeight: chat['unread'] > 0 ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (chat['unread'] > 0)
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: KivoDarkTheme.primaryEmerald,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${chat['unread']}',
                                  style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              contactName: chat['name'],
                              isOnline: chat['isOnline'] == true,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
