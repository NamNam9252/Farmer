import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
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
import '../../../../shared/widgets/language_toggle.dart';

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

    // Trigger notification fetch on first load
    final notificationState = ref.watch(notificationProvider);
    if (!notificationState.hasLoaded && 
        !notificationState.isLoading && 
        notificationState.error == null) {
      Future.microtask(() => ref.read(notificationProvider.notifier).loadNotifications());
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
          const LanguageToggle(),
          const SizedBox(width: 8),
          // Bell Icon
          Consumer(
            builder: (context, ref, child) {
              final notificationState = ref.watch(notificationProvider);
              final unreadCount = notificationState.notifications.where((n) => !n.isRead).length;

              return GestureDetector(
                onTap: () => _showNotifications(context, ref, isHindi),
                child: Container(
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
                  child: Stack(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.notifications_outlined,
                          size: 24,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
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
        onTap: () => context.go(RouteNames.community),
      ),
      _ServiceItem(
        labelEn: 'Smart\nFarming',
        labelHi: 'स्मार्ट\nखेती',
        icon: Icons.analytics_rounded,
        iconColor: Colors.white,
        iconBgColor: const Color(0xFF00897B),
        cardBgColor: const Color(0xFFE0F2F1),
        onTap: () => context.go(RouteNames.cropRecommendation),
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
                onTap: () => _showAllFeatures(context, isHindi),
                child: Text(
                  isHindi ? 'सभी देखें' : 'View All',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
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
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
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

  void _showAllFeatures(BuildContext context, bool isHindi) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollController) {
            final allFeatures = [
              _ServiceItem(
                labelEn: 'Market\n(Mandi)',
                labelHi: 'बाज़ार\n(मंडी)',
                icon: Icons.storefront_rounded,
                iconColor: Colors.white,
                iconBgColor: const Color(0xFFF57C00),
                cardBgColor: const Color(0xFFFFF3E0),
                onTap: () {
                  Navigator.pop(ctx);
                  context.go(RouteNames.market);
                },
              ),
              _ServiceItem(
                labelEn: 'Crop\nAdvisory',
                labelHi: 'फसल\nसलाह',
                icon: Icons.psychology_rounded,
                iconColor: Colors.white,
                iconBgColor: const Color(0xFF4CAF50),
                cardBgColor: const Color(0xFFE8F5E9),
                onTap: () {
                  Navigator.pop(ctx);
                  context.go(RouteNames.advisory);
                },
              ),
              _ServiceItem(
                labelEn: 'Disease\nDetection',
                labelHi: 'रोग\nपहचान',
                icon: Icons.pest_control_rounded,
                iconColor: Colors.white,
                iconBgColor: const Color(0xFFE53935),
                cardBgColor: const Color(0xFFFFEBEE),
                onTap: () {
                  Navigator.pop(ctx);
                  context.go(RouteNames.disease);
                },
              ),
              _ServiceItem(
                labelEn: 'Crop\nRecommendation',
                labelHi: 'फसल\nसिफारिश',
                icon: Icons.agriculture_rounded,
                iconColor: Colors.white,
                iconBgColor: const Color(0xFF00897B),
                cardBgColor: const Color(0xFFE0F2F1),
                onTap: () {
                  Navigator.pop(ctx);
                  context.go(RouteNames.cropRecommendation);
                },
              ),
              _ServiceItem(
                labelEn: 'Govt\nSchemes',
                labelHi: 'सरकारी\nयोजनाएं',
                icon: Icons.account_balance_rounded,
                iconColor: Colors.white,
                iconBgColor: const Color(0xFF1E88E5),
                cardBgColor: const Color(0xFFE3F2FD),
                onTap: () {
                  Navigator.pop(ctx);
                  _showComingSoon(context, isHindi);
                },
              ),
              _ServiceItem(
                labelEn: 'Community\nFund',
                labelHi: 'सामुदायिक\nनिधि',
                icon: Icons.groups_rounded,
                iconColor: Colors.white,
                iconBgColor: const Color(0xFF8E24AA),
                cardBgColor: const Color(0xFFF3E5F5),
                onTap: () {
                  Navigator.pop(ctx);
                  context.go(RouteNames.community);
                },
              ),
              _ServiceItem(
                labelEn: 'Warehouse\nStorage',
                labelHi: 'भंडारण\nसेवा',
                icon: Icons.warehouse_rounded,
                iconColor: Colors.white,
                iconBgColor: const Color(0xFF6D4C41),
                cardBgColor: const Color(0xFFEFEBE9),
                onTap: () {
                  Navigator.pop(ctx);
                  _showComingSoon(context, isHindi);
                },
              ),
              _ServiceItem(
                labelEn: 'Weather\nAlerts',
                labelHi: 'मौसम\nचेतावनी',
                icon: Icons.thunderstorm_rounded,
                iconColor: Colors.white,
                iconBgColor: const Color(0xFF0288D1),
                cardBgColor: const Color(0xFFE1F5FE),
                onTap: () {
                  Navigator.pop(ctx);
                  _showComingSoon(context, isHindi);
                },
              ),
            ];

            return Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.apps_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isHindi ? 'सभी सेवाएं' : 'All Services',
                              style: AppTextStyles.headline2,
                            ),
                            Text(
                              isHindi
                                  ? 'अपनी ज़रूरत की सेवा चुनें'
                                  : 'Choose a service you need',
                              style: AppTextStyles.body2,
                            ),
                          ],
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Divider(),
                  ),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: allFeatures.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.78,
                      ),
                      itemBuilder: (_, index) {
                        return _ServiceCard(
                            item: allFeatures[index], isHindi: isHindi);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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

  void _showNotifications(BuildContext context, WidgetRef ref, bool isHindi) {
    ref.read(notificationProvider.notifier).loadNotifications();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(notificationProvider);

            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: const BoxDecoration(
                color: Color(0xFFF5FBF6),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isHindi ? 'सूचनाएं' : 'Notifications',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: state.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : state.notifications.isEmpty
                            ? Center(child: Text(isHindi ? 'कोई सूचना नहीं' : 'No notifications'))
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: state.notifications.length,
                                itemBuilder: (context, index) {
                                  final n = state.notifications[index];
                                  return Card(
                                    color: n.isRead ? Colors.white : const Color(0xFFE8F5E9),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: ListTile(
                                      title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text(n.body),
                                      trailing: n.isRead ? null : const Icon(Icons.circle, color: Color(0xFF2E7D32), size: 12),
                                      onTap: () {
                                        ref.read(notificationProvider.notifier).markAsRead(n.id);
                                        if (n.actionType == 'COMMUNITY_JOIN_REQUEST') {
                                           Navigator.pop(context);
                                           // Navigate directly to the management screen
                                           context.go('/community/${n.actionId}/requests');
                                        } else if (n.actionType == 'COMMUNITY_JOIN_APPROVED') {
                                           Navigator.pop(context);
                                           // Navigate to community detail
                                           context.go('/community/${n.actionId}');
                                        }
                                      },
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
      },
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
    this.cardBgColor = Colors.transparent,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.9),
                  blurRadius: 6,
                  offset: const Offset(-2, -2),
                ),
              ],
              border: Border.all(
                color: AppColors.divider.withValues(alpha: 0.5),
                width: 1.2,
              ),
            ),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: item.iconBgColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.iconBgColor, size: 30),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isHindi
                ? item.labelHi.replaceAll('\n', ' ')
                : item.labelEn.replaceAll('\n', ' '),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
        ],
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
