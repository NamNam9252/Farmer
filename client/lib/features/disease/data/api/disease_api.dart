import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/disease_report_model.dart';

class DiseaseApi {
  final ApiClient _client = ApiClient.instance;

  Future<DiseaseReportModel> analyzeImage({
    required File imageFile,
    required String cropType,
    String language = 'hi',
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
          return DiseaseReportModel.fromJson(
            body['data'] as Map<String, dynamic>,
          );
        }
        throw DiseaseApiException(body['message'] as String? ?? 'Analysis failed');
      }
      throw DiseaseApiException('Server error: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw DiseaseApiException('Connection timed out. Check your internet.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw DiseaseApiException('No internet connection.');
      }
      throw DiseaseApiException(e.message ?? 'Network error');
    }
  }

  Future<List<DiseaseReportModel>> getReports() async {
    try {
      final response = await _client.dio.get(AppConstants.reportsEndpoint);
      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        if (body['success'] == true) {
          final list = body['data'] as List;
          return list
              .map((e) => DiseaseReportModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}

class DiseaseApiException implements Exception {
  final String message;
  DiseaseApiException(this.message);

  @override
  String toString() => message;
}
