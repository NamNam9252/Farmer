import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  static String get baseUrl => dotenv.get('BASE_URL', fallback: 'http://172.16.65.10:3000/api/v1');
  static const String diseaseEndpoint = '/disease';
  static const String analyzeEndpoint = '/disease/analyze';
  static const String reportsEndpoint = '/disease/reports';
  static const String marketEndpoint = '/market';
  static const String marketPricesEndpoint = '/market/prices';
  static const String marketCommoditiesEndpoint = '/market/commodities';
  static const String marketMarketsEndpoint = '/market/markets';
  static const String advisoryEndpoint = '/advisory/recommendation';
  static const String marketplaceNewEndpoint = '/marketplace';
  static const String weatherEndpoint = '/weather';
  static const String cropRecommendationEndpoint = '/crop-recommendation/recommend';
  static const String communityEndpoint = '/community';
  static const String schemesEndpoint = '/schemes';
  static const String newsEndpoint = '/news';
  static const String rentalEndpoint = '/rental';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const double imageQuality = 85;

  static const String langKey = 'selected_language';
  static const String langEnglish = 'en';
  static const String langHindi = 'hi';

  static const List<String> indianCrops = [
    'Wheat (गेहूं)',
    'Rice (धान)',
    'Cotton (कपास)',
    'Tomato (टमाटर)',
    'Potato (आलू)',
    'Onion (प्याज)',
    'Mustard (सरसों)',
    'Sugarcane (गन्ना)',
    'Maize (मक्का)',
    'Soybean (सोयाबीन)',
    'Chilli (मिर्च)',
    'Brinjal (बैंगन)',
    'Banana (केला)',
    'Mango (आम)',
    'Other (अन्य)',
  ];
}
