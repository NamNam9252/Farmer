import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/weather_api.dart';
import '../../data/models/weather_model.dart';
import '../../../../core/services/location_service.dart';

/// State for weather data — holds current weather + forecast + location info.
class WeatherState {
  final WeatherModel? weather;
  final String district;
  final String state;
  final double? latitude;
  final double? longitude;
  final bool isLoading;
  final String? error;

  const WeatherState({
    this.weather,
    this.district = '',
    this.state = '',
    this.latitude,
    this.longitude,
    this.isLoading = false,
    this.error,
  });

  WeatherState copyWith({
    WeatherModel? weather,
    String? district,
    String? state,
    double? latitude,
    double? longitude,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return WeatherState(
      weather: weather ?? this.weather,
      district: district ?? this.district,
      state: state ?? this.state,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class WeatherNotifier extends StateNotifier<WeatherState> {
  WeatherNotifier() : super(const WeatherState());

  final WeatherApi _api = WeatherApi();

  /// Fetches weather data. If coordinates are provided, skips internal GPS fetch.
  Future<void> fetchWeather({
    double? latitude,
    double? longitude,
    String? district,
    String? stateName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      double finalLat = latitude ?? 0.0;
      double finalLng = longitude ?? 0.0;

      if (latitude == null || longitude == null) {
        // Fallback to internal GPS if not provided
        final location = await LocationService.getCurrentLocation();
        finalLat = location.latitude;
        finalLng = location.longitude;

        state = state.copyWith(
          district: location.district,
          state: location.state,
          latitude: finalLat,
          longitude: finalLng,
        );
      } else if (district != null || stateName != null) {
        // Update district/state if provided from external source
        state = state.copyWith(
          district: district,
          state: stateName,
          latitude: finalLat,
          longitude: finalLng,
        );
      }

      // Fetch current conditions + 5-day forecast from backend
      final weather = await _api.getWeather(
        latitude: finalLat,
        longitude: finalLng,
      );

      state = state.copyWith(weather: weather, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

/// Global weather provider — usable from Home, Advisory, or any screen.
final weatherProvider =
    StateNotifierProvider<WeatherNotifier, WeatherState>(
  (_) => WeatherNotifier(),
);
