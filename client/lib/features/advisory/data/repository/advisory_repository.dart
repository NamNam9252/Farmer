import '../../domain/advisory_repository_contract.dart';
import '../../domain/entities/recommendation.dart';
import '../api/advisory_api.dart';

/// Concrete repository implementation that connects the API to the domain.
class AdvisoryRepository implements IAdvisoryRepository {
  final AdvisoryApi _api = AdvisoryApi();

  @override
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
  }) async {
    final models = await _api.getRecommendation(
      crop: crop,
      daysSinceSowing: daysSinceSowing,
      latitude: latitude,
      longitude: longitude,
      soilN: soilN,
      soilP: soilP,
      soilK: soilK,
      soilMoisture: soilMoisture,
      pestReported: pestReported,
    );
    return models.map((m) => m.toEntity()).toList();
  }
}
