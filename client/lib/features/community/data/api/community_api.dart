import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/community_model.dart';

/// Handles HTTP requests to the community endpoints.
class CommunityApi {
  final ApiClient _client = ApiClient.instance;

  Dio get dio => _client.dio;

  /// GET /community/nearby?lat=&lng=&radius=
  Future<List<CommunityModel>> getNearbyCommunities({
    required double latitude,
    required double longitude,
    double radius = 50,
  }) async {
    try {
      final response = await _client.dio.get(
        '${AppConstants.communityEndpoint}/nearby',
        queryParameters: {
          'lat': latitude,
          'lng': longitude,
          'radius': radius,
        },
      );

      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        if (body['success'] == true) {
          final list = body['data'] as List;
          return list
              .map((e) => CommunityModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        throw CommunityApiException(
            body['message'] as String? ?? 'Failed to load communities');
      }
      throw CommunityApiException('Server error: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw CommunityApiException('Connection timed out.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw CommunityApiException('No internet connection.');
      }
      throw CommunityApiException(e.message ?? 'Network error');
    }
  }

  /// GET /community/:id
  Future<CommunityModel> getCommunityDetails(String id) async {
    try {
      final response = await _client.dio.get(
        '${AppConstants.communityEndpoint}/$id',
      );

      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        if (body['success'] == true) {
          return CommunityModel.fromJson(body['data'] as Map<String, dynamic>);
        }
        throw CommunityApiException(
            body['message'] as String? ?? 'Community not found');
      }
      throw CommunityApiException('Server error: ${response.statusCode}');
    } on DioException catch (e) {
      throw CommunityApiException(e.message ?? 'Network error');
    }
  }

  /// POST /community/:id/join
  Future<Map<String, dynamic>> joinCommunity(String id) async {
    try {
      final response = await _client.dio.post(
        '${AppConstants.communityEndpoint}/$id/join',
      );

      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        if (body['success'] == true) {
          return body['data'] as Map<String, dynamic>;
        }
        throw CommunityApiException(
            body['message'] as String? ?? 'Failed to join');
      }
      throw CommunityApiException('Server error: ${response.statusCode}');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?;
      throw CommunityApiException(msg ?? e.message ?? 'Network error');
    }
  }

  /// POST /community/:id/leave
  Future<void> leaveCommunity(String id) async {
    try {
      final response = await _client.dio.post(
        '${AppConstants.communityEndpoint}/$id/leave',
      );

      if (response.statusCode == 200) return;
      throw CommunityApiException('Server error: ${response.statusCode}');
    } on DioException catch (e) {
      throw CommunityApiException(e.message ?? 'Network error');
    }
  }

  /// GET /community/:id/members
  Future<List<CommunityMemberModel>> getMembers(String id) async {
    try {
      final response = await _client.dio.get(
        '${AppConstants.communityEndpoint}/$id/members',
      );

      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        if (body['success'] == true) {
          final list = body['data'] as List;
          return list
              .map((e) =>
                  CommunityMemberModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        throw CommunityApiException('Failed to load members');
      }
      throw CommunityApiException('Server error: ${response.statusCode}');
    } on DioException catch (e) {
      throw CommunityApiException(e.message ?? 'Network error');
    }
  }

  /// POST /community (create a new community)
  Future<CommunityModel> createCommunity({
    required String name,
    String? description,
    String? type,
    bool isPrivate = false,
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    try {
      final response = await _client.dio.post(
        AppConstants.communityEndpoint,
        data: {
          'name': name,
          if (description != null) 'description': description,
          if (type != null) 'type': type,
          'isPrivate': isPrivate,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (radiusKm != null) 'radiusKm': radiusKm,
        },
      );

      if (response.statusCode == 201) {
        final body = response.data as Map<String, dynamic>;
        if (body['success'] == true) {
          return CommunityModel.fromJson(body['data'] as Map<String, dynamic>);
        }
        throw CommunityApiException(
            body['message'] as String? ?? 'Failed to create');
      }
      throw CommunityApiException('Server error: ${response.statusCode}');
    } on DioException catch (e) {
      throw CommunityApiException(e.message ?? 'Network error');
    }
  }

  /// GET /community/:id/requests
  Future<List<Map<String, dynamic>>> getJoinRequests(String communityId) async {
    try {
      final response = await _client.dio.get(
        '${AppConstants.communityEndpoint}/$communityId/requests',
      );

      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        if (body['success'] == true) {
          return List<Map<String, dynamic>>.from(body['data'] as List);
        }
        throw CommunityApiException(body['message'] as String? ?? 'Failed to load requests');
      }
      throw CommunityApiException('Server error: ${response.statusCode}');
    } on DioException catch (e) {
      throw CommunityApiException(e.message ?? 'Network error');
    }
  }

  /// POST /community/:id/requests/:requestId/approve
  Future<void> approveJoinRequest(String communityId, String requestId) async {
    try {
      final response = await _client.dio.post(
        '${AppConstants.communityEndpoint}/$communityId/requests/$requestId/approve',
      );

      if (response.statusCode == 200) return;
      throw CommunityApiException('Server error: ${response.statusCode}');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?;
      throw CommunityApiException(msg ?? e.message ?? 'Network error');
    }
  }

  /// POST /community/:id/requests/:requestId/reject
  Future<void> rejectJoinRequest(String communityId, String requestId) async {
    try {
      final response = await _client.dio.post(
        '${AppConstants.communityEndpoint}/$communityId/requests/$requestId/reject',
      );

      if (response.statusCode == 200) return;
      throw CommunityApiException('Server error: ${response.statusCode}');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?;
      throw CommunityApiException(msg ?? e.message ?? 'Network error');
    }
  }
}

class CommunityApiException implements Exception {
  final String message;
  CommunityApiException(this.message);

  @override
  String toString() => message;
}
