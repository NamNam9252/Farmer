/// Daily forecast for one day.
class DailyForecast {
  final String date;
  final int maxTemp;
  final int minTemp;
  final int humidity;
  final double rainSum;
  final int rainProbability;
  final String summary;

  const DailyForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.humidity,
    required this.rainSum,
    required this.rainProbability,
    required this.summary,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      date: json['date'] as String? ?? '',
      maxTemp: (json['maxTemp'] as num?)?.toInt() ?? 0,
      minTemp: (json['minTemp'] as num?)?.toInt() ?? 0,
      humidity: (json['humidity'] as num?)?.toInt() ?? 0,
      rainSum: (json['rainSum'] as num?)?.toDouble() ?? 0,
      rainProbability: (json['rainProbability'] as num?)?.toInt() ?? 0,
      summary: json['summary'] as String? ?? '',
    );
  }
}

/// Hourly forecast piece.
class HourlyForecast {
  final String time;
  final double temp;
  final int humidity;
  final int rainProbability;

  const HourlyForecast({
    required this.time,
    required this.temp,
    required this.humidity,
    required this.rainProbability,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    return HourlyForecast(
      time: json['time'] as String? ?? '',
      temp: (json['temp'] as num?)?.toDouble() ?? 0,
      humidity: (json['humidity'] as num?)?.toInt() ?? 0,
      rainProbability: (json['rainProbability'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Weather alert model.
class WeatherAlert {
  final String sender;
  final String event;
  final int start;
  final int end;
  final String description;

  const WeatherAlert({
    required this.sender,
    required this.event,
    required this.start,
    required this.end,
    required this.description,
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    return WeatherAlert(
      sender: json['sender'] as String? ?? '',
      event: json['event'] as String? ?? '',
      start: (json['start'] as num?)?.toInt() ?? 0,
      end: (json['end'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? '',
    );
  }
}

/// Data model for current weather + forecast + hourly + alerts.
class WeatherModel {
  final double temperature;
  final double humidity;
  final double rainProbability;
  final String overview;
  final List<DailyForecast> forecast;
  final List<HourlyForecast> hourly;
  final List<WeatherAlert> alerts;

  const WeatherModel({
    required this.temperature,
    required this.humidity,
    required this.rainProbability,
    required this.overview,
    required this.forecast,
    required this.hourly,
    required this.alerts,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0,
      rainProbability: (json['rain_probability'] as num?)?.toDouble() ?? 0,
      overview: json['overview'] as String? ?? '',
      forecast: (json['forecast'] as List<dynamic>? ?? [])
          .map((e) => DailyForecast.fromJson(e as Map<String, dynamic>))
          .toList(),
      hourly: (json['hourly'] as List<dynamic>? ?? [])
          .map((e) => HourlyForecast.fromJson(e as Map<String, dynamic>))
          .toList(),
      alerts: (json['alerts'] as List<dynamic>? ?? [])
          .map((e) => WeatherAlert.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
