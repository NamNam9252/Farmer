import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../notifications/presentation/widgets/notification_sheet.dart';
import '../../../../core/services/location_provider.dart';
import '../../../community/presentation/providers/community_provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../router/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../../weather/presentation/providers/weather_provider.dart';
import '../../../../shared/widgets/shared_app_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';
    final weatherState = ref.watch(weatherProvider);

    // Trigger notification fetch on first load
    final notificationState = ref.watch(notificationProvider);
    if (!notificationState.hasLoaded &&
        !notificationState.isLoading &&
        notificationState.error == null) {
      Future.microtask(
        () => ref.read(notificationProvider.notifier).loadNotifications(),
      );
    }

    // Trigger eager location and community fetch
    final locState = ref.watch(locationProvider);
    final communityState = ref.watch(communityListProvider);

    if (locState.position == null &&
        !locState.isLoading &&
        locState.error == null) {
      Future.microtask(() async {
        await ref.read(locationProvider.notifier).refreshLocation();
        final updatedLoc = ref.read(locationProvider).position;
        if (updatedLoc != null) {
          if (communityState.communities.isEmpty && !communityState.isLoading) {
            ref.read(communityListProvider.notifier).loadNearby(
              updatedLoc.latitude,
              updatedLoc.longitude,
            );
          }
          if (weatherState.weather == null && !weatherState.isLoading) {
            ref
                .read(weatherProvider.notifier)
                .fetchWeather(
                  latitude: updatedLoc.latitude,
                  longitude: updatedLoc.longitude,
                  district: updatedLoc.district,
                  stateName: updatedLoc.state,
                );
          }
        }
      });
    } else if (locState.position != null &&
        weatherState.weather == null &&
        !weatherState.isLoading &&
        weatherState.error == null) {
      Future.microtask(
        () => ref.read(weatherProvider.notifier).fetchWeather(
          latitude: locState.position!.latitude,
          longitude: locState.position!.longitude,
          district: locState.position!.district,
          stateName: locState.position!.state,
        ),
      );
    }

    String userName = isHindi ? 'किसान' : 'Farmer';
    if (authState is Authenticated) {
      userName = authState.user.name;
    }

    String locationText =
        isHindi ? 'हापुड़, उत्तर प्रदेश' : 'Hapur, Uttar Pradesh';
    if (locState.position != null) {
      locationText =
          '${locState.position!.district}, ${locState.position!.state}';
    } else if (weatherState.district.isNotEmpty) {
      locationText = '${weatherState.district}, ${weatherState.state}';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await ref
              .read(locationProvider.notifier)
              .refreshLocation(force: true);
          final updatedLoc = ref.read(locationProvider).position;
          if (updatedLoc != null) {
            await ref.read(communityListProvider.notifier).loadNearby(
              updatedLoc.latitude,
              updatedLoc.longitude,
            );
            await ref.read(weatherProvider.notifier).fetchWeather(
              latitude: updatedLoc.latitude,
              longitude: updatedLoc.longitude,
              district: updatedLoc.district,
              stateName: updatedLoc.state,
            );
          }
          await ref.read(notificationProvider.notifier).loadNotifications();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ── Sticky Header ──
            SharedStickyHeader(
              title: isHindi ? 'नमस्ते, $userName 🙏' : 'Namaste, $userName 🙏',
              subtitle: locationText,
              showBackButton: false,
              expandedHeight: 180,
              collapsedHeight: 100,
              leading: GestureDetector(
                onTap: () => context.push(RouteNames.profile),
                child: Container(
                  margin: const EdgeInsets.only(left: 12),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 26,
                    color: Colors.white,
                  ),
                ),
              ),
              actions: [
                Consumer(
                  builder: (context, ref, child) {
                    final ns = ref.watch(notificationProvider);
                    final unreadCount =
                        ns.notifications.where((n) => !n.isRead).length;

                    return GestureDetector(
                      onTap: () => NotificationSheet.show(context, ref, isHindi),
                      child: Container(
                        width: 42,
                        height: 42,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF5252),
                                    shape: BoxShape.circle,
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

            // ── Body content ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildAlertBanner(context, weatherState, isHindi),
                    _buildWeatherCard(context, isHindi, weatherState),
                    const SizedBox(height: 28),
                    _buildServicesSection(context, isHindi),
                    const SizedBox(height: 28),
                    _buildMandiPricesSection(isHindi),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  ALERT BANNER
  // ──────────────────────────────────────────────────────────
  Widget _buildAlertBanner(
    BuildContext context,
    WeatherState weatherState,
    bool isHindi,
  ) {
    final alerts = weatherState.weather?.alerts ?? [];
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEF9A9A), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                alerts.first.event,
                style: const TextStyle(
                  color: Color(0xFFC62828),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.push(RouteNames.weatherDetails),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                isHindi ? 'देखें' : 'View',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  WEATHER CARD
  // ──────────────────────────────────────────────────────────
  Widget _buildWeatherCard(
    BuildContext context,
    bool isHindi,
    WeatherState weatherState,
  ) {
    final w = weatherState.weather;
    final tempText = w != null ? '${w.temperature.round()}°C' : '--°C';
    final rainProb = w?.rainProbability ?? 0;
    final humidityVal = (w?.humidity ?? 0).toDouble();

    String subtitle;
    if (w == null) {
      subtitle = weatherState.isLoading
          ? (isHindi ? 'लोड हो रहा है...' : 'Loading...')
          : (isHindi ? 'मौसम डेटा उपलब्ध नहीं' : 'Weather data unavailable');
    } else if (rainProb >= 50) {
      subtitle =
          isHindi
              ? 'बारिश की ${rainProb.round()}% संभावना'
              : '${rainProb.round()}% chance of rain';
    } else if (humidityVal > 80) {
      subtitle = isHindi ? 'उच्च नमी' : 'High humidity';
    } else {
      subtitle = isHindi ? 'मौसम साफ है' : 'Clear weather';
    }

    String weatherSvg;
    if (w == null) {
      weatherSvg = AppIcons.weatherCloud;
    } else if (rainProb >= 50) {
      weatherSvg = AppIcons.weatherRainy;
    } else {
      weatherSvg = AppIcons.weatherSunny;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GestureDetector(
        onTap: () {
          if (w != null) context.push(RouteNames.weatherDetails);
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1565C0), Color(0xFF1E88E5), Color(0xFF42A5F5)],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isHindi ? '☁ मौसम अपडेट' : '☁ WEATHER UPDATE',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tempText,
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    if (w != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _WeatherStat(
                            icon: Icons.water_drop_rounded,
                            value:
                                isHindi
                                    ? 'नमी: ${humidityVal.round()}%'
                                    : 'Humidity: ${humidityVal.round()}%',
                          ),
                          const SizedBox(width: 12),
                          _WeatherStat(
                            icon: Icons.umbrella_rounded,
                            value:
                                isHindi
                                    ? 'वर्षा: ${rainProb.round()}%'
                                    : 'Rain: ${rainProb.round()}%',
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SvgPicture.string(weatherSvg, width: 80, height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  SERVICES SECTION
  // ──────────────────────────────────────────────────────────
  Widget _buildServicesSection(BuildContext context, bool isHindi) {
    final services = _buildServiceItems(context, isHindi);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isHindi ? 'कृषि सेवाएं' : 'Agriculture Services',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _showAllFeatures(context, isHindi),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    isHindi ? 'सभी देखें' : 'See All',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 18,
              crossAxisSpacing: 14,
              childAspectRatio: 0.80,
            ),
            itemBuilder: (context, index) {
              return _ServiceCard(item: services[index], isHindi: isHindi);
            },
          ),
        ],
      ),
    );
  }

  List<_ServiceItem> _buildServiceItems(
    BuildContext context,
    bool isHindi,
  ) {
    return [
      _ServiceItem(
        labelEn: 'Market\n(Mandi)',
        labelHi: 'बाज़ार\n(मंडी)',
        svgData: AppIcons.market,
        imageAsset: 'assets/icons/ic_market.png',
        bgColor: AppColors.cardSunshine,
        onTap: () => context.push(RouteNames.market),
      ),
      _ServiceItem(
        labelEn: 'Crop\nAdvisory',
        labelHi: 'फसल\nसलाह',
        svgData: AppIcons.cropAdvisory,
        imageAsset: 'assets/icons/ic_crop_advisory.png',
        bgColor: AppColors.cardMint,
        onTap: () => context.push(RouteNames.advisory),
      ),
      _ServiceItem(
        labelEn: 'Disease\nDetection',
        labelHi: 'रोग\nपहचान',
        svgData: AppIcons.disease,
        imageAsset: 'assets/icons/ic_disease.png',
        bgColor: AppColors.cardRose,
        onTap: () => context.push(RouteNames.disease),
      ),
      _ServiceItem(
        labelEn: 'Schemes',
        labelHi: 'योजनाएं',
        svgData: AppIcons.schemes,
        imageAsset: 'assets/icons/ic_schemes.png',
        bgColor: AppColors.cardSky,
        onTap: () => context.push(RouteNames.schemes),
      ),
      _ServiceItem(
        labelEn: 'Community\nFund',
        labelHi: 'समुदाय\nनिधि',
        svgData: AppIcons.community,
        imageAsset: 'assets/icons/ic_community.png',
        bgColor: AppColors.cardLavender,
        onTap: () => context.push(RouteNames.community),
      ),
      _ServiceItem(
        labelEn: 'Smart\nFarming',
        labelHi: 'स्मार्ट\nखेती',
        svgData: AppIcons.smartFarming,
        imageAsset: 'assets/icons/ic_smart_farming.png',
        bgColor: AppColors.cardPeach,
        onTap: () => context.push(RouteNames.cropRecommendation),
      ),
    ];
  }

  // ──────────────────────────────────────────────────────────
  //  MANDI PRICES
  // ──────────────────────────────────────────────────────────
  Widget _buildMandiPricesSection(bool isHindi) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF57C00), Color(0xFFFFB74D)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isHindi ? 'लाइव मंडी भाव' : 'Live Mandi Prices',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _MandiPriceTile(
                  emoji: '🌾',
                  cropName: isHindi ? 'गेहूं' : 'Wheat',
                  price: '₹2,450',
                  unit: '/qt',
                  isUp: true,
                ),
                const SizedBox(width: 12),
                _MandiPriceTile(
                  emoji: '🌻',
                  cropName: isHindi ? 'सरसों' : 'Mustard',
                  price: '₹5,100',
                  unit: '/qt',
                  isUp: false,
                ),
                const SizedBox(width: 12),
                _MandiPriceTile(
                  emoji: '🌽',
                  cropName: isHindi ? 'मक्का' : 'Maize',
                  price: '₹1,980',
                  unit: '/qt',
                  isUp: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  //  ALL FEATURES BOTTOM SHEET
  // ──────────────────────────────────────────────────────────
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
                svgData: AppIcons.market,
                imageAsset: 'assets/icons/ic_market.png',
                bgColor: AppColors.cardSunshine,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(RouteNames.market);
                },
              ),
              _ServiceItem(
                labelEn: 'Crop\nAdvisory',
                labelHi: 'फसल\nसलाह',
                svgData: AppIcons.cropAdvisory,
                imageAsset: 'assets/icons/ic_crop_advisory.png',
                bgColor: AppColors.cardMint,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(RouteNames.advisory);
                },
              ),
              _ServiceItem(
                labelEn: 'Disease\nDetection',
                labelHi: 'रोग\nपहचान',
                svgData: AppIcons.disease,
                imageAsset: 'assets/icons/ic_disease.png',
                bgColor: AppColors.cardRose,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(RouteNames.disease);
                },
              ),
              _ServiceItem(
                labelEn: 'Smart\nFarming',
                labelHi: 'स्मार्ट\nखेती',
                svgData: AppIcons.smartFarming,
                imageAsset: 'assets/icons/ic_smart_farming.png',
                bgColor: AppColors.cardPeach,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(RouteNames.cropRecommendation);
                },
              ),
              _ServiceItem(
                labelEn: 'Govt\nSchemes',
                labelHi: 'सरकारी\nयोजनाएं',
                svgData: AppIcons.schemes,
                imageAsset: 'assets/icons/ic_schemes.png',
                bgColor: AppColors.cardSky,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(RouteNames.schemes);
                },
              ),
              _ServiceItem(
                labelEn: 'Community\nFund',
                labelHi: 'समुदाय\nनिधि',
                svgData: AppIcons.community,
                imageAsset: 'assets/icons/ic_community.png',
                bgColor: AppColors.cardLavender,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(RouteNames.community);
                },
              ),
              _ServiceItem(
                labelEn: 'Marketplace\n(New)',
                labelHi: 'मार्केटप्लेस\n(नया)',
                svgData: AppIcons.marketplace,
                imageAsset: 'assets/icons/ic_marketplace.png',
                bgColor: AppColors.cardMint,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(RouteNames.marketplaceNew);
                },
              ),
              _ServiceItem(
                labelEn: 'Warehouse\nStorage',
                labelHi: 'भंडारण\nसेवा',
                svgData: AppIcons.warehouse,
                bgColor: const Color(0xFFEFEBE9),
                onTap: () {
                  Navigator.pop(ctx);
                  _showComingSoon(context, isHindi);
                },
              ),
              _ServiceItem(
                labelEn: 'Weather\nAlerts',
                labelHi: 'मौसम\nचेतावनी',
                svgData: AppIcons.weatherAlert,
                imageAsset: 'assets/icons/ic_weather.png',
                bgColor: const Color(0xFFE1F5FE),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(RouteNames.weatherDetails);
                },
              ),
            ];

            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF6F8F6),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.apps_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isHindi ? 'सभी सेवाएं' : 'All Services',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              isHindi
                                  ? 'अपनी ज़रूरत की सेवा चुनें'
                                  : 'Choose a service you need',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
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
                    child: Divider(color: Colors.grey[200]),
                  ),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: allFeatures.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 18,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.80,
                          ),
                      itemBuilder: (_, index) => _ServiceCard(
                        item: allFeatures[index],
                        isHindi: isHindi,
                      ),
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
          isHindi ? 'जल्द आ रहा है!' : 'Coming Soon!',
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

