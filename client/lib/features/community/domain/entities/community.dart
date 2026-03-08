/// Domain entity for a community.
class CommunityEntity {
  final String id;
  final String name;
  final String? description;
  final String type; // GENERAL, CROP_BASED, ROUND, RADIUS_BASED
  final bool isPrivate;
  final bool isPending;
  final int memberCount;
  final int postCount;
  final String? coverImageUrl;
  final String? cropName;
  final double? centerLatitude;
  final double? centerLongitude;
  final CommunityCreator? createdBy;

  const CommunityEntity({
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
}

class CommunityCreator {
  final String id;
  final String name;

  const CommunityCreator({required this.id, required this.name});
}

/// Domain entity for a community member.
class CommunityMemberEntity {
  final String id;
  final String userId;
  final String userName;
  final String? profileImageUrl;
  final String role; // ADMIN, MODERATOR, MEMBER

  const CommunityMemberEntity({
    required this.id,
    required this.userId,
    required this.userName,
    this.profileImageUrl,
    required this.role,
  });
}
