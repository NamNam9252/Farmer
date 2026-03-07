import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../router/route_names.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../../weather/presentation/providers/weather_provider.dart';
import '../../../weather/data/models/weather_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';
    final weatherState = ref.watch(weatherProvider);

    // Trigger weather fetch on first load
    if (weatherState.weather == null &&
        !weatherState.isLoading &&
        weatherState.error == null) {
      Future.microtask(() => ref.read(weatherProvider.notifier).fetchWeather());
    }

    String userName = isHindi ? 'किसान' : 'Farmer';
    if (authState is Authenticated) {
      userName = authState.user.name;
    }

    // Location from weather provider or fallback
    String locationText = isHindi ? 'हापुड़, उत्तर प्रदेश' : 'Hapur, Uttar Pradesh';
    if (weatherState.district.isNotEmpty) {
      locationText = '${weatherState.district}, ${weatherState.state}';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _buildHeader(context, ref, userName, lang, isHindi, locationText),
            const SizedBox(height: 16),
            _buildWeatherCard(context, isHindi, weatherState),
            const SizedBox(height: 24),
            _buildServicesSection(context, isHindi),
            const SizedBox(height: 24),
            _buildMandiPricesSection(isHindi),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    String userName,
    String lang,
    bool isHindi,
    String locationText,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: const Icon(
              Icons.person_rounded,
              size: 30,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHindi ? 'नमस्ते, $userName 🙏' : 'Namaste, $userName 🙏',
                  style: AppTextStyles.headline2,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      locationText,
                      style: AppTextStyles.body2,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Language Toggle
          GestureDetector(
            onTap: () {
              ref.read(languageProvider.notifier).state =
                  lang == 'hi' ? 'en' : 'hi';
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                lang == 'hi' ? 'EN' : 'हि',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Bell Icon
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.notifications_outlined,
                size: 24,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(
    BuildContext context,
    bool isHindi,
    WeatherState weatherState,
  ) {
    final w = weatherState.weather;
    final tempText = w != null ? '${w.temperature.round()}°C' : '--°C';
    final rainProb = w?.rainProbability ?? 0;
    final humidityVal = w?.humidity ?? 0;

    String subtitle;
    if (w == null) {
      subtitle = weatherState.isLoading
          ? (isHindi ? 'लोड हो रहा है...' : 'Loading...')
          : (isHindi
              ? 'मौसम डेटा उपलब्ध नहीं'
              : 'Weather data unavailable');
    } else if (rainProb >= 50) {
      subtitle = isHindi
          ? 'बारिश की ${rainProb.round()}% संभावना'
          : '${rainProb.round()}% chance of rain';
    } else if (humidityVal > 80) {
      subtitle = isHindi ? 'उच्च नमी' : 'High humidity';
    } else {
      subtitle = isHindi ? 'मौसम साफ है' : 'Clear weather';
    }

    IconData weatherIcon;
    Color iconColor;
    if (w == null) {
      weatherIcon = Icons.cloud_outlined;
      iconColor = const Color(0xFF90A4AE);
    } else if (rainProb >= 50) {
      weatherIcon = Icons.grain_rounded;
      iconColor = const Color(0xFF42A5F5);
    } else if (w.temperature > 35) {
      weatherIcon = Icons.wb_sunny_rounded;
      iconColor = const Color(0xFFF9A825);
    } else {
      weatherIcon = Icons.wb_sunny_rounded;
      iconColor = const Color(0xFFF9A825);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          if (w != null) {
            _showWeatherForecast(context, isHindi, weatherState);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFDFF0FA),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHindi ? 'मौसम अपडेट' : 'WEATHER UPDATE',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1565C0),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tempText,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1565C0),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    if (w != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        isHindi
                            ? 'नमी: ${humidityVal.round()}%'
                            : 'Humidity: ${humidityVal.round()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                weatherIcon,
                size: 72,
                color: iconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWeatherForecast(
    BuildContext context,
    bool isHindi,
    WeatherState weatherState,
  ) {
    if (weatherState.weather == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isHindi
                          ? AppStrings.weatherForecastHindi
                          : AppStrings.weatherForecast,
                      style: AppTextStyles.headline1,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  itemCount: weatherState.weather!.forecast.length,
                  itemBuilder: (context, index) {
                    final forecast = weatherState.weather!.forecast[index];
                    final date = DateTime.parse(forecast.date);
                    final isToday = index == 0;

                    // Date Formatting
                    String dateStr;
                    if (isToday) {
                      dateStr = isHindi ? 'आज' : 'Today';
                    } else {
                      dateStr = isHindi
                          ? DateFormat('EEEE', 'hi').format(date)
                          : DateFormat('EEEE').format(date);
                    }

                    final fullDateStr = isHindi
                        ? DateFormat('d MMMM', 'hi').format(date)
                        : DateFormat('d MMMM').format(date);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.primary.withValues(alpha: 0.05)
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isToday
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : Colors.grey[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isToday
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  fullDateStr,
                                  style: AppTextStyles.body2,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.water_drop_rounded,
                                      size: 14,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${forecast.rainProbability}%',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.opacity_rounded,
                                      size: 14,
                                      color: Colors.teal,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${forecast.humidity}%',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Icon(Icons.arrow_upward_rounded,
                                        size: 12, color: Colors.red),
                                    const SizedBox(width: 1),
                                    Text(
                                      '${forecast.maxTemp}°',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_downward_rounded,
                                        size: 12, color: Colors.blue),
                                    const SizedBox(width: 1),
                                    Text(
                                      '${forecast.minTemp}°',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  isHindi
                                      ? '${forecast.rainSum} mm ${AppStrings.rainChanceHindi}'
                                      : '${forecast.rainSum} mm rain',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServicesSection(BuildContext context, bool isHindi) {
    final services = [
      _ServiceItem(
        labelEn: 'Market\n(Mandi)',
        labelHi: 'बाज़ार\n(मंडी)',
        icon: Icons.storefront_rounded,
        iconColor: Colors.white,
        iconBgColor: const Color(0xFFF57C00),
        cardBgColor: const Color(0xFFFFF3E0),
        onTap: () => context.go(RouteNames.market),
      ),
      _ServiceItem(
        labelEn: 'Crop\nAdvisory',
        labelHi: 'फसल\nसलाह',
        icon: Icons.psychology_rounded,
        iconColor: Colors.white,
        iconBgColor: const Color(0xFF4CAF50),
        cardBgColor: const Color(0xFFE8F5E9),
        onTap: () => context.go(RouteNames.advisory),
      ),
      _ServiceItem(
        labelEn: 'Disease\nDetection',
        labelHi: 'रोग\nपहचान',
        icon: Icons.pest_control_rounded,
        iconColor: Colors.white,
        iconBgColor: const Color(0xFFE53935),
        cardBgColor: const Color(0xFFFFEBEE),
        onTap: () => context.go(RouteNames.disease),
      ),
      _ServiceItem(
        labelEn: 'Schemes',
        labelHi: 'योजनाएं',
        icon: Icons.account_balance_rounded,
        iconColor: Colors.white,
        iconBgColor: const Color(0xFF1E88E5),
        cardBgColor: const Color(0xFFE3F2FD),
        onTap: () => _showComingSoon(context, isHindi),
      ),
      _ServiceItem(
        labelEn: 'Community\nFund',
        labelHi: 'सामुदायिक\nनिधि',
        icon: Icons.groups_rounded,
        iconColor: Colors.white,
        iconBgColor: const Color(0xFF8E24AA),
        cardBgColor: const Color(0xFFF3E5F5),
        onTap: () => _showComingSoon(context, isHindi),
      ),
      _ServiceItem(
        labelEn: 'Crop Diary',
        labelHi: 'फसल डायरी',
        icon: Icons.menu_book_rounded,
        iconColor: Colors.white,
        iconBgColor: const Color(0xFF5D4037),
        cardBgColor: const Color(0xFFEFEBE9),
        onTap: () => _showComingSoon(context, isHindi),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isHindi ? 'कृषि सेवाएं' : 'Agriculture Services',
                style: AppTextStyles.headline2,
              ),
              GestureDetector(
                onTap: () => _showComingSoon(context, isHindi),
                child: Text(
                  isHindi ? 'सभी देखें' : 'View All',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: services.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              return _ServiceCard(item: services[index], isHindi: isHindi);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMandiPricesSection(bool isHindi) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isHindi ? 'लाइव मंडी भाव' : 'Live Mandi Prices',
            style: AppTextStyles.headline2,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _MandiPriceTile(
                  emoji: '🌾',
                  cropName: isHindi ? 'गेहूं' : 'Wheat (गेहूं)',
                  price: '₹2,450 /qt',
                  isUp: true,
                ),
                const SizedBox(width: 12),
                _MandiPriceTile(
                  emoji: '🌻',
                  cropName: isHindi ? 'सरसों' : 'Mustard (सरसों)',
                  price: '₹5,100 /qt',
                  isUp: false,
                ),
                const SizedBox(width: 12),
                _MandiPriceTile(
                  emoji: '🌽',
                  cropName: isHindi ? 'मक्का' : 'Maize (मक्का)',
                  price: '₹1,980 /qt',
                  isUp: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, bool isHindi) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isHindi ? 'जल्द आ रहा है! 🚧' : 'Coming Soon! 🚧',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class _ServiceItem {
  const _ServiceItem({
    required this.labelEn,
    required this.labelHi,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.cardBgColor,
    required this.onTap,
  });

  final String labelEn;
  final String labelHi;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final Color cardBgColor;
  final VoidCallback onTap;
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.item, required this.isHindi});

  final _ServiceItem item;
  final bool isHindi;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: item.cardBgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: item.iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.iconColor, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              isHindi ? item.labelHi : item.labelEn,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MandiPriceTile extends StatelessWidget {
  const _MandiPriceTile({
    required this.emoji,
    required this.cropName,
    required this.price,
    required this.isUp,
  });

  final String emoji;
  final String cropName;
  final String price;
  final bool isUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  cropName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isUp
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 16,
                      color: isUp ? AppColors.success : AppColors.error,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
