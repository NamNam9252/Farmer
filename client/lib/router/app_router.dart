import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'route_names.dart';
import '../features/disease/presentation/screens/disease_screen.dart';
import '../features/market/presentation/screens/market_book_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/auth/presentation/screens/otp_verification_screen.dart';
import '../features/onboarding/presentation/screens/location_setup_screen.dart';
import '../features/onboarding/presentation/screens/role_onboarding_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/state/auth_state.dart';
import '../shared/widgets/bottom_nav_bar.dart';
import '../core/theme/app_theme.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/advisory/presentation/screens/advisory_screen.dart';
import '../features/crop_recommendation/presentation/screens/crop_recommendation_screen.dart';
import '../features/community/presentation/screens/community_screen.dart';
import '../features/community/presentation/screens/community_detail_screen.dart';
import '../features/community/presentation/screens/join_requests_screen.dart';
import '../features/marketplace_new/presentation/screens/marketplace_new_home_screen.dart';
import '../features/marketplace_new/presentation/screens/post_item_screen.dart';
import '../features/marketplace_new/presentation/screens/post_demand_screen.dart';
import '../features/marketplace_new/presentation/screens/browse_items_screen.dart';
import '../features/marketplace_new/presentation/screens/browse_demands_screen.dart';
import '../features/marketplace_new/presentation/screens/item_detail_screen.dart';
import '../features/marketplace_new/presentation/screens/demand_detail_screen.dart';
import '../features/marketplace_new/presentation/screens/my_listings_screen.dart';
import '../features/marketplace_new/presentation/screens/my_purchase_requests_screen.dart';
import '../features/marketplace_new/presentation/screens/my_demand_offers_screen.dart';
import '../features/marketplace_new/data/models/marketplace_new_models.dart';
import '../features/chatbot/presentation/screens/chatbot_screen.dart';
import '../features/weather/presentation/screens/weather_details_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';

part 'app_router.g.dart';

final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);

final rootNavigatorKey = GlobalKey<NavigatorState>();
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authControllerProvider);
  final prefs = ref.watch(sharedPrefsProvider);
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RouteNames.splash,
    redirect: (context, state) {
      final isAuth = authState is Authenticated;
      final isLoading = authState is AuthLoading || authState is AuthInitial;

      final isGoingToSplash = state.uri.path == RouteNames.splash;
      final isGoingToLogin = state.uri.path == RouteNames.login;
      final isGoingToSignup = state.uri.path == RouteNames.signup;
      final isGoingToOnboarding = state.uri.path == RouteNames.onboarding;

      if (isLoading) {
        return isGoingToSplash ? null : RouteNames.splash;
      }

      if (!isAuth &&
          !isGoingToLogin &&
          !isGoingToSignup &&
          !isGoingToOnboarding) {
        return hasSeenOnboarding ? RouteNames.login : RouteNames.onboarding;
      }

      if (isAuth &&
          (isGoingToSplash ||
              isGoingToLogin ||
              isGoingToSignup ||
              isGoingToOnboarding)) {
        return RouteNames.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const Scaffold(
          backgroundColor: AppColors.primary,
          body: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: RouteNames.otpVerification,
        builder: (context, state) {
          final email = state.extra as String?;
          return OtpVerificationScreen(email: email ?? '');
        },
      ),
      GoRoute(
        path: RouteNames.locationSetup,
        builder: (context, state) => const LocationSetupScreen(),
      ),
      GoRoute(
        path: RouteNames.roleSetup,
        builder: (context, state) => const RoleOnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          final location = state.uri.path;
          int currentIndex = 0;
          if (location.startsWith(RouteNames.disease)) currentIndex = 1;
          if (location.startsWith(RouteNames.market)) currentIndex = 2;
          if (location.startsWith(RouteNames.profile)) currentIndex = 3;

          return AppBottomNavBar(currentIndex: currentIndex, child: child);
        },
        routes: [
          GoRoute(
            path: RouteNames.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: RouteNames.disease,
            builder: (context, state) => const DiseaseScreen(),
          ),
          GoRoute(
            path: RouteNames.market,
            builder: (context, state) => const MarketBookScreen(),
          ),
          GoRoute(
            path: RouteNames.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: RouteNames.help,
            builder: (context, state) => const _PlaceholderScreen(
              title: 'मदद',
              subtitle: 'Help & Support - Coming Soon',
              icon: Icons.support_agent_rounded,
            ),
          ),
          GoRoute(
            path: RouteNames.advisory,
            builder: (context, state) => const AdvisoryScreen(),
          ),
          GoRoute(
            path: RouteNames.cropRecommendation,
            builder: (context, state) => const CropRecommendationScreen(),
          ),
          GoRoute(
            path: RouteNames.marketplaceNew,
            name: RouteNames.marketplaceNew,
            builder: (context, state) => const MarketplaceNewHomeScreen(),
            routes: [
              GoRoute(
                path: 'post-item',
                name: RouteNames.postItem,
                builder: (context, state) {
                  final item = state.extra as MarketplaceItem?;
                  return PostItemScreen(item: item);
                },
              ),
              GoRoute(
                path: 'post-demand',
                name: RouteNames.postDemand,
                builder: (context, state) {
                  final demand = state.extra as MarketplaceDemand?;
                  return PostDemandScreen(demand: demand);
                },
              ),
              GoRoute(
                path: 'browse-items',
                name: RouteNames.browseItems,
                builder: (context, state) => const BrowseItemsScreen(),
              ),
              GoRoute(
                path: 'browse-demands',
                name: RouteNames.browseDemands,
                builder: (context, state) => const BrowseDemandsScreen(),
              ),
              GoRoute(
                path: 'item-detail',
                name: RouteNames.itemDetail,
                builder: (context, state) {
                  final item = state.extra as MarketplaceItem;
                  return ItemDetailScreen(item: item);
                },
              ),
              GoRoute(
                path: 'demand-detail',
                name: RouteNames.demandDetail,
                builder: (context, state) {
                  final demand = state.extra as MarketplaceDemand;
                  return DemandDetailScreen(demand: demand);
                },
              ),
              GoRoute(
                path: 'my-listings',
                name: RouteNames.myListings,
                builder: (context, state) => const MyListingsScreen(),
              ),
              GoRoute(
                path: 'purchase-requests',
                name: RouteNames.myPurchaseRequests,
                builder: (context, state) => const MyPurchaseRequestsScreen(),
              ),
              GoRoute(
                path: 'demand-offers',
                name: RouteNames.myDemandOffers,
                builder: (context, state) => const MyDemandOffersScreen(),
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.community,
            name: RouteNames.community,
            builder: (context, state) => const CommunityScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: RouteNames.communityDetail,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  final name = state.uri.queryParameters['name'] ?? 'Community';
                  return CommunityDetailScreen(
                    communityId: id,
                    communityName: name,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'requests',
                    name: RouteNames.communityJoinRequests,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return JoinRequestsScreen(communityId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.chatbot,
            builder: (context, state) => const ChatbotScreen(),
          ),
          GoRoute(
            path: RouteNames.weatherDetails,
            builder: (context, state) => const WeatherDetailsScreen(),
          ),
        ],
      ),
    ],
  );
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              subtitle,
              style: AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
