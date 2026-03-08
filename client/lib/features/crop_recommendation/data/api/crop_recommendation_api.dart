import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_error.dart';
import '../../domain/entities/crop_recommendation.dart';

class CropRecommendationApi {
  final ApiClient _client = ApiClient.instance;

  Future<CropRecommendationReport> getRecommendation({
    required double latitude,
    required double longitude,
    String? soilType,
    List<String>? preferredCrops,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'latitude': latitude,
        'longitude': longitude,
      };
      
      if (soilType != null && soilType.isNotEmpty) {
        data['soil_type'] = soilType;
      }
      
      if (preferredCrops != null && preferredCrops.isNotEmpty) {
        data['preferred_crops'] = preferredCrops;
      }

      final response = await _client.dio.post(
        AppConstants.cropRecommendationEndpoint,
        data: data,
        // The endpoint uses Groq AI, which can take ~10-15s, overriding default 30s timeout to 60s
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );

      final apiResponse = ApiResponse<CropRecommendationReport>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => CropRecommendationReport.fromJson(data as Map<String, dynamic>),
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw AppError(
          message: apiResponse.message,
          type: AppErrorType.server,
        );
      }

      return apiResponse.data!;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AppError(
        message: e.toString(),
        type: AppErrorType.unknown,
        originalError: e,
      );
    }
  }

  AppError _handleDioError(DioException e) {
    String message = 'Network error';
    AppErrorType type = AppErrorType.network;

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      message = 'AI Analysis took too long. Please try again.';
      type = AppErrorType.network;
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'Unable to connect to server. Please check your internet.';
      type = AppErrorType.network;
    } else if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic> && data['message'] is String) {
        message = data['message'] as String;
      } else {
        message = 'Server error: \${e.response!.statusCode}';
      }
    }

    return AppError(
      message: message,
      type: type,
      originalError: e,
    );
  }
}
