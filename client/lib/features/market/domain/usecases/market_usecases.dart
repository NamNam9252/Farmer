import '../entities/market_price.dart';
import '../repository_contract.dart';

class FetchCommoditiesUseCase {
  final MarketRepository _repository;

  FetchCommoditiesUseCase(this._repository);

  Future<List<String>> execute() {
    return _repository.getCommodities();
  }
}

class FetchMarketsUseCase {
  final MarketRepository _repository;

  FetchMarketsUseCase(this._repository);

  Future<List<String>> execute() {
    return _repository.getMarkets();
  }
}

class FetchMarketPricesUseCase {
  final MarketRepository _repository;

  FetchMarketPricesUseCase(this._repository);

  Future<List<MarketPrice>> execute({
    required String commodity,
    required String market,
    required String date,
  }) {
    return _repository.getPrices(
      commodity: commodity,
      market: market,
      date: date,
    );
  }
}

