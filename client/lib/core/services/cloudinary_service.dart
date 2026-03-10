import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/constants/app_constants.dart';

class CloudinaryService {
  static String get cloudName => dotenv.get('CLOUDINARY_CLOUD_NAME', fallback: '');
  static String get uploadPreset => dotenv.get('CLOUDINARY_UPLOAD_PRESET', fallback: '');
  
  final Dio _dio = Dio();

  Future<String?> uploadImage(File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'upload_preset': uploadPreset,
      });

      final response = await _dio.post(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['secure_url'] as String;
      }
      return null;
    } catch (e) {
      print('Cloudinary Upload Error: $e');
      return null;
    }
  }
}
