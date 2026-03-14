import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/rental_models.dart';

class RentalApi {
  final Dio _dio = ApiClient.instance.dio;

  // Assets
  Future<List<RentalAsset>> getAssets() async {
    final response = await _dio.get('${AppConstants.rentalEndpoint}/assets');
    final List data = response.data['data']['assets'];
    return data.map((e) => RentalAsset.fromJson(e)).toList();
  }

  Future<RentalAsset> getAsset(String id) async {
    final response = await _dio.get('${AppConstants.rentalEndpoint}/assets/$id');
    return RentalAsset.fromJson(response.data['data']);
  }

  Future<RentalAsset> createAsset(Map<String, dynamic> data) async {
    final response = await _dio.post('${AppConstants.rentalEndpoint}/assets', data: data);
    return RentalAsset.fromJson(response.data['data']);
  }

  Future<RentalAsset> updateAsset(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('${AppConstants.rentalEndpoint}/assets/$id', data: data);
    return RentalAsset.fromJson(response.data['data']);
  }

  Future<void> deleteAsset(String id) async {
    await _dio.delete('${AppConstants.rentalEndpoint}/assets/$id');
  }

  Future<List<RentalAsset>> getMyAssets() async {
    final response = await _dio.get('${AppConstants.rentalEndpoint}/me/assets');
    final List data = response.data['data'];
    return data.map((e) => RentalAsset.fromJson(e)).toList();
  }

  // Bids
  Future<List<RentalBid>> getAssetBids(String assetId) async {
    final response = await _dio.get('${AppConstants.rentalEndpoint}/assets/$assetId/bids');
    final List data = response.data['data'];
    return data.map((e) => RentalBid.fromJson(e)).toList();
  }

  Future<RentalBid> placeBid(String assetId, Map<String, dynamic> data) async {
    final response = await _dio.post('${AppConstants.rentalEndpoint}/assets/$assetId/bids', data: data);
    return RentalBid.fromJson(response.data['data']);
  }

  Future<void> acceptBid(String assetId, String bidId) async {
    await _dio.post('${AppConstants.rentalEndpoint}/assets/$assetId/bids/$bidId/accept');
  }

  Future<void> withdrawBid(String bidId) async {
    await _dio.delete('${AppConstants.rentalEndpoint}/bids/$bidId/withdraw');
  }

  Future<List<RentalBid>> getMyBids() async {
    final response = await _dio.get('${AppConstants.rentalEndpoint}/me/bids');
    final List data = response.data['data'];
    return data.map((e) => RentalBid.fromJson(e)).toList();
  }

  // Rentals
  Future<List<RentalOrder>> getMyRentals() async {
    final response = await _dio.get('${AppConstants.rentalEndpoint}/me/rentals');
    final List data = response.data['data'];
    return data.map((e) => RentalOrder.fromJson(e)).toList();
  }
}
