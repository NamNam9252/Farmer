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
              backgroundImage: 'assets/images/service_icons/smart_farming.png',
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
    if (w == null) return const SizedBox.shrink();

    final tempText = '${w.temperature.round()}°';
    final now = DateTime.now();
    final isNight = now.hour < 6 || now.hour > 18;
    final isRaining = w.rainProbability > 50;
    final isHot = w.temperature > 32;

    // Condition subtitle
    String conditionText = isHindi ? 'साफ मौसम' : 'Clear Sky';
    if (isRaining) conditionText = isHindi ? 'बारिश की संभावना' : 'Rainy';
    else if (isHot) conditionText = isHindi ? 'तेज धूप' : 'Sunny & Hot';

    // Theme colors
    Color color1, color2;
    if (isNight) {
      color1 = isRaining ? const Color(0xFF1A237E) : const Color(0xFF0D47A1);
      color2 = isRaining ? const Color(0xFF000000) : const Color(0xFF121212);
    } else if (isRaining) {
      color1 = const Color(0xFF607D8B);
      color2 = const Color(0xFF263238);
    } else if (isHot) {
      color1 = const Color(0xFFFF9800);
      color2 = const Color(0xFFD84315);
    } else {
      color1 = const Color(0xFF2196F3);
      color2 = const Color(0xFF1565C0);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: GestureDetector(
        onTap: () => context.push(RouteNames.weatherDetails),
        child: Container(
          height: 205,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: color1.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 1. Dynamic Background Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color1, color2],
                  ),
                ),
              ),

              // 2. Celestial Body (Sun/Moon)
              Positioned(
                top: -20,
                right: -20,
                child: _buildHomeCelestialBody(isNight, isRaining, isHot),
              ),

              // 3. Floating Clouds
              _buildHomeCloud(0, -40, 40, isNight),
              _buildHomeCloud(1, 120, 100, isNight),

              // 4. Content Overlay
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          isHindi ? 'अभी का मौसम' : 'LIVE WEATHER',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      tempText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      conditionText,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _HomeWeatherStat(
                          icon: Icons.water_drop_rounded,
                          value: '${w.humidity.round()}%',
                          label: isHindi ? 'नमी' : 'Humidity',
                        ),
                        const SizedBox(width: 24),
                        _HomeWeatherStat(
                          icon: Icons.umbrella_rounded,
                          value: '${w.rainProbability.round()}%',
                          label: isHindi ? 'बारिश' : 'Rain',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeCelestialBody(bool isNight, bool isRaining, bool isHot) {
    if (isRaining) return const SizedBox.shrink();
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isNight ? Colors.indigoAccent : (isHot ? Colors.orange : Colors.yellow)).withValues(alpha: 0.4),
            blurRadius: 60,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Icon(
        isNight ? Icons.nightlight_round : Icons.wb_sunny_rounded,
        size: 80,
        color: isNight ? Colors.white.withValues(alpha: 0.9) : (isHot ? Colors.orangeAccent : Colors.yellow[200]),
      ),
    );
  }

  Widget _buildHomeCloud(int index, double top, double left, bool isNight) {
    return Positioned(
      top: top,
      left: left,
      child: Opacity(
        opacity: 0.3,
        child: Icon(
          Icons.cloud_rounded,
          size: 100 + (index * 20),
          color: isNight ? Colors.blueGrey[800] : Colors.white70,
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
            itemCount: services.length,
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
        labelEn: 'Crop\nPrice',
        labelHi: 'मंडी\nभाव',
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
        labelEn: 'Community',
        labelHi: 'समुदाय',
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
                labelEn: 'Crop\nPrice',
                labelHi: 'मंडी\nभाव',
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
                labelEn: 'Community',
                labelHi: 'समुदाय',
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
                labelEn: 'Get\nHelper',
                labelHi: 'मददगार\nखोजें',
                svgData: AppIcons.community,
                imageAsset: 'assets/icons/ic_get_helper.png',
                bgColor: AppColors.cardSky,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(RouteNames.laborListing);
                },
              ),
              _ServiceItem(
                labelEn: 'Warehouse\nStorage',
                labelHi: 'भंडारण\nसेवा',
                svgData: AppIcons.warehouse,
                imageAsset: 'assets/images/service_icons/warehouse.png',
                bgColor: const Color(0xFFEFEBE9),
                onTap: () {
                  Navigator.pop(ctx);
                  _showComingSoon(context, isHindi);
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

void _showComingSoon(BuildContext context, bool isHindi) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.stars_rounded, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            isHindi ? 'जल्द आ रहा है' : 'Coming Soon',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: Text(
        isHindi
            ? 'यह सुविधा जल्द ही उपलब्ध होगी। हमारे साथ बने रहें!'
            : 'This feature will be available soon. Stay tuned!',
        style: const TextStyle(fontSize: 15),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            isHindi ? 'ठीक है' : 'OK',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

class _HomeWeatherStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HomeWeatherStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

