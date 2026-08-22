import 'package:flutter/foundation.dart';

class ChannelModel {
  final String id;
  final String name;
  final String description;
  final String avatarUrl;
  final String ownerId;
  final int subscriberCount;
  final bool isVerified;

  ChannelModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.avatarUrl,
    required this.ownerId,
    this.subscriberCount = 0,
    this.isVerified = false,
  });

  factory ChannelModel.fromMap(Map<String, dynamic> map, String docId) {
    return ChannelModel(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      ownerId: map['ownerId'] ?? '',
      subscriberCount: map['subscriberCount'] ?? 0,
      isVerified: map['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'avatarUrl': avatarUrl,
      'ownerId': ownerId,
      'subscriberCount': subscriberCount,
      'isVerified': isVerified,
    };
  }
}
