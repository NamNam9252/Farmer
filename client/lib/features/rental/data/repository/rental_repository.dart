import '../../domain/repository_contract.dart';
import '../api/rental_api.dart';
import '../models/rental_models.dart';

class RentalRepository implements IRentalRepository {
  final RentalApi _api;

  RentalRepository(this._api);

  @override
  Future<List<RentalAsset>> getAssets() => _api.getAssets();

  @override
  Future<RentalAsset> getAsset(String id) => _api.getAsset(id);

  @override
  Future<RentalAsset> createAsset(Map<String, dynamic> data) => _api.createAsset(data);

  @override
  Future<RentalAsset> updateAsset(String id, Map<String, dynamic> data) => _api.updateAsset(id, data);

  @override
  Future<void> deleteAsset(String id) => _api.deleteAsset(id);

  @override
  Future<List<RentalAsset>> getMyAssets() => _api.getMyAssets();

  @override
  Future<List<RentalBid>> getAssetBids(String assetId) => _api.getAssetBids(assetId);

  @override
  Future<RentalBid> placeBid(String assetId, Map<String, dynamic> data) => _api.placeBid(assetId, data);

  @override
  Future<void> acceptBid(String assetId, String bidId) => _api.acceptBid(assetId, bidId);

  @override
  Future<void> withdrawBid(String bidId) => _api.withdrawBid(bidId);

  @override
  Future<List<RentalBid>> getMyBids() => _api.getMyBids();

  @override
  Future<List<RentalOrder>> getMyRentals() => _api.getMyRentals();
}
