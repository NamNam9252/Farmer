import '../../../../core/network/api_client.dart';
import '../models/news_model.dart';

class NewsApi {
  final ApiClient _apiClient = ApiClient.instance;

  Future<List<NewsModel>> getNews() async {
    final response = await _apiClient.dio.get('/news');

    if (response.data['success'] == true) {
      final List data = response.data['data'] ?? [];
      return data
          .map((json) => NewsModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return [];
  }
}
