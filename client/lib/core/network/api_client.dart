import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../services/secure_storage_service.dart';

class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            await _secureStorage.deleteToken();
            // Auth provider will handle routing redirect if we listen to the storage or state
          }
          handler.next(e);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();
  late final Dio _dio;
  final SecureStorageService _secureStorage = SecureStorageService();

  Dio get dio => _dio;

  Future<Response> postMultipart(
    String path,
    File imageFile, {
    Map<String, dynamic>? fields,
  }) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'crop_image.jpg',
      ),
      if (fields != null) ...fields,
    });

    return _dio.post(path, data: formData);
  }
}
