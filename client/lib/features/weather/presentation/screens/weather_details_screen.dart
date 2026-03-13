import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../providers/weather_provider.dart';
import '../../data/models/weather_model.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../shared/widgets/shared_app_bar.dart';

class WeatherDetailsScreen extends ConsumerWidget {
  const WeatherDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherState = ref.watch(weatherProvider);
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';
    final weather = weatherState.weather;

    if (weather == null) {
      return Scaffold(
        appBar: AppBar(title: Text(isHindi ? 'मौसम की जानकारी' : 'Weather Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          _buildDynamicBackground(weather),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // SharedSliverAppBar instead of _buildAppBar
              SharedSliverAppBar(
                title: isHindi ? 'मौसम की रिपोर्ट' : 'Weather Report',
                subtitle: '${weatherState.district}, ${weatherState.state}',
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAlertBanner(weather.alerts, isHindi),
                      const SizedBox(height: 16),
                      _buildCurrentWeatherCard(weather, isHindi),
                      const SizedBox(height: 24),
                      _buildAIOverviewCard(weather.overview, isHindi),
                      const SizedBox(height: 24),
                      _buildHourlyTimeline(weather.hourly, isHindi),
                      const SizedBox(height: 24),
                      _buildDailyForecast(weather.forecast, isHindi),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicBackground(WeatherModel weather) {
    // Dynamic colors based on weather conditions
    final isHot = weather.temperature > 30;
    final isRaining = weather.rainProbability > 50;
    
    final color1 = isHot 
        ? const Color(0xFFFF9800) 
        : (isRaining ? const Color(0xFF455A64) : const Color(0xFF2196F3));
    final color2 = isHot 
        ? const Color(0xFFFF5722) 
        : (isRaining ? const Color(0xFF263238) : const Color(0xFF1976D2));

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color1, color2],
        ),
      ),
    );
  }


  Widget _buildAlertBanner(List<WeatherAlert> alerts, bool isHindi) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHindi ? 'मौसम की चेतावनी' : 'Weather Alert',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  alerts.first.event,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeatherCard(WeatherModel weather, bool isHindi) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weather.temperature.round()}°',
                        style: const TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      Text(
                        isHindi ? 'वर्तमान तापमान' : 'Current Temp',
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                  Icon(
                    weather.rainProbability > 50 ? Icons.grain_rounded : Icons.wb_sunny_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(Icons.water_drop_rounded, '${weather.humidity.round()}%', isHindi ? 'नमी' : 'Humidity'),
                  _buildStatItem(Icons.umbrella_rounded, '${weather.rainProbability.round()}%', isHindi ? 'बारिश' : 'Rain'),
                  _buildStatItem(Icons.air_rounded, '12 km/h', isHindi ? 'हवा' : 'Wind'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ],
    );
  }

  Widget _buildAIOverviewCard(String overview, bool isHindi) {
    if (overview.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                isHindi ? 'दैनिक समाचार (AI)' : 'Daily Weather News (AI)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            overview,
            style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyTimeline(List<HourlyForecast> hourly, bool isHindi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isHindi ? 'अगले 24 घंटे' : 'Next 24 Hours',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: hourly.length > 24 ? 24 : hourly.length,
            itemBuilder: (context, index) {
              final h = hourly[index];
              final time = DateTime.parse(h.time);
              final timeStr = DateFormat('ha').format(time);

              return Container(
                width: 70,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(timeStr, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    Icon(
                      h.rainProbability > 50 ? Icons.grain_rounded : Icons.wb_sunny_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text('${h.temp.round()}°', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDailyForecast(List<DailyForecast> forecast, bool isHindi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isHindi ? '7 दिनों का पूर्वानुमान' : '7-Day Forecast',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        ...forecast.map((f) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  DateFormat('EEEE').format(DateTime.parse(f.date)),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    const Icon(Icons.water_drop_rounded, size: 14, color: Colors.lightBlueAccent),
                    const SizedBox(width: 4),
                    Text('${f.rainProbability}%', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${f.maxTemp}°', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text('${f.minTemp}°', style: const TextStyle(color: Colors.white60)),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
