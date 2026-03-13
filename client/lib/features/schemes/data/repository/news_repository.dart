import '../api/news_api.dart';
import '../models/news_model.dart';

class NewsRepository {
  final NewsApi _api = NewsApi();

  Future<List<NewsModel>> getNews() async {
    return _api.getNews();
  }
}
