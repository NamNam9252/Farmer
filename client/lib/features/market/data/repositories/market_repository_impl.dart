import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/market_price_model.dart';
import '../../domain/entities/market_price.dart';
import '../../domain/repositories/market_repository.dart';

class MarketRepository implements IMarketRepository {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<List<MarketPrice>> getMarketPrices({
    String? commodity,
    String? market,
    String? date,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        AppConstants.marketPricesEndpoint,
        queryParameters: {
          if (commodity != null) 'commodity': commodity,
          if (market != null) 'market': market,
          if (date != null) 'date': date,
        },
      );

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => MarketPriceModel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch market prices');
      }
    } catch (e) {
      throw Exception('Error fetching market prices: $e');
    }
  }

  @override
  Future<List<String>> getCommodities() async {
    try {
      final response = await _apiClient.dio.get('/market/commodities');
      if (response.data['success'] == true) {
        return List<String>.from(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch commodities');
      }
    } catch (e) {
      throw Exception('Error fetching commodities: $e');
    }
  }

  @override
  Future<List<String>> getMarkets() async {
    try {
      final response = await _apiClient.dio.get('/market/markets');
      if (response.data['success'] == true) {
        return List<String>.from(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch markets');
      }
    } catch (e) {
      throw Exception('Error fetching markets: $e');
    }
  }
}
