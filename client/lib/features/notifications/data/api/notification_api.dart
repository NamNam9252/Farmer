import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationApi {
  final ApiClient _client = ApiClient.instance;

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _client.dio.get('/notifications');
      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        final list = body['data'] as List;
        return list.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to load notifications');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _client.dio.patch('/notifications/$id/read');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }
}
