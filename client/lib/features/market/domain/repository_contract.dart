import 'entities/market_price.dart';

abstract class MarketRepository {
  Future<List<String>> getCommodities();

  Future<List<String>> getMarkets();

  Future<List<MarketPrice>> getPrices({
    required String commodity,
    required String market,
    required String date,
  });
}

