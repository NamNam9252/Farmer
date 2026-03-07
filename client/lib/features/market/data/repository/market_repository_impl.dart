import '../../domain/entities/market_price.dart';
import '../../domain/repository_contract.dart';
import '../api/market_api.dart';

class MarketRepositoryImpl implements MarketRepository {
  MarketRepositoryImpl(this._api);

  final MarketApi _api;

  @override
  Future<List<String>> getCommodities() {
    return _api.getCommodities();
  }

  @override
  Future<List<String>> getMarkets() {
    return _api.getMarkets();
  }

  @override
  Future<List<MarketPrice>> getPrices({
    required String commodity,
    required String market,
    required String date,
  }) {
    return _api.getPrices(
      commodity: commodity,
      market: market,
      date: date,
    );
  }
}

