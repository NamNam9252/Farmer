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
}
