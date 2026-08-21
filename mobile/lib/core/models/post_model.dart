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

    return PostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Kivo User',
      authorHandle: data['authorHandle'] ?? '@kivouser',
      authorPhoto: data['authorPhoto'] ?? '',
      isVerified: data['isVerified'] ?? false,
      caption: data['caption'] ?? '',
      postType: type,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      youtubeVideoId: data['youtubeVideoId'],
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      tipCountJMD: (data['tipCountJMD'] ?? 0).toDouble(),
      likedBy: List<String>.from(data['likedBy'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
