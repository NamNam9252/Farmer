import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/crop_recommendation_api.dart';
import '../state/crop_recommendation_state.dart';
import '../../../../core/services/location_service.dart';

final cropRecommendationApiProvider = Provider<CropRecommendationApi>((ref) {
  return CropRecommendationApi();
});

final cropRecommendationProvider = StateNotifierProvider<CropRecommendationNotifier, CropRecommendationState>((ref) {
  final api = ref.watch(cropRecommendationApiProvider);
  return CropRecommendationNotifier(api);
});

class CropRecommendationNotifier extends StateNotifier<CropRecommendationState> {
  final CropRecommendationApi _api;

  CropRecommendationNotifier(this._api) : super(const CropRecommendationState());

  void setSoilType(String soilType) {
    state = state.copyWith(selectedSoilType: soilType);
  }

  void togglePreferredCrop(String crop) {
    final currentList = List<String>.from(state.preferredCrops);
    if (currentList.contains(crop)) {
      currentList.remove(crop);
    } else {
      currentList.add(crop);
    }
    state = state.copyWith(preferredCrops: currentList);
  }

  void clearPreferences() {
    state = state.copyWith(selectedSoilType: '', preferredCrops: []);
  }

  Future<void> getRecommendation() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // 1. Get current location
      final locationResult = await LocationService.getCurrentLocation();
      
      // 2. Fetch recommendation
      final report = await _api.getRecommendation(
        latitude: locationResult.latitude,
        longitude: locationResult.longitude,
        soilType: state.selectedSoilType,
        preferredCrops: state.preferredCrops,
      );

      state = state.copyWith(isLoading: false, report: report);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
