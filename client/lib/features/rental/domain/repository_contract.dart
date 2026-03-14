import '../data/models/rental_models.dart';

abstract class IRentalRepository {
  Future<List<RentalAsset>> getAssets();
  Future<RentalAsset> getAsset(String id);
  Future<RentalAsset> createAsset(Map<String, dynamic> data);
  Future<RentalAsset> updateAsset(String id, Map<String, dynamic> data);
  Future<void> deleteAsset(String id);
  Future<List<RentalAsset>> getMyAssets();
  
  Future<List<RentalBid>> getAssetBids(String assetId);
  Future<RentalBid> placeBid(String assetId, Map<String, dynamic> data);
  Future<void> acceptBid(String assetId, String bidId);
  Future<void> withdrawBid(String bidId);
  Future<List<RentalBid>> getMyBids();
  
  Future<List<RentalOrder>> getMyRentals();
}
