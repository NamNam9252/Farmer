import '../../domain/entities/market_price.dart';

class MarketPriceModel {
  final String commodity;
  final String market;
  final String date;
  final double averagePrice;
  final double lowestPrice;
  final double highestPrice;
  final String unit;

  const MarketPriceModel({
    required this.commodity,
    required this.market,
    required this.date,
    required this.averagePrice,
    required this.lowestPrice,
    required this.highestPrice,
    required this.unit,
  });

  factory MarketPriceModel.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    return MarketPriceModel(
      commodity: json['commodity']?.toString() ?? '',
      market: json['market']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      averagePrice: _toDouble(json['averagePrice']),
      lowestPrice: _toDouble(json['lowestPrice']),
      highestPrice: _toDouble(json['highestPrice']),
      unit: json['unit']?.toString() ?? 'quintal',
    );
  }

  MarketPrice toEntity() {
    return MarketPrice(
      commodity: commodity,
      market: market,
      date: date,
      averagePrice: averagePrice,
      lowestPrice: lowestPrice,
      highestPrice: highestPrice,
      unit: unit,
    );
  }
}

