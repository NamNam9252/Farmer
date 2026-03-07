import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/market_price.dart';
import '../../domain/repositories/market_repository.dart';
import '../../data/repositories/market_repository_impl.dart';

final marketRepositoryProvider = Provider<IMarketRepository>(
  (_) => MarketRepository(),
);

class MarketState {
  final List<MarketPrice> prices;
  final List<String> availableCommodities;
  final List<String> availableMarkets;
  final bool isLoading;
  final String? error;
  final String selectedCommodity;
  final String selectedMarket;
  final String selectedDate;

  MarketState({
    this.prices = const [],
    this.availableCommodities = const [],
    this.availableMarkets = const [],
    this.isLoading = false,
    this.error,
    this.selectedCommodity = 'Wheat',
    this.selectedMarket = 'Delhi',
    this.selectedDate = '',
  });

  MarketState copyWith({
    List<MarketPrice>? prices,
    List<String>? availableCommodities,
    List<String>? availableMarkets,
    bool? isLoading,
    String? error,
    String? selectedCommodity,
    String? selectedMarket,
    String? selectedDate,
  }) {
    return MarketState(
      prices: prices ?? this.prices,
      availableCommodities: availableCommodities ?? this.availableCommodities,
      availableMarkets: availableMarkets ?? this.availableMarkets,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCommodity: selectedCommodity ?? this.selectedCommodity,
      selectedMarket: selectedMarket ?? this.selectedMarket,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

class MarketNotifier extends StateNotifier<MarketState> {
  final IMarketRepository _repository;

  MarketNotifier(this._repository) : super(MarketState(
    selectedDate: "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}"
  )) {
    _initialize();
  }

  Future<void> _initialize() async {
    await fetchFilterOptions();
    await fetchPrices();
  }

  Future<void> fetchFilterOptions() async {
    try {
      final commodities = await _repository.getCommodities();
      final markets = await _repository.getMarkets();
      state = state.copyWith(
        availableCommodities: commodities,
        availableMarkets: markets,
      );
    } catch (e) {
      // Silent error or handle as needed
    }
  }

  Future<void> fetchPrices() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prices = await _repository.getMarketPrices(
        commodity: state.selectedCommodity,
        market: state.selectedMarket,
        date: state.selectedDate,
      );
      state = state.copyWith(prices: prices, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void updateFilters({String? commodity, String? market, String? date}) {
    state = state.copyWith(
      selectedCommodity: commodity,
      selectedMarket: market,
      selectedDate: date,
    );
    fetchPrices();
  }
}

final marketProvider = StateNotifierProvider<MarketNotifier, MarketState>((ref) {
  final repo = ref.watch(marketRepositoryProvider);
  return MarketNotifier(repo);
});
