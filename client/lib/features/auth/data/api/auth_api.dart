import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class AuthApi {
  final ApiClient _apiClient = ApiClient.instance;

  Future<Response> login(Map<String, dynamic> data) async {
    return await _apiClient.dio.post('/auth/login', data: data);
  }

  Future<Response> signup(Map<String, dynamic> data) async {
    return await _apiClient.dio.post('/auth/signup', data: data);
  }
}
