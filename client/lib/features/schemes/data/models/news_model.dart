class NewsModel {
  final String id;
  final String title;
  final String content;
  final String? source;
  final String? sourceUrl;
  final String? imageUrl;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final bool isNational;

  NewsModel({
    required this.id,
    required this.title,
    required this.content,
    this.source,
    this.sourceUrl,
    this.imageUrl,
    this.publishedAt,
    required this.createdAt,
    required this.isNational,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      source: json['source'],
      sourceUrl: json['sourceUrl'],
      imageUrl: json['imageUrl'],
      publishedAt:
          json['publishedAt'] != null
              ? DateTime.tryParse(json['publishedAt'])
              : null,
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
              : DateTime.now(),
      isNational: json['isNational'] ?? false,
    );
  }
}
