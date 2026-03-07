import '../advisory_repository_contract.dart';
import '../entities/recommendation.dart';

/// Use case: get crop advisory recommendations.
/// Delegates to the repository contract.
class GetRecommendationUseCase {
  final IAdvisoryRepository _repository;

  GetRecommendationUseCase(this._repository);

  Future<List<Recommendation>> execute({
    required String crop,
    required int daysSinceSowing,
    required double latitude,
    required double longitude,
    required String soilN,
    required String soilP,
    required String soilK,
    required String soilMoisture,
    required bool pestReported,
  }) {
    return _repository.getRecommendation(
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
  }
}
