/// Data model for weather API response.
class WeatherModel {
  final double temperature;
  final double humidity;
  final double rainProbability;

  const WeatherModel({
    required this.temperature,
    required this.humidity,
    required this.rainProbability,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0,
      rainProbability: (json['rain_probability'] as num?)?.toDouble() ?? 0,
    );
  }
}
