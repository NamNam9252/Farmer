class MarketPrice {
  final String commodity;
  final String market;
  final String date;
  final double averagePrice;
  final double lowestPrice;
  final double highestPrice;
  final String unit;

  const MarketPrice({
    required this.commodity,
    required this.market,
    required this.date,
    required this.averagePrice,
    required this.lowestPrice,
    required this.highestPrice,
    required this.unit,
  });
}

