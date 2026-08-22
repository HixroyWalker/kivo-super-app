import 'package:flutter/foundation.dart';

class CommunityModel {
  final String id;
  final String name;
  final String description;
  final String avatarUrl;
  final String bannerUrl;
  final List<String> groupIds;
  final List<String> adminIds;
  final int memberCount;

  CommunityModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.avatarUrl,
    this.bannerUrl = '',
    this.groupIds = const [],
    this.adminIds = const [],
    this.memberCount = 0,
  });

  factory CommunityModel.fromMap(Map<String, dynamic> map, String docId) {
    return CommunityModel(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      bannerUrl: map['bannerUrl'] ?? '',
      groupIds: List<String>.from(map['groupIds'] ?? []),
      adminIds: List<String>.from(map['adminIds'] ?? []),
      memberCount: map['memberCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'avatarUrl': avatarUrl,
      'bannerUrl': bannerUrl,
      'groupIds': groupIds,
      'adminIds': adminIds,
      'memberCount': memberCount,
    };
  }
}
