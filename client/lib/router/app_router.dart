import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'route_names.dart';
import '../features/disease/presentation/screens/disease_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/state/auth_state.dart';
import '../shared/widgets/bottom_nav_bar.dart';
import '../core/theme/app_theme.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';

part 'app_router.g.dart';

// Create a provider for SharedPreferences to check onboarding status synchronously during routing
final sharedPrefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authControllerProvider);
  final prefs = ref.watch(sharedPrefsProvider);
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

  return GoRouter(
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
      
      if (!isAuth && !isGoingToLogin && !isGoingToSignup && !isGoingToOnboarding) {
        return hasSeenOnboarding ? RouteNames.login : RouteNames.onboarding;
      }
      
      if (isAuth && (isGoingToSplash || isGoingToLogin || isGoingToSignup || isGoingToOnboarding)) {
        return RouteNames.disease;
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const Scaffold(
          backgroundColor: AppColors.primary,
          body: Center(child: CircularProgressIndicator(color: Colors.white)),
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
      ShellRoute(
        builder: (context, state, child) {
          final location = state.uri.path;
          int currentIndex = 0;
          if (location.startsWith(RouteNames.disease)) currentIndex = 1;
          if (location.startsWith(RouteNames.market)) currentIndex = 2;
          if (location.startsWith(RouteNames.help)) currentIndex = 3;

          return AppBottomNavBar(currentIndex: currentIndex, child: child);
        },
        routes: [
          GoRoute(
            path: RouteNames.home,
            builder: (context, state) => const _PlaceholderScreen(
              title: 'होम',
              subtitle: 'Home - Coming Soon',
              icon: Icons.home_rounded,
            ),
          ),
          GoRoute(
            path: RouteNames.disease,
            builder: (context, state) => const DiseaseScreen(),
          ),
          GoRoute(
            path: RouteNames.market,
            builder: (context, state) => const _PlaceholderScreen(
              title: 'बाज़ार',
              subtitle: 'Marketplace - Coming Soon',
              icon: Icons.storefront_rounded,
            ),
          ),
          GoRoute(
            path: RouteNames.help,
            builder: (context, state) => const _PlaceholderScreen(
              title: 'मदद',
              subtitle: 'Help & Support - Coming Soon',
              icon: Icons.support_agent_rounded,
            ),
          ),
        ],
      ),
    ],
  );
}

// Temporary placeholder screen
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
            Icon(icon, size: 72, color: AppColors.primary.withOpacity(0.3)),
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
