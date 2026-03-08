import '../api/community_api.dart';
import '../../domain/entities/community.dart';

/// Repository that wraps CommunityApi and converts models → entities.
class CommunityRepository {
  final CommunityApi _api = CommunityApi();

  Future<List<CommunityEntity>> getNearbyCommunities({
    required double latitude,
    required double longitude,
    double radius = 50,
  }) async {
    final models = await _api.getNearbyCommunities(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );
    return models.map((m) => m.toEntity()).toList();
  }

  Future<CommunityEntity> getCommunityDetails(String id) async {
    final model = await _api.getCommunityDetails(id);
    return model.toEntity();
  }

  Future<Map<String, dynamic>> joinCommunity(String id) async {
    return _api.joinCommunity(id);
  }

  Future<void> leaveCommunity(String id) async {
    return _api.leaveCommunity(id);
  }

  Future<List<CommunityMemberEntity>> getMembers(String id) async {
    final models = await _api.getMembers(id);
    return models.map((m) => m.toEntity()).toList();
  }

  Future<CommunityEntity> createCommunity({
    required String name,
    String? description,
    String? type,
    bool isPrivate = false,
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    final model = await _api.createCommunity(
      name: name,
      description: description,
      type: type,
      isPrivate: isPrivate,
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
    return model.toEntity();
  }

  Future<List<Map<String, dynamic>>> getJoinRequests(String id) async {
    return _api.getJoinRequests(id);
  }

  Future<void> approveJoinRequest(String communityId, String requestId) async {
    return _api.approveJoinRequest(communityId, requestId);
  }

  Future<void> rejectJoinRequest(String communityId, String requestId) async {
    return _api.rejectJoinRequest(communityId, requestId);
  }

  Future<void> deleteCommunity(String id) async {
    return _api.deleteCommunity(id);
  }
}
