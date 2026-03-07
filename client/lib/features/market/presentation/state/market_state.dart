import '../../domain/entities/market_price.dart';

class MarketState {
  final bool isLoading;
  final List<String> commodities;
  final List<String> markets;
  final String? selectedCommodity;
  final String? selectedMarket;
  final DateTime selectedDate;
  final List<MarketPrice> prices;
  final String? error;

  const MarketState({
    this.isLoading = false,
    this.commodities = const [],
    this.markets = const [],
    this.selectedCommodity,
    this.selectedMarket,
    required this.selectedDate,
    this.prices = const [],
    this.error,
  });

  factory MarketState.initial() {
    final today = DateTime.now();
    return MarketState(selectedDate: DateTime(today.year, today.month, today.day));
  }

  MarketState copyWith({
    bool? isLoading,
    List<String>? commodities,
    List<String>? markets,
    String? selectedCommodity,
    String? selectedMarket,
    DateTime? selectedDate,
    List<MarketPrice>? prices,
    String? error,
    bool clearError = false,
  }) {
    return MarketState(
      isLoading: isLoading ?? this.isLoading,
      commodities: commodities ?? this.commodities,
      markets: markets ?? this.markets,
      selectedCommodity: selectedCommodity ?? this.selectedCommodity,
      selectedMarket: selectedMarket ?? this.selectedMarket,
      selectedDate: selectedDate ?? this.selectedDate,
      prices: prices ?? this.prices,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

