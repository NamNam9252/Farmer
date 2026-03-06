import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class OnboardingApi {
  final ApiClient _apiClient = ApiClient.instance;

  Future<Response> submitLocation(Map<String, dynamic> data) async {
    return await _apiClient.dio.post('/users/location', data: data);
  }

  Future<Response> submitFarmerProfile(Map<String, dynamic> data) async {
    return await _apiClient.dio.post('/users/profile/farmer', data: data);
  }

  Future<Response> submitLaborProfile(Map<String, dynamic> data) async {
    return await _apiClient.dio.post('/users/profile/labor', data: data);
  }

  Future<Response> submitExpertProfile(Map<String, dynamic> data) async {
    return await _apiClient.dio.post('/users/profile/expert', data: data);
  }
}
