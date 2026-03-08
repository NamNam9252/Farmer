import '../../domain/entities/crop_recommendation.dart';

class CropRecommendationState {
  final bool isLoading;
  final String? error;
  final CropRecommendationReport? report;
  final String selectedSoilType;
  final List<String> preferredCrops;

  const CropRecommendationState({
    this.isLoading = false,
    this.error,
    this.report,
    this.selectedSoilType = '',
    this.preferredCrops = const [],
  });

  CropRecommendationState copyWith({
    bool? isLoading,
    String? error,
    CropRecommendationReport? report,
    String? selectedSoilType,
    List<String>? preferredCrops,
    bool clearError = false,
  }) {
    return CropRecommendationState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      report: report ?? this.report,
      selectedSoilType: selectedSoilType ?? this.selectedSoilType,
      preferredCrops: preferredCrops ?? this.preferredCrops,
    );
  }
}
