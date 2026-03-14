import '../../domain/entities/market_price.dart';

class MarketPriceModel extends MarketPrice {
  const MarketPriceModel({
    required super.commodity,
    required super.market,
    required super.date,
    required super.averagePrice,
    required super.lowestPrice,
    required super.highestPrice,
    super.unit,
    super.state,
    super.district,
    super.variety,
    super.grade,
  });

  /// Parse from the new mandi-prices API record format
  factory MarketPriceModel.fromMandiJson(Map<String, dynamic> json) {
    return MarketPriceModel(
      commodity: json['commodity'] as String? ?? '',
      market: json['market'] as String? ?? '',
      date: json['arrivalDate'] as String? ?? '',
      averagePrice: (json['modalPrice'] as num?)?.toDouble() ?? 0.0,
      lowestPrice: (json['minPrice'] as num?)?.toDouble() ?? 0.0,
      highestPrice: (json['maxPrice'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'INR/quintal',
      state: json['state'] as String? ?? '',
      district: json['district'] as String? ?? '',
      variety: json['variety'] as String? ?? '',
      grade: json['grade'] as String? ?? '',
    );
  }

  /// Legacy parser (kept for backward compat)
  factory MarketPriceModel.fromJson(Map<String, dynamic> json) {
    return MarketPriceModel(
      commodity: json['commodity'] as String? ?? '',
      market: json['market'] as String? ?? '',
      date: json['date'] as String? ?? '',
      averagePrice: (json['averagePrice'] as num?)?.toDouble() ?? 0.0,
      lowestPrice: (json['lowestPrice'] as num?)?.toDouble() ?? 0.0,
      highestPrice: (json['highestPrice'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'quintal',
    );
  }

  MarketPrice toEntity() => this;

  Map<String, dynamic> toJson() => {
        'commodity': commodity,
        'market': market,
        'date': date,
        'averagePrice': averagePrice,
        'lowestPrice': lowestPrice,
        'highestPrice': highestPrice,
        'unit': unit,
        'state': state,
        'district': district,
        'variety': variety,
        'grade': grade,
      };
}
