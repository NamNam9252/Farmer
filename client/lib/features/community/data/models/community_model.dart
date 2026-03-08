import '../../domain/entities/community.dart';

/// Data model for parsing community JSON from the API.
class CommunityModel {
  final String id;
  final String name;
  final String? description;
  final String type;
  final bool isPrivate;
  final bool isPending;
  final int memberCount;
  final int postCount;
  final String? coverImageUrl;
  final String? cropName;
  final double? centerLatitude;
  final double? centerLongitude;
  final Map<String, dynamic>? createdBy;

  CommunityModel({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.isPrivate,
    this.isPending = false,
    required this.memberCount,
    required this.postCount,
    this.coverImageUrl,
    this.cropName,
    this.centerLatitude,
    this.centerLongitude,
    this.createdBy,
  });

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    final count = json['_count'] as Map<String, dynamic>?;
    return CommunityModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Community',
      description: json['description']?.toString(),
      type: json['type']?.toString() ?? 'GENERAL',
      isPrivate: json['isPrivate'] as bool? ?? false,
      isPending: json['isPending'] as bool? ?? false,
      memberCount: count != null ? (count['members'] as int? ?? 0) : (json['memberCount'] as int? ?? 0),
      postCount: count != null ? (count['posts'] as int? ?? 0) : (json['postCount'] as int? ?? 0),
      coverImageUrl: json['coverImageUrl']?.toString(),
      cropName: json['cropName']?.toString(),
      centerLatitude: (json['centerLatitude'] as num?)?.toDouble(),
      centerLongitude: (json['centerLongitude'] as num?)?.toDouble(),
      createdBy: json['createdBy'] as Map<String, dynamic>?,
    );
  }

  CommunityEntity toEntity() {
    return CommunityEntity(
      id: id,
      name: name,
      description: description,
      type: type,
      isPrivate: isPrivate,
      isPending: isPending,
      memberCount: memberCount,
      postCount: postCount,
      coverImageUrl: coverImageUrl,
      cropName: cropName,
      centerLatitude: centerLatitude,
      centerLongitude: centerLongitude,
      createdBy: createdBy != null
          ? CommunityCreator(
              id: (createdBy!['_id'] ?? createdBy!['id'])?.toString() ?? '',
              name: createdBy!['name']?.toString() ?? 'Unknown',
            )
          : null,
    );
  }
}

/// Data model for community member JSON.
class CommunityMemberModel {
  final String id;
  final String role;
  final Map<String, dynamic> user;

  CommunityMemberModel({
    required this.id,
    required this.role,
    required this.user,
  });

  factory CommunityMemberModel.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] as Map<String, dynamic>? ?? {};
    return CommunityMemberModel(
      id: json['id']?.toString() ?? '',
      role: json['role']?.toString() ?? 'MEMBER',
      user: userMap,
    );
  }

  CommunityMemberEntity toEntity() {
    return CommunityMemberEntity(
      id: id,
      userId: (user['_id'] ?? user['id'])?.toString() ?? '',
      userName: user['name']?.toString() ?? 'Unknown',
      profileImageUrl: user['profileImageUrl']?.toString(),
      role: role,
    );
  }
}
