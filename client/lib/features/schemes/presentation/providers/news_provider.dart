import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/news_model.dart';
import '../../data/repository/news_repository.dart';

final newsRepositoryProvider = Provider<NewsRepository>(
  (_) => NewsRepository(),
);

final newsProvider = FutureProvider<List<NewsModel>>((ref) async {
  return ref.read(newsRepositoryProvider).getNews();
});
