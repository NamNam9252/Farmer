import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'location_service.dart';

/// Provider to manage and cache the user's location state.
final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});

class LocationState {
  final bool isLoading;
  final LocationResult? position;
  final String? error;

  LocationState({
    this.isLoading = false,
    this.position,
    this.error,
  });

  LocationState copyWith({
    bool? isLoading,
    LocationResult? position,
    String? error,
  }) {
    return LocationState(
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      error: error,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(LocationState());

  /// Fetches the current location and updates the state.
  /// If [force] is false and we already have a position, it won't block the UI.
  Future<void> refreshLocation({bool force = false}) async {
    if (state.position != null && !force) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await LocationService.getCurrentLocation();
      state = state.copyWith(isLoading: false, position: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      // Fallback to default if no position exists
      if (state.position == null) {
        state = state.copyWith(
          position: LocationResult(
            latitude: 26.8347,
            longitude: 75.6510,
            state: 'Rajasthan',
            district: 'Jaipur',
            pincode: '302001',
          ),
        );
      }
    }
  }
}
