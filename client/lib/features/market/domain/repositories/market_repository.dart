import '../../domain/entities/market_price.dart';

abstract class IMarketRepository {
  Future<List<MarketPrice>> getMarketPrices({
    String? commodity,
    String? market,
    String? date,
  });
  Future<List<String>> getCommodities();
  Future<List<String>> getMarkets();
}
