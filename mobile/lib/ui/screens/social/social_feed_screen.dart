import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/post_model.dart';
import '../../../core/services/social_feed_provider.dart';
import '../../../core/services/wallet_provider.dart';
import '../../widgets/sandboxed_video_player.dart';
import 'create_post_screen.dart';

class SocialFeedScreen extends StatelessWidget {
  final bool isEmbedded;
  const SocialFeedScreen({Key? key, this.isEmbedded = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.watch<SocialFeedProvider>();
    final posts = feedProvider.posts;

    Widget content;
    if (posts.isEmpty && feedProvider.isLoading) {
      content = const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFD700)),
      );
    } else if (posts.isEmpty) {
      content = _buildEmptyState(context);
    } else {
      content = RefreshIndicator(
        color: const Color(0xFFFFD700),
        onRefresh: () async {
          // Pull to refresh
        },
        child: ListView.builder(
          padding: EdgeInsets.only(top: isEmbedded ? 8 : 0, bottom: 80),
          itemCount: posts.length + (isEmbedded ? 1 : 0),
          itemBuilder: (context, index) {
            if (isEmbedded && index == 0) {
              return _buildEmbeddedHeader(context);
            }
            final postIndex = isEmbedded ? index - 1 : index;
            final post = posts[postIndex];
            return _PostCard(post: post);
          },
        ),
      );
    }

    if (isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101726),
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'Kivo Feed',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Color(0xFFFFD700),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '🇯🇲 Jamaica',
                style: TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePostScreen()),
              );
            },
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildEmbeddedHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161F30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF223048)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFFFD700),
            child: Icon(Icons.person, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePostScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E17),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Share an update, photo, or YouTube link...',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_photo_alternate, color: Color(0xFFFFD700), size: 22),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreatePostScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.dynamic_feed, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text(
            'No posts yet',
            style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Be the first to share photos or YouTube videos!',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePostScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create First Post'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
          )
        ],
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  final PostModel post;
  const _PostCard({Key? key, required this.post}) : super(key: key);

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> with SingleTickerProviderStateMixin {
  bool _showHeartOverlay = false;

  void _handleDoubleTap() {
    context.read<SocialFeedProvider>().toggleLike(widget.post.id);
    setState(() => _showHeartOverlay = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showHeartOverlay = false);
    });
  }

  void _showTippingModal(BuildContext context) {
    final walletProvider = context.read<WalletProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141E33),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(widget.post.authorPhoto),
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tip ${widget.post.authorName}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        widget.post.authorHandle,
                        style: const TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Send an instant wallet tip to support this creator:',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [50.0, 100.0, 500.0].map((amount) {
                  return ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final success = await context.read<SocialFeedProvider>().tipCreator(
                        postId: widget.post.id,
                        amountJMD: amount,
                        walletProvider: walletProvider,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: success ? const Color(0xFF00C853) : Colors.redAccent,
                            content: Text(
                              success
                                  ? 'Tipped \$${amount.toStringAsFixed(0)} JMD to ${widget.post.authorName}! 🇯🇲'
                                  : 'Tip failed. Please check your wallet balance.',
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('\$${amount.toStringAsFixed(0)} JMD', style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showUgcMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141E33),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.amber),
                title: const Text('Report Post', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<SocialFeedProvider>().reportPost(widget.post.id, 'Inappropriate Content');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thank you. This post has been reported for review.')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.redAccent),
                title: const Text('Block User', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<SocialFeedProvider>().blockUser(widget.post.authorId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Blocked @${widget.post.authorHandle}. You will no longer see their posts.')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF101726),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Handle, 3-dots Menu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: CachedNetworkImageProvider(post.authorPhoto),
                  backgroundColor: Colors.white10,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.authorName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (post.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: Color(0xFFFFD700), size: 14),
                          ]
                        ],
                      ),
                      Text(
                        post.authorHandle,
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
                  onPressed: () => _showUgcMenu(context),
                )
              ],
            ),
          ),

          // Media Content: YouTube Sandboxed Video OR Image OR Text Only
          if (post.postType == PostType.youtube && post.youtubeVideoId != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SandboxedVideoPlayer(videoId: post.youtubeVideoId!),
            ),
          ] else if (post.postType == PostType.image && post.imageUrls.isNotEmpty) ...[
            GestureDetector(
              onDoubleTap: _handleDoubleTap,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CachedNetworkImage(
                    imageUrl: post.imageUrls.first,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 300,
                      color: Colors.black26,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD700)),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 250,
                      color: Colors.white10,
                      child: const Icon(Icons.broken_image, color: Colors.white24, size: 48),
                    ),
                  ),
                  if (_showHeartOverlay)
                    const Icon(
                      Icons.favorite,
                      color: Color(0xFFFFD700),
                      size: 90,
                    ),
                ],
              ),
            ),
          ],

          // Action Toolbar: Like, Comment, Tip $ JMD
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    post.likedBy.contains(context.read<WalletProvider>().userEmail)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: post.likedBy.contains(context.read<WalletProvider>().userEmail)
                        ? Colors.redAccent
                        : Colors.white70,
                    size: 26,
                  ),
                  onPressed: () => context.read<SocialFeedProvider>().toggleLike(post.id),
                ),
                Text(
                  '${post.likeCount}',
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.chat_bubble_outline, color: Colors.white70, size: 24),
                const SizedBox(width: 6),
                Text(
                  '${post.commentCount}',
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),

                // In-Feed Tipping Badge & Button
                ElevatedButton.icon(
                  onPressed: () => _showTippingModal(context),
                  icon: const Icon(Icons.payments, size: 16, color: Colors.black),
                  label: Text(
                    post.tipCountJMD > 0 ? 'Tip (\$${post.tipCountJMD.toStringAsFixed(0)})' : 'Tip Creator',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),

          // Caption & Timestamp
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${post.authorName} ',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      TextSpan(
                        text: post.caption,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatTimeAgo(post.createdAt),
                  style: const TextStyle(color: Colors.white24, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
