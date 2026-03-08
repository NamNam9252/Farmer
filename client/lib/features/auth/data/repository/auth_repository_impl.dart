import 'dart:convert';
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
      final userMap = data['user'] as Map<String, dynamic>;
      final userModel = UserModel.fromJson(userMap);

      await _secureStorageService.saveToken(token);
      await _secureStorageService.saveUser(jsonEncode(userMap));
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
    required String email,
  }) async {
    try {
      final response = await _authApi.signup({
        'name': name,
        'phone': phone,
        'password': password,
        'role': UserModel.roleToString(role),
        'email': email,
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
      final userMap = data['user'] as Map<String, dynamic>;
      final userModel = UserModel.fromJson(userMap);

      await _secureStorageService.saveToken(token);
      await _secureStorageService.saveUser(jsonEncode(userMap));
      return userModel;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> requestOtp({required String email}) async {
    try {
      final response = await _authApi.requestOtp({'email': email});
      _checkSuccess(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<User> verifyOtp({required String email, required String otp}) async {
    try {
      final response = await _authApi.verifyOtp({'email': email, 'otp': otp});

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      if (!apiResponse.success) {
        throw AppError(message: apiResponse.message, type: AppErrorType.server);
      }

      final data = apiResponse.data!;
      final token = data['token'] as String;
      final userMap = data['user'] as Map<String, dynamic>;
      final userModel = UserModel.fromJson(userMap);

      await _secureStorageService.saveToken(token);
      await _secureStorageService.saveUser(jsonEncode(userMap));
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

  @override
  Future<User?> getUser() async {
    final userJson = await _secureStorageService.getUser();
    if (userJson == null) return null;
    try {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    } catch (e) {
      return null;
    }
  }

  void _checkSuccess(Response response) {
    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data,
      (data) => data as Map<String, dynamic>? ?? {},
    );

    if (!apiResponse.success) {
      throw AppError(message: apiResponse.message, type: AppErrorType.server);
    }
  }

  AppError _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      String message = 'Server Error';
      if (data is Map<String, dynamic> && data['message'] != null) {
        message = data['message'];
      }
      if (e.response?.statusCode == 401) {
        return AppError(
          message: message,
          type: AppErrorType.unauthorized,
          originalError: e,
        );
      }
      return AppError(
        message: message,
        type: AppErrorType.server,
        originalError: e,
      );
    }
    return AppError(
      message: 'Network connection failed',
      type: AppErrorType.network,
      originalError: e,
    );
  }
}
