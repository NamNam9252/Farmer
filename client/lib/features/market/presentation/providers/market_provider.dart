import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/market_price.dart';
import '../../domain/repositories/market_repository.dart';
import '../../data/repositories/market_repository_impl.dart';

final marketRepositoryProvider = Provider<IMarketRepository>(
  (_) => MarketRepository(),
);

class MarketState {
  final List<MarketPrice> prices;
  final List<MarketPrice> filteredPrices; // filtered by category chip
  final List<String> availableCommodities;
  final List<String> availableStates;
  final List<String> availableDistricts;
  final bool isLoading;
  final String? error;
  final String selectedCommodity;
  final String selectedState;
  final String selectedDistrict;
  final String searchStage;
  final String message;
  final List<String> suggestedCrops;
  final List<String> nearestMarkets;
  final String? activeCategoryFilter; // which chip is active

  MarketState({
    this.prices = const [],
    this.filteredPrices = const [],
    this.availableCommodities = const [],
    this.availableStates = const [],
    this.availableDistricts = const [],
    this.isLoading = false,
    this.error,
    this.selectedCommodity = '',
    this.selectedState = 'Rajasthan',
    this.selectedDistrict = '',
    this.searchStage = '',
    this.message = '',
    this.suggestedCrops = const [],
    this.nearestMarkets = const [],
    this.activeCategoryFilter,
  });

  MarketState copyWith({
    List<MarketPrice>? prices,
    List<MarketPrice>? filteredPrices,
    List<String>? availableCommodities,
    List<String>? availableStates,
    List<String>? availableDistricts,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? selectedCommodity,
    String? selectedState,
    String? selectedDistrict,
    String? searchStage,
    String? message,
    List<String>? suggestedCrops,
    List<String>? nearestMarkets,
    String? activeCategoryFilter,
    bool clearCategoryFilter = false,
  }) {
    return MarketState(
      prices: prices ?? this.prices,
      filteredPrices: filteredPrices ?? this.filteredPrices,
      availableCommodities: availableCommodities ?? this.availableCommodities,
      availableStates: availableStates ?? this.availableStates,
      availableDistricts: availableDistricts ?? this.availableDistricts,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedCommodity: selectedCommodity ?? this.selectedCommodity,
      selectedState: selectedState ?? this.selectedState,
      selectedDistrict: selectedDistrict ?? this.selectedDistrict,
      searchStage: searchStage ?? this.searchStage,
      message: message ?? this.message,
      suggestedCrops: suggestedCrops ?? this.suggestedCrops,
      nearestMarkets: nearestMarkets ?? this.nearestMarkets,
      activeCategoryFilter:
          clearCategoryFilter ? null : (activeCategoryFilter ?? this.activeCategoryFilter),
    );
  }

  /// Unique commodity categories from current results (for chips)
  List<String> get categories {
    final seen = <String>{};
    for (final p in prices) {
      if (p.commodity.isNotEmpty) seen.add(p.commodity);
    }
    return seen.toList()..sort();
  }
}

class MarketNotifier extends StateNotifier<MarketState> {
  final IMarketRepository _repository;

  MarketNotifier(this._repository) : super(MarketState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadStates();
    await _loadCommodities();
    await fetchPrices();
  }

  Future<void> _loadStates() async {
    try {
      final states = await _repository.getStates();
      state = state.copyWith(availableStates: states);
    } catch (_) {}
  }

  Future<void> _loadCommodities() async {
    try {
      final commodities = await _repository.getCommodities();
      state = state.copyWith(availableCommodities: commodities);
    } catch (_) {}
  }

  Future<void> loadDistricts(String stateName) async {
    try {
      final districts = await _repository.getDistricts(stateName);
      state = state.copyWith(
        availableDistricts: districts,
        selectedDistrict: '',
      );
    } catch (_) {
      state = state.copyWith(availableDistricts: []);
    }
  }

  Future<void> fetchPrices() async {
    // Need at least one filter
    if (state.selectedCommodity.isEmpty &&
        state.selectedState.isEmpty &&
        state.selectedDistrict.isEmpty) {
      // Default: just fetch by state
      if (state.selectedState.isEmpty) return;
    }

    state = state.copyWith(isLoading: true, clearError: true, clearCategoryFilter: true);

    try {
      final result = await _repository.getMandiPrices(
        commodity: state.selectedCommodity.isEmpty ? null : state.selectedCommodity,
        state: state.selectedState.isEmpty ? null : state.selectedState,
        district: state.selectedDistrict.isEmpty ? null : state.selectedDistrict,
      );

      state = state.copyWith(
        prices: result.records,
        filteredPrices: result.records,
        isLoading: false,
        searchStage: result.searchStage,
        message: result.message,
        suggestedCrops: result.otherCropsInArea,
        nearestMarkets: result.nearestMarkets,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void updateState(String newState) {
    state = state.copyWith(
      selectedState: newState,
      selectedDistrict: '',
      availableDistricts: [],
    );
    loadDistricts(newState);
    fetchPrices();
  }

  void updateDistrict(String district) {
    state = state.copyWith(selectedDistrict: district);
    fetchPrices();
  }

  void updateCommodity(String commodity) {
    state = state.copyWith(selectedCommodity: commodity);
    fetchPrices();
  }

  void clearCommodity() {
    state = state.copyWith(selectedCommodity: '');
    fetchPrices();
  }

  void filterByCategory(String? category) {
    if (category == null || category == state.activeCategoryFilter) {
      // Toggle off
      state = state.copyWith(
        filteredPrices: state.prices,
        clearCategoryFilter: true,
      );
    } else {
      final filtered = state.prices.where((p) => p.commodity == category).toList();
      state = state.copyWith(
        filteredPrices: filtered,
        activeCategoryFilter: category,
      );
    }
  }
}

final marketProvider = StateNotifierProvider<MarketNotifier, MarketState>((ref) {
  final repo = ref.watch(marketRepositoryProvider);
  return MarketNotifier(repo);
});
