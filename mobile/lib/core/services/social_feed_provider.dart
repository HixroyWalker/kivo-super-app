import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import 'wallet_provider.dart';

class SocialFeedProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<PostModel> _posts = [];
  bool _isLoading = false;
  final Set<String> _blockedUserIds = {};

  List<PostModel> get posts => _posts.where((p) => !_blockedUserIds.contains(p.authorId)).toList();
  bool get isLoading => _isLoading;

  SocialFeedProvider() {
    _initializeFeed();
  }

  void _initializeFeed() {
    _isLoading = true;
    notifyListeners();

    _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) {
        _posts = _generateDefaultSeedPosts();
      } else {
        _posts = snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
      }
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      debugPrint('Firestore feed error: $error. Falling back to local feed cache.');
      if (_posts.isEmpty) {
        _posts = _generateDefaultSeedPosts();
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  List<PostModel> _generateDefaultSeedPosts() {
    return [
      PostModel(
        id: 'seed_1',
        authorId: 'kivo_official',
        authorName: 'Kivo Jamaica Official',
        authorHandle: '@kivoja',
        authorPhoto: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        isVerified: true,
        caption: 'Kivo Super App Showcase & Tutorial 🇯🇲 Tap play to watch inline!',
        postType: PostType.youtube,
        youtubeVideoId: 'Iv7OdQMNzz0', // User requested test YouTube link
        likeCount: 42,
        commentCount: 8,
        tipCountJMD: 0.0,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      PostModel(
        id: 'seed_2',
        authorId: 'chef_keisha',
        authorName: 'Keisha Kingston Bakes',
        authorHandle: '@keishabakes',
        authorPhoto: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
        isVerified: false,
        caption: 'Fresh batch of Jamaican rum cakes ready for delivery in New Kingston! Order directly via Kivo Marketplace. 🍰✨',
        postType: PostType.image,
        imageUrls: [
          'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=800',
        ],
        likeCount: 189,
        commentCount: 24,
        tipCountJMD: 500.0,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      PostModel(
        id: 'seed_3',
        authorId: 'dancehall_vibes',
        authorName: 'Kingston Sound Sessions',
        authorHandle: '@soundsessions',
        authorPhoto: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        isVerified: true,
        caption: 'Live acoustic session recorded in Blue Mountains. Tap play and enjoy the soundscape 🎸⛰️',
        postType: PostType.youtube,
        youtubeVideoId: 'M7lc1UVf-VE',
        likeCount: 512,
        commentCount: 68,
        tipCountJMD: 2500.0,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  /// Create a new post (Photo, YouTube, or Text)
  Future<void> createPost({
    required String caption,
    String? imageUrl,
    String? youtubeVideoId,
  }) async {
    final user = _auth.currentUser;
    final authorId = user?.uid ?? 'guest_user';
    final authorName = user?.displayName ?? 'Kivo Creator';
    final authorPhoto = user?.photoURL ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150';
    final authorHandle = '@${authorName.toLowerCase().replaceAll(' ', '')}';

    PostType type = PostType.textOnly;
    List<String> images = [];
    if (youtubeVideoId != null && youtubeVideoId.isNotEmpty) {
      type = PostType.youtube;
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      type = PostType.image;
      images = [imageUrl];
    }

    final newPost = PostModel(
      id: 'p_${DateTime.now().millisecondsSinceEpoch}',
      authorId: authorId,
      authorName: authorName,
      authorHandle: authorHandle,
      authorPhoto: authorPhoto,
      caption: caption,
      postType: type,
      imageUrls: images,
      youtubeVideoId: youtubeVideoId,
      createdAt: DateTime.now(),
    );

    // Optimistic UI update
    _posts.insert(0, newPost);
    notifyListeners();

    try {
      await _firestore.collection('posts').doc(newPost.id).set(newPost.toMap());
    } catch (e) {
      debugPrint('Error saving post to Firestore: $e');
    }
  }

  /// Toggle Like with Double-Tap Support
  Future<void> toggleLike(String postId) async {
    final userId = _auth.currentUser?.uid ?? 'anonymous_user';
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];
    final hasLiked = post.likedBy.contains(userId);
    final newLikedBy = List<String>.from(post.likedBy);
    int newLikeCount = post.likeCount;

    if (hasLiked) {
      newLikedBy.remove(userId);
      newLikeCount = (newLikeCount > 0) ? newLikeCount - 1 : 0;
    } else {
      newLikedBy.add(userId);
      newLikeCount += 1;
    }

    _posts[index] = PostModel(
      id: post.id,
      authorId: post.authorId,
      authorName: post.authorName,
      authorHandle: post.authorHandle,
      authorPhoto: post.authorPhoto,
      isVerified: post.isVerified,
      caption: post.caption,
      postType: post.postType,
      imageUrls: post.imageUrls,
      youtubeVideoId: post.youtubeVideoId,
      likeCount: newLikeCount,
      commentCount: post.commentCount,
      tipCountJMD: post.tipCountJMD,
      likedBy: newLikedBy,
      createdAt: post.createdAt,
    );
    notifyListeners();

    try {
      await _firestore.collection('posts').doc(postId).update({
        'likeCount': hasLiked ? FieldValue.increment(-1) : FieldValue.increment(1),
        'likedBy': hasLiked ? FieldValue.arrayRemove([userId]) : FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      debugPrint('Error syncing like: $e');
    }
  }

  /// Send In-Feed P2P Tip to Creator
  Future<bool> tipCreator({
    required String postId,
    required double amountJMD,
    required WalletProvider walletProvider,
  }) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return false;

    final post = _posts[index];
    final success = await walletProvider.transferFunds(
      recipientIdentifier: post.authorHandle,
      amount: amountJMD,
      note: 'Tip for post: "${post.caption.length > 25 ? post.caption.substring(0, 25) + '...' : post.caption}"',
    );

    if (success) {
      _posts[index] = PostModel(
        id: post.id,
        authorId: post.authorId,
        authorName: post.authorName,
        authorHandle: post.authorHandle,
        authorPhoto: post.authorPhoto,
        isVerified: post.isVerified,
        caption: post.caption,
        postType: post.postType,
        imageUrls: post.imageUrls,
        youtubeVideoId: post.youtubeVideoId,
        likeCount: post.likeCount,
        commentCount: post.commentCount,
        tipCountJMD: post.tipCountJMD + amountJMD,
        likedBy: post.likedBy,
        createdAt: post.createdAt,
      );
      notifyListeners();

      try {
        await _firestore.collection('posts').doc(postId).update({
          'tipCountJMD': FieldValue.increment(amountJMD),
        });
      } catch (e) {
        debugPrint('Error recording tip: $e');
      }
      return true;
    }
    return false;
  }

  /// UGC Compliance: Block User
  void blockUser(String userId) {
    _blockedUserIds.add(userId);
    notifyListeners();
  }

  /// UGC Compliance: Report Post
  Future<void> reportPost(String postId, String reason) async {
    try {
      await _firestore.collection('reports').add({
        'postId': postId,
        'reportedBy': _auth.currentUser?.uid ?? 'anonymous',
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error reporting post: $e');
    }
  }

  /// Static Helper: Extract YouTube ID from text
  static String? extractYouTubeId(String text) {
    final RegExp regExp = RegExp(
      r'(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
      multiLine: false,
    );
    final match = regExp.firstMatch(text);
    return match?.group(1);
  }
}
