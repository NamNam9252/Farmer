import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/chat_models.dart';

class ChatbotApi {
  final Dio _dio = ApiClient.instance.dio;

  static const String _chatEndpoint = '/agent/chat';
  static const String _confirmEndpoint = '/agent/confirm';

  Future<AgentResponse> sendMessage({
    required String message,
    List<ChatMessage> conversationHistory = const [],
    double? lat,
    double? lng,
    String? imagePath,
  }) async {
    final Map<String, dynamic> body = {
      'message': message,
      'conversationHistory': conversationHistory.map((m) => m.toApiMessage()).toList(),
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };

    dynamic requestData;

    if (imagePath != null) {
      requestData = FormData.fromMap({
        ...body,
        'image': await MultipartFile.fromFile(
          imagePath,
          filename: imagePath.split('/').last,
        ),
      });
    } else {
      requestData = body;
    }

    final response = await _dio.post(_chatEndpoint, data: requestData);

    final data = response.data['data'] as Map<String, dynamic>;
    return AgentResponse.fromJson(data);
  }

  Future<Map<String, dynamic>> confirmAction({
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _dio.post(_confirmEndpoint, data: {
      'action': action,
      'payload': payload,
    });

    return response.data['data'] as Map<String, dynamic>;
  }
}
