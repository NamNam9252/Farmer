import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/recommendation_model.dart';

/// Handles the HTTP request to the advisory recommendation endpoint.
class AdvisoryApi {
  final ApiClient _client = ApiClient.instance;

  Future<List<RecommendationModel>> getRecommendation({
    required String crop,
    required int daysSinceSowing,
    required double latitude,
    required double longitude,
    required String soilN,
    required String soilP,
    required String soilK,
    required String soilMoisture,
    required bool pestReported,
  }) async {
    try {
      final response = await _client.dio.post(
        AppConstants.advisoryEndpoint,
        data: {
          'crop': crop,
          'days_since_sowing': daysSinceSowing,
          'latitude': latitude,
          'longitude': longitude,
          'soil_n': soilN,
          'soil_p': soilP,
          'soil_k': soilK,
          'soil_moisture': soilMoisture,
          'pest_reported': pestReported,
        },
      );

      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        if (body['success'] == true) {
          final list = body['data'] as List;
          return list
              .map((e) =>
                  RecommendationModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        throw AdvisoryApiException(
            body['message'] as String? ?? 'Advisory failed');
      }
      throw AdvisoryApiException('Server error: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw AdvisoryApiException('Connection timed out. Check your internet.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw AdvisoryApiException('No internet connection.');
      }
      throw AdvisoryApiException(e.message ?? 'Network error');
    }
  }
}

class AdvisoryApiException implements Exception {
  final String message;
  AdvisoryApiException(this.message);

  @override
  String toString() => message;
}
