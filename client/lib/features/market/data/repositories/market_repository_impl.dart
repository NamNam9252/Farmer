import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/market_price_model.dart';
import '../../domain/entities/market_price.dart';
import '../../domain/repositories/market_repository.dart';

class MarketRepository implements IMarketRepository {
  final ApiClient _apiClient = ApiClient.instance;

  @override
  Future<MandiPriceResult> getMandiPrices({
    String? commodity,
    String? state,
    String? district,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        AppConstants.mandiPricesEndpoint,
        queryParameters: {
          if (commodity != null && commodity.isNotEmpty) 'commodity': commodity,
          if (state != null && state.isNotEmpty) 'state': state,
          if (district != null && district.isNotEmpty) 'district': district,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final List<dynamic> rawRecords = data['records'] ?? [];
      final records = rawRecords
          .map((json) => MarketPriceModel.fromMandiJson(json as Map<String, dynamic>))
          .toList();

      final suggestions = data['suggestions'] as Map<String, dynamic>? ?? {};
      final nearestMarkets = (suggestions['nearestMarkets'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final otherCrops = (suggestions['otherCropsInArea'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      return MandiPriceResult(
        records: records,
        searchStage: data['searchStage'] as String? ?? 'unknown',
        message: data['message'] as String? ?? '',
        totalResults: data['totalResults'] as int? ?? records.length,
        nearestMarkets: nearestMarkets,
        otherCropsInArea: otherCrops,
      );
    } catch (e) {
      throw Exception('Error fetching mandi prices: $e');
    }
  }

  @override
  Future<List<String>> getStates() async {
    try {
      final response = await _apiClient.dio.get(AppConstants.marketStatesEndpoint);
      if (response.data['success'] == true) {
        return List<String>.from(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch states');
      }
    } catch (e) {
      throw Exception('Error fetching states: $e');
    }
  }

  @override
  Future<List<String>> getDistricts(String state) async {
    try {
      final response = await _apiClient.dio.get(
        AppConstants.marketDistrictsEndpoint,
        queryParameters: {'state': state},
      );
      if (response.data['success'] == true) {
        return List<String>.from(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch districts');
      }
    } catch (e) {
      throw Exception('Error fetching districts: $e');
    }
  }

  // ── Legacy methods ──

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
