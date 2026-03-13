import 'dart:io';
import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/constants/app_constants.dart';

class DiseaseApiService {
  final ApiClient _client = ApiClient.instance;

  Future<Map<String, dynamic>> analyzeImage({
    required File imageFile,
    String cropType = 'general',
    String language = 'en',
  }) async {
    try {
      final response = await _client.postMultipart(
        AppConstants.analyzeEndpoint,
        imageFile,
        fields: {
          'cropType': cropType,
          'language': language,
        },
      );

      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        if (body['success'] == true) {
          return body['data'] as Map<String, dynamic>;
        }
        throw Exception(body['message'] as String? ?? 'Analysis failed');
      }
      throw Exception('Server error: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timed out. Check your internet.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('No internet connection.');
      }
      throw Exception(e.message ?? 'Network error');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
