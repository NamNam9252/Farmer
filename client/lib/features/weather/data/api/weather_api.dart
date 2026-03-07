import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/weather_model.dart';

/// Handles the HTTP request to the weather endpoint.
class WeatherApi {
  final ApiClient _client = ApiClient.instance;

  Future<WeatherModel> getWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _client.dio.get(
        AppConstants.weatherEndpoint,
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
        },
      );

      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        if (body['success'] == true) {
          return WeatherModel.fromJson(body['data'] as Map<String, dynamic>);
        }
        throw WeatherApiException(
            body['message'] as String? ?? 'Weather fetch failed');
      }
      throw WeatherApiException('Server error: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw WeatherApiException('Connection timed out.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw WeatherApiException('No internet connection.');
      }
      throw WeatherApiException(e.message ?? 'Network error');
    }
  }
}

class WeatherApiException implements Exception {
  final String message;
  WeatherApiException(this.message);

  @override
  String toString() => message;
}
