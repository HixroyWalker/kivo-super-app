import 'package:cloud_firestore/cloud_firestore.dart';

enum PostType { image, youtube, textOnly }

class PostComment {
  final String id;
  final String authorId;
  final String authorName;
  final String authorPhoto;
  final String text;
  final DateTime createdAt;

  PostComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorPhoto,
    required this.text,
    required this.createdAt,
  });

  factory PostComment.fromMap(String id, Map<String, dynamic> data) {
    return PostComment(
      id: id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Anonymous',
      authorPhoto: data['authorPhoto'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorPhoto': authorPhoto,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorHandle;
  final String authorPhoto;
  final bool isVerified;
  final String caption;
  final PostType postType;
  final List<String> imageUrls;
  final String? youtubeVideoId;
  final int likeCount;
  final int commentCount;
  final double tipCountJMD;
  final List<String> likedBy;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorHandle,
    required this.authorPhoto,
    this.isVerified = false,
    required this.caption,
    required this.postType,
    this.imageUrls = const [],
    this.youtubeVideoId,
    this.likeCount = 0,
    this.commentCount = 0,
    this.tipCountJMD = 0.0,
    this.likedBy = const [],
    required this.createdAt,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    PostType type = PostType.textOnly;
    final typeStr = data['postType'] as String? ?? 'textOnly';
    if (typeStr == 'image') {
      type = PostType.image;
    } else if (typeStr == 'youtube') {
      type = PostType.youtube;
    }

    DateTime parsedDate = DateTime.now();
    final rawDate = data['createdAt'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    }

    double parsedTips = 0.0;
    final rawTips = data['tipCountJMD'];
    if (rawTips is num) {
      parsedTips = rawTips.toDouble();
    } else if (rawTips is String) {
      parsedTips = double.tryParse(rawTips) ?? 0.0;
    }

    int parsedLikes = 0;
    final rawLikes = data['likeCount'];
    if (rawLikes is num) {
      parsedLikes = rawLikes.toInt();
    } else if (rawLikes is String) {
      parsedLikes = int.tryParse(rawLikes) ?? 0;
    }

    int parsedComments = 0;
    final rawComments = data['commentCount'];
    if (rawComments is num) {
      parsedComments = rawComments.toInt();
    } else if (rawComments is String) {
      parsedComments = int.tryParse(rawComments) ?? 0;
    }

    List<String> parsedImages = [];
    if (data['imageUrls'] is List) {
      parsedImages = (data['imageUrls'] as List)
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }

    List<String> parsedLikedBy = [];
    if (data['likedBy'] is List) {
      parsedLikedBy = (data['likedBy'] as List)
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return PostModel(
      id: doc.id,
      authorId: data['authorId']?.toString() ?? 'kivo_user',
      authorName: data['authorName']?.toString() ?? 'Kivo User',
      authorHandle: data['authorHandle']?.toString() ?? '@kivouser',
      authorPhoto: (data['authorPhoto'] != null && data['authorPhoto'].toString().isNotEmpty)
          ? data['authorPhoto'].toString()
          : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      isVerified: data['isVerified'] == true,
      caption: data['caption']?.toString() ?? '',
      postType: type,
      imageUrls: parsedImages,
      youtubeVideoId: data['youtubeVideoId']?.toString(),
      likeCount: parsedLikes,
      commentCount: parsedComments,
      tipCountJMD: parsedTips,
      likedBy: parsedLikedBy,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorHandle': authorHandle,
      'authorPhoto': authorPhoto,
      'isVerified': isVerified,
      'caption': caption,
      'postType': postType.name,
      'imageUrls': imageUrls,
      'youtubeVideoId': youtubeVideoId,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'tipCountJMD': tipCountJMD,
      'likedBy': likedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
