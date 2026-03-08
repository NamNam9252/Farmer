import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repository/community_repository.dart';
import '../../domain/entities/community.dart';
import '../../data/api/community_api.dart';

/// Sealed state for the community list screen.
class CommunityListState {
  final bool isLoading;
  final String? error;
  final List<CommunityEntity> communities;

  const CommunityListState({
    this.isLoading = false,
    this.error,
    this.communities = const [],
  });

  CommunityListState copyWith({
    bool? isLoading,
    String? error,
    List<CommunityEntity>? communities,
  }) {
    return CommunityListState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      communities: communities ?? this.communities,
    );
  }
}

/// State for a single community detail.
class CommunityDetailState {
  final bool isLoading;
  final String? error;
  final CommunityEntity? community;
  final List<CommunityMemberEntity> members;
  final bool isJoining;

  const CommunityDetailState({
    this.isLoading = false,
    this.error,
    this.community,
    this.members = const [],
    this.isJoining = false,
  });

  CommunityDetailState copyWith({
    bool? isLoading,
    String? error,
    CommunityEntity? community,
    List<CommunityMemberEntity>? members,
    bool? isJoining,
  }) {
    return CommunityDetailState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      community: community ?? this.community,
      members: members ?? this.members,
      isJoining: isJoining ?? this.isJoining,
    );
  }
}

/// Provider for the community list.
class CommunityListNotifier extends StateNotifier<CommunityListState> {
  CommunityListNotifier() : super(const CommunityListState());

  final CommunityRepository _repo = CommunityRepository();

  Future<void> loadNearby(double lat, double lng, {double radius = 50}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _repo.getNearbyCommunities(
        latitude: lat,
        longitude: lng,
        radius: radius,
      );
      state = state.copyWith(isLoading: false, communities: list);
    } on CommunityApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createCommunity({
    required String name,
    String? description,
    String? type,
    bool isPrivate = false,
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newCommunity = await _repo.createCommunity(
        name: name,
        description: description,
        type: type,
        isPrivate: isPrivate,
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      // Prepend the new community to the current list
      state = state.copyWith(
        isLoading: false,
        communities: [newCommunity, ...state.communities],
      );
    } on CommunityApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow; // So UI can catch and show snackbar
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

/// Provider for community detail.
class CommunityDetailNotifier extends StateNotifier<CommunityDetailState> {
  CommunityDetailNotifier() : super(const CommunityDetailState());

  final CommunityRepository _repo = CommunityRepository();

  Future<void> loadDetails(String id, {bool showLoading = true}) async {
    if (showLoading) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final community = await _repo.getCommunityDetails(id);
      final members = await _repo.getMembers(id);
      state = state.copyWith(
        isLoading: false,
        community: community,
        members: members,
      );
    } on CommunityApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> joinCommunity(String id) async {
    state = state.copyWith(isJoining: true);
    try {
      await _repo.joinCommunity(id);
      // Reload silently to update members list without blanking screen
      await loadDetails(id, showLoading: false);
      state = state.copyWith(isJoining: false);
    } on CommunityApiException catch (e) {
      if (e.message.toLowerCase().contains('already a member') || 
          e.message.toLowerCase().contains('already member')) {
        // Explicitly handle "already a member" as a success state fix
        await loadDetails(id, showLoading: false);
        state = state.copyWith(isJoining: false);
      } else {
        state = state.copyWith(isJoining: false, error: e.message);
      }
    } catch (e) {
      state = state.copyWith(isJoining: false, error: e.toString());
    }
  }

  Future<void> leaveCommunity(String id) async {
    state = state.copyWith(isJoining: true);
    try {
      await _repo.leaveCommunity(id);
      await loadDetails(id, showLoading: false);
      state = state.copyWith(isJoining: false);
    } on CommunityApiException catch (e) {
      state = state.copyWith(isJoining: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isJoining: false, error: e.toString());
    }
  }

  Future<void> approveJoinRequest(String communityId, String requestId) async {
    try {
      await _repo.approveJoinRequest(communityId, requestId);
      await loadDetails(communityId, showLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> rejectJoinRequest(String communityId, String requestId) async {
    try {
      await _repo.rejectJoinRequest(communityId, requestId);
      await loadDetails(communityId, showLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final communityListProvider =
    StateNotifierProvider<CommunityListNotifier, CommunityListState>(
  (ref) => CommunityListNotifier(),
);

final communityDetailProvider =
    StateNotifierProvider<CommunityDetailNotifier, CommunityDetailState>(
  (ref) => CommunityDetailNotifier(),
);
