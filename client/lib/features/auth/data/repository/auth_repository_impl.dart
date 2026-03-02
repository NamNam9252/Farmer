import 'package:dio/dio.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repository_contract.dart';
import '../api/auth_api.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApi _authApi;
  final SecureStorageService _secureStorageService;

  AuthRepositoryImpl(this._authApi, this._secureStorageService);

  @override
  Future<User> login({required String phone, required String password}) async {
    try {
      final response = await _authApi.login({
        'phone': phone,
        'password': password,
      });

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      if (!apiResponse.success) {
        throw AppError(message: apiResponse.message, type: AppErrorType.server);
      }

      final data = apiResponse.data!;
      final token = data['token'] as String;
      final userModel = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      await _secureStorageService.saveToken(token);
      return userModel;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<User> signup({
    required String name,
    required String phone,
    required String password,
    required UserRole role,
    String? email,
  }) async {
    try {
      final response = await _authApi.signup({
        'name': name,
        'phone': phone,
        'password': password,
        'role': UserModel.roleToString(role),
        if (email != null && email.isNotEmpty) 'email': email,
      });

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      if (!apiResponse.success) {
        throw AppError(message: apiResponse.message, type: AppErrorType.server);
      }

      final data = apiResponse.data!;
      final token = data['token'] as String;
      final userModel = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      await _secureStorageService.saveToken(token);
      return userModel;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> logout() async {
    await _secureStorageService.deleteAll();
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _secureStorageService.getToken();
    return token != null && token.isNotEmpty;
  }

  AppError _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      String message = 'Server Error';
      if (data is Map<String, dynamic> && data['message'] != null) {
        message = data['message'];
      }
      if (e.response?.statusCode == 401) {
        return AppError(message: message, type: AppErrorType.unauthorized, originalError: e);
      }
      return AppError(message: message, type: AppErrorType.server, originalError: e);
    }
    return AppError(message: 'Network connection failed', type: AppErrorType.network, originalError: e);
  }
}
