import 'entities/recommendation.dart';

/// Abstract contract for advisory data access.
/// Domain layer defines this; data layer implements it.
abstract class IAdvisoryRepository {
  Future<List<Recommendation>> getRecommendation({
    required String crop,
    required int daysSinceSowing,
    required double latitude,
    required double longitude,
    required String soilN,
    required String soilP,
    required String soilK,
    required String soilMoisture,
    required bool pestReported,
    required String lang,
  });
}