// ──────────────────────────────────────────────────────────
//  WEATHER STAT CHIP
// ──────────────────────────────────────────────────────────
class _WeatherStat extends StatelessWidget {
  const _WeatherStat({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.white70),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────
//  SERVICE ITEM MODEL
// ──────────────────────────────────────────────────────────
class _ServiceItem {
  const _ServiceItem({
    required this.labelEn,
    required this.labelHi,
    required this.svgData,
    this.imageAsset,
    required this.bgColor,
    required this.onTap,
    this.isViewAll = false,
  });

  final String labelEn;
  final String labelHi;
  final String svgData;
  final String? imageAsset;
  final Color bgColor;
  final VoidCallback onTap;
  final bool isViewAll;
}

// ──────────────────────────────────────────────────────────
//  SERVICE CARD  (animated tap feedback)
// ──────────────────────────────────────────────────────────
class _ServiceCard extends StatefulWidget {
  const _ServiceCard({required this.item, required this.isHindi});

  final _ServiceItem item;
  final bool isHindi;

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.item.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: child,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon circle
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: widget.item.bgColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.item.bgColor.withValues(alpha: 0.6),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: widget.item.isViewAll
                    ? Center(
                        child: Icon(
                          Icons.grid_view_rounded,
                          size: 38,
                          color: AppColors.primary,
                        ),
                      )
                    : widget.item.imageAsset != null
                        ? Image.asset(
                            widget.item.imageAsset!,
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                          )
                        : widget.item.labelEn.contains('Smart')
                            ? _buildSmartFarmingIcon()
                            : Center(
                                child: SvgPicture.string(
                                  widget.item.svgData,
                                  width: 48,
                                  height: 48,
                                ),
                              ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isHindi
                  ? widget.item.labelHi.replaceAll('\n', ' ')
                  : widget.item.labelEn.replaceAll('\n', ' '),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartFarmingIcon() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.agriculture_rounded,
            size: 44,
            color: Colors.deepOrange[800]?.withValues(alpha: 0.15),
          ),
          Positioned(
            top: 14,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 32,
              color: Colors.deepOrange[800],
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.psychology_rounded,
                size: 20,
                color: Colors.deepOrange[400],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
//  MANDI PRICE TILE
// ──────────────────────────────────────────────────────────
class _MandiPriceTile extends StatelessWidget {
  const _MandiPriceTile({
    required this.emoji,
    required this.cropName,
    required this.price,
    required this.unit,
    required this.isUp,
  });

  final String emoji;
  final String cropName;
  final String price;
  final String unit;
  final bool isUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isUp ? AppColors.success : AppColors.error)
              .withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isUp
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFEBEE),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
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
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isUp
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFC62828),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      isUp
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 14,
                      color: isUp
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ],
                ),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
