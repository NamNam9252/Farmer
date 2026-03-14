import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class LaborApi {
  final ApiClient _apiClient = ApiClient.instance;

  Future<Response> getProfile() async {
    return await _apiClient.dio.get('/labor/profile');
  }

  Future<Response> updateProfile(Map<String, dynamic> data) async {
    print('--- LABOR API UPDATE PROFILE CALLED ---');
    print('Sending data: $data');
    return await _apiClient.dio.put('/labor/profile', data: data);
  }

  Future<Response> createProfile(Map<String, dynamic> data) async {
    return await _apiClient.dio.post('/labor/profile', data: data);
  }

  Future<Response> listAvailable(String? districtId) async {
    return await _apiClient.dio.get('/labor/available', queryParameters: {
      if (districtId != null) 'districtId': districtId,
    });
  }

  Future<Response> hireLabor(String laborId, Map<String, dynamic> data) async {
    return await _apiClient.dio.post('/labor/$laborId/hire', data: data);
  }

  Future<Response> requestBooking(String laborId, Map<String, dynamic> data) async {
    return await _apiClient.dio.post('/labor/$laborId/bookings', data: data);
  }

  Future<Response> getBookingRequests() async {
    return await _apiClient.dio.get('/labor/bookings/requests');
  }

  Future<Response> respondToBookingRequest(
    String bookingId,
    String action, {
    String? cancelReason,
  }) async {
    return await _apiClient.dio.post(
      '/labor/bookings/$bookingId/respond',
      data: {
        'action': action,
        if (cancelReason != null && cancelReason.trim().isNotEmpty)
          'cancelReason': cancelReason,
      },
    );
  }

  Future<Response> getMyEmployments() async {
    return await _apiClient.dio.get('/labor/my-employments');
  }

  Future<Response> getFarmerLabor() async {
    return await _apiClient.dio.get('/labor/farmer/labor');
  }
}
