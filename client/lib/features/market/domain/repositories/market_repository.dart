import '../../domain/entities/market_price.dart';

/// Mandi query result with metadata
class MandiPriceResult {
  final List<MarketPrice> records;
  final String searchStage;
  final String message;
  final int totalResults;
  final List<String> nearestMarkets;
  final List<String> otherCropsInArea;

  const MandiPriceResult({
    required this.records,
    required this.searchStage,
    required this.message,
    required this.totalResults,
    this.nearestMarkets = const [],
    this.otherCropsInArea = const [],
  });
}

abstract class IMarketRepository {
  Future<MandiPriceResult> getMandiPrices({
    String? commodity,
    String? state,
    String? district,
  });
  Future<List<String>> getCommodities();
  Future<List<String>> getStates();
  Future<List<String>> getDistricts(String state);

  // Legacy
  Future<List<MarketPrice>> getMarketPrices({
    String? commodity,
    String? market,
    String? date,
  });
  Future<List<String>> getMarkets();
}
