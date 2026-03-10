import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/marketplace_new_models.dart';

class MarketplaceNewApi {
  final Dio _dio = ApiClient.instance.dio;

  // Items
  Future<List<MarketplaceItem>> getItems({
    String? category,
    String? location,
    double? minPrice,
    double? maxPrice,
  }) async {
    final response = await _dio.get(
      '${AppConstants.marketplaceNewEndpoint}/items',
      queryParameters: {
        if (category != null) 'category': category,
        if (location != null) 'location': location,
        if (minPrice != null) 'minPrice': minPrice.toString(),
        if (maxPrice != null) 'maxPrice': maxPrice.toString(),
      },
    );
    final List data = response.data['data'];
    return data.map((e) => MarketplaceItem.fromJson(e)).toList();
  }

  Future<List<MarketplaceItem>> getUserItems(String userId) async {
    final response = await _dio.get('${AppConstants.marketplaceNewEndpoint}/items/user/$userId');
    final List data = response.data['data'];
    return data.map((e) => MarketplaceItem.fromJson(e)).toList();
  }

  Future<MarketplaceItem> createItem(Map<String, dynamic> data) async {
    final response = await _dio.post('${AppConstants.marketplaceNewEndpoint}/items', data: data);
    return MarketplaceItem.fromJson(response.data['data']);
  }

  Future<MarketplaceItem> updateItem(String itemId, Map<String, dynamic> data) async {
    final response = await _dio.put('${AppConstants.marketplaceNewEndpoint}/items/$itemId', data: data);
    return MarketplaceItem.fromJson(response.data['data']);
  }

  Future<void> deleteItem(String itemId) async {
    await _dio.delete('${AppConstants.marketplaceNewEndpoint}/items/$itemId');
  }

  // Demands
  Future<List<MarketplaceDemand>> getDemands({String? category}) async {
    final response = await _dio.get(
      '${AppConstants.marketplaceNewEndpoint}/demands',
      queryParameters: {
        if (category != null) 'category': category,
      },
    );
    final List data = response.data['data'];
    return data.map((e) => MarketplaceDemand.fromJson(e)).toList();
  }

  Future<List<MarketplaceDemand>> getUserDemands(String userId) async {
    final response = await _dio.get('${AppConstants.marketplaceNewEndpoint}/demands/user/$userId');
    final List data = response.data['data'];
    return data.map((e) => MarketplaceDemand.fromJson(e)).toList();
  }

  Future<MarketplaceDemand> createDemand(Map<String, dynamic> data) async {
    final response = await _dio.post('${AppConstants.marketplaceNewEndpoint}/demands', data: data);
    return MarketplaceDemand.fromJson(response.data['data']);
  }

  Future<MarketplaceDemand> updateDemand(String demandId, Map<String, dynamic> data) async {
    final response = await _dio.put('${AppConstants.marketplaceNewEndpoint}/demands/$demandId', data: data);
    return MarketplaceDemand.fromJson(response.data['data']);
  }

  Future<void> deleteDemand(String demandId) async {
    await _dio.delete('${AppConstants.marketplaceNewEndpoint}/demands/$demandId');
  }

  // Purchase Requests
  Future<PurchaseRequest> sendPurchaseRequest(Map<String, dynamic> data) async {
    final response = await _dio.post('${AppConstants.marketplaceNewEndpoint}/purchase-requests', data: data);
    return PurchaseRequest.fromJson(response.data['data']);
  }

  Future<List<PurchaseRequest>> getSellerRequests() async {
    final response = await _dio.get('${AppConstants.marketplaceNewEndpoint}/purchase-requests/seller');
    final List data = response.data['data'];
    return data.map((e) => PurchaseRequest.fromJson(e)).toList();
  }

  Future<List<PurchaseRequest>> getBuyerRequests() async {
    final response = await _dio.get('${AppConstants.marketplaceNewEndpoint}/purchase-requests/buyer');
    final List data = response.data['data'];
    return data.map((e) => PurchaseRequest.fromJson(e)).toList();
  }

  Future<PurchaseRequest> acceptPurchaseRequest(String requestId) async {
    final response = await _dio.put('${AppConstants.marketplaceNewEndpoint}/purchase-requests/$requestId/accept');
    return PurchaseRequest.fromJson(response.data['data']);
  }

  Future<PurchaseRequest> rejectPurchaseRequest(String requestId) async {
    final response = await _dio.put('${AppConstants.marketplaceNewEndpoint}/purchase-requests/$requestId/reject');
    return PurchaseRequest.fromJson(response.data['data']);
  }

  // Demand Offers
  Future<DemandOffer> sendDemandOffer(Map<String, dynamic> data) async {
    final response = await _dio.post('${AppConstants.marketplaceNewEndpoint}/demand-offers', data: data);
    return DemandOffer.fromJson(response.data['data']);
  }

  Future<List<DemandOffer>> getBuyerOffers() async {
    final response = await _dio.get('${AppConstants.marketplaceNewEndpoint}/demand-offers/buyer');
    final List data = response.data['data'];
    return data.map((e) => DemandOffer.fromJson(e)).toList();
  }

  Future<List<DemandOffer>> getSellerOffers() async {
    final response = await _dio.get('${AppConstants.marketplaceNewEndpoint}/demand-offers/seller');
    final List data = response.data['data'];
    return data.map((e) => DemandOffer.fromJson(e)).toList();
  }

  Future<DemandOffer> acceptDemandOffer(String offerId) async {
    final response = await _dio.put('${AppConstants.marketplaceNewEndpoint}/demand-offers/$offerId/accept');
    return DemandOffer.fromJson(response.data['data']);
  }

  Future<DemandOffer> rejectDemandOffer(String offerId) async {
    final response = await _dio.put('${AppConstants.marketplaceNewEndpoint}/demand-offers/$offerId/reject');
    return DemandOffer.fromJson(response.data['data']);
  }

  // Reporting
  Future<void> reportItem(String itemId, String reason, String description) async {
    await _dio.post(
      '${AppConstants.marketplaceNewEndpoint}/items/$itemId/report',
      data: {'reason': reason, 'description': description},
    );
  }

  Future<void> reportDemand(String demandId, String reason, String description) async {
    await _dio.post(
      '${AppConstants.marketplaceNewEndpoint}/demands/$demandId/report',
      data: {'reason': reason, 'description': description},
    );
  }
}
