import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/recommendation.dart';
import '../../domain/usecases/get_recommendation_usecase.dart';
import '../../domain/advisory_repository_contract.dart';
import '../../data/repository/advisory_repository.dart';
import '../../../weather/presentation/providers/weather_provider.dart';
import '../../../../core/services/language_provider.dart';

// --- Providers ---

final advisoryRepositoryProvider = Provider<IAdvisoryRepository>(
  (_) => AdvisoryRepository(),
);

final getRecommendationUseCaseProvider = Provider<GetRecommendationUseCase>(
  (ref) => GetRecommendationUseCase(ref.watch(advisoryRepositoryProvider)),
);

// --- State ---

class AdvisoryState {
  final String crop;
  final int daysSinceSowing;
  final String soilN;
  final String soilP;
  final String soilK;
  final String soilMoisture;
  final bool pestReported;
  final List<Recommendation> results;
  final bool isLoading;
  final String? error;

  const AdvisoryState({
    this.crop = 'wheat',
    this.daysSinceSowing = 15,
    this.soilN = 'medium',
    this.soilP = 'medium',
    this.soilK = 'medium',
    this.soilMoisture = 'medium',
    this.pestReported = false,
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  AdvisoryState copyWith({
    String? crop,
    int? daysSinceSowing,
    String? soilN,
    String? soilP,
    String? soilK,
    String? soilMoisture,
    bool? pestReported,
    List<Recommendation>? results,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearResults = false,
  }) {
    return AdvisoryState(
      crop: crop ?? this.crop,
      daysSinceSowing: daysSinceSowing ?? this.daysSinceSowing,
      soilN: soilN ?? this.soilN,
      soilP: soilP ?? this.soilP,
      soilK: soilK ?? this.soilK,
      soilMoisture: soilMoisture ?? this.soilMoisture,
      pestReported: pestReported ?? this.pestReported,
      results: clearResults ? [] : (results ?? this.results),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// --- Notifier ---

class AdvisoryNotifier extends StateNotifier<AdvisoryState> {
  AdvisoryNotifier(this._useCase, this._ref) : super(const AdvisoryState());

  final GetRecommendationUseCase _useCase;
  final Ref _ref;

  void setCrop(String crop) => state = state.copyWith(crop: crop);
  void setDays(int days) => state = state.copyWith(daysSinceSowing: days);
  void setSoilN(String v) => state = state.copyWith(soilN: v);
  void setSoilP(String v) => state = state.copyWith(soilP: v);
  void setSoilK(String v) => state = state.copyWith(soilK: v);
  void setSoilMoisture(String v) => state = state.copyWith(soilMoisture: v);
  void setPestReported(bool v) => state = state.copyWith(pestReported: v);

  Future<void> fetchRecommendation() async {
    state = state.copyWith(isLoading: true, clearError: true, clearResults: true);

    try {
      // Use real location from weather provider, fallback to Hapur
      final ws = _ref.read(weatherProvider);
      final lat = ws.latitude ?? 28.7307;
      final lon = ws.longitude ?? 77.7759;

      final results = await _useCase.execute(
        crop: state.crop,
        daysSinceSowing: state.daysSinceSowing,
        latitude: lat,
        longitude: lon,
        soilN: state.soilN,
        soilP: state.soilP,
        soilK: state.soilK,
        soilMoisture: state.soilMoisture,
        pestReported: state.pestReported,
        lang: _ref.read(languageProvider),
      );
      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearAll() => state = const AdvisoryState();
}

// --- Provider ---

final advisoryProvider =
    StateNotifierProvider<AdvisoryNotifier, AdvisoryState>(
  (ref) => AdvisoryNotifier(
    ref.watch(getRecommendationUseCaseProvider),
    ref,
  ),
);

