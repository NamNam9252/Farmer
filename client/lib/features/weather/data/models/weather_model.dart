/// Daily forecast for one day coming from the backend.
class DailyForecast {
  final String date;
  final int maxTemp;
  final int minTemp;
  final int humidity;
  final double rainSum;
  final int rainProbability;

  const DailyForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.humidity,
    required this.rainSum,
    required this.rainProbability,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      date: json['date'] as String? ?? '',
      maxTemp: (json['maxTemp'] as num?)?.toInt() ?? 0,
      minTemp: (json['minTemp'] as num?)?.toInt() ?? 0,
      humidity: (json['humidity'] as num?)?.toInt() ?? 0,
      rainSum: (json['rainSum'] as num?)?.toDouble() ?? 0,
      rainProbability: (json['rainProbability'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Data model for current weather + 5-day forecast.
class WeatherModel {
  final double temperature;
  final double humidity;
  final double rainProbability;
  final List<DailyForecast> forecast;

  const WeatherModel({
    required this.temperature,
    required this.humidity,
    required this.rainProbability,
    required this.forecast,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final rawForecast = json['forecast'] as List<dynamic>? ?? [];
    return WeatherModel(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0,
      rainProbability: (json['rain_probability'] as num?)?.toDouble() ?? 0,
      forecast: rawForecast
          .map((e) => DailyForecast.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
