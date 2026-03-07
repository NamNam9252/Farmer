import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/market_api.dart';
import '../../data/repository/market_repository_impl.dart';
import '../../domain/usecases/market_usecases.dart';
import '../state/market_state.dart';

final marketRepositoryProvider = Provider<MarketRepositoryImpl>(
  (_) => MarketRepositoryImpl(MarketApi()),
);

final fetchCommoditiesUseCaseProvider = Provider<FetchCommoditiesUseCase>(
  (ref) => FetchCommoditiesUseCase(ref.watch(marketRepositoryProvider)),
);

final fetchMarketsUseCaseProvider = Provider<FetchMarketsUseCase>(
  (ref) => FetchMarketsUseCase(ref.watch(marketRepositoryProvider)),
);

final fetchMarketPricesUseCaseProvider = Provider<FetchMarketPricesUseCase>(
  (ref) => FetchMarketPricesUseCase(ref.watch(marketRepositoryProvider)),
);

class MarketNotifier extends StateNotifier<MarketState> {
  MarketNotifier(
    this._fetchCommodities,
    this._fetchMarkets,
    this._fetchPrices,
  ) : super(MarketState.initial()) {
    _init();
  }

  final FetchCommoditiesUseCase _fetchCommodities;
  final FetchMarketsUseCase _fetchMarkets;
  final FetchMarketPricesUseCase _fetchPrices;

  Future<void> _init() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _fetchCommodities.execute(),
        _fetchMarkets.execute(),
      ]);

      final commodities = results[0] as List<String>;
      final markets = results[1] as List<String>;

      state = state.copyWith(
        isLoading: false,
        commodities: commodities,
        markets: markets,
        selectedCommodity:
            state.selectedCommodity ?? (commodities.isNotEmpty ? commodities.first : null),
        selectedMarket:
            state.selectedMarket ?? (markets.isNotEmpty ? markets.first : null),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void selectCommodity(String value) {
    state = state.copyWith(selectedCommodity: value, clearError: true);
  }

  void selectMarket(String value) {
    state = state.copyWith(selectedMarket: value, clearError: true);
  }

  void selectDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    state = state.copyWith(selectedDate: normalized, clearError: true);
  }

  Future<void> fetchPrices() async {
    final commodity = state.selectedCommodity;
    final market = state.selectedMarket;

    if (commodity == null || market == null) {
      state = state.copyWith(
        error: 'Please select commodity and market.',
      );
      return;
    }

    final dateStr =
        '${state.selectedDate.year.toString().padLeft(4, '0')}-'
        '${state.selectedDate.month.toString().padLeft(2, '0')}-'
        '${state.selectedDate.day.toString().padLeft(2, '0')}';

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final prices = await _fetchPrices.execute(
        commodity: commodity,
        market: market,
        date: dateStr,
      );
      state = state.copyWith(isLoading: false, prices: prices);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final marketProvider = StateNotifierProvider<MarketNotifier, MarketState>(
  (ref) => MarketNotifier(
    ref.watch(fetchCommoditiesUseCaseProvider),
    ref.watch(fetchMarketsUseCaseProvider),
    ref.watch(fetchMarketPricesUseCaseProvider),
  ),
);

