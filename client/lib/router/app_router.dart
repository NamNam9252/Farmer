import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'route_names.dart';
import '../features/disease/presentation/screens/disease_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/auth/presentation/screens/otp_verification_screen.dart';
import '../features/onboarding/presentation/screens/location_setup_screen.dart';
import '../features/onboarding/presentation/screens/role_onboarding_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/state/auth_state.dart';
import '../shared/widgets/bottom_nav_bar.dart';
import '../core/theme/app_theme.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';

part 'app_router.g.dart';

// Create a provider for SharedPreferences to check onboarding status synchronously during routing
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authControllerProvider);
  final prefs = ref.watch(sharedPrefsProvider);
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

  return GoRouter(
    initialLocation: RouteNames.splash,
    redirect: (context, state) {
      final isAuth = authState is Authenticated;
      final isPendingVerification = authState is AuthPendingVerification;
      final isLoading = authState is AuthLoading || authState is AuthInitial;

      final isGoingToSplash = state.uri.path == RouteNames.splash;
      final isGoingToLogin = state.uri.path == RouteNames.login;
      final isGoingToSignup = state.uri.path == RouteNames.signup;
      final isGoingToOnboarding = state.uri.path == RouteNames.onboarding;
      final isGoingToOtp = state.uri.path == RouteNames.otpVerification;

      if (isLoading) {
        return isGoingToSplash ? null : RouteNames.splash;
      }

      if (isPendingVerification) {
        if (!isGoingToOtp) {
          return RouteNames.otpVerification;
        }
        return null;
      }

      if (!isAuth &&
          !isGoingToLogin &&
          !isGoingToSignup &&
          !isGoingToOnboarding &&
          !isGoingToOtp) {
        return hasSeenOnboarding ? RouteNames.login : RouteNames.onboarding;
      }

      if (authState is Authenticated) {
        if (isGoingToSplash ||
            isGoingToLogin ||
            isGoingToSignup ||
            isGoingToOnboarding ||
            isGoingToOtp) {
          return RouteNames.disease;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder:
            (context, state) => const Scaffold(
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
          if (location.startsWith(RouteNames.help)) currentIndex = 3;

          return AppBottomNavBar(currentIndex: currentIndex, child: child);
        },
        routes: [
          GoRoute(
            path: RouteNames.home,
            builder:
                (context, state) => const _PlaceholderScreen(
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
            builder:
                (context, state) => const _PlaceholderScreen(
                  title: 'बाज़ार',
                  subtitle: 'Marketplace - Coming Soon',
                  icon: Icons.storefront_rounded,
                ),
          ),
          GoRoute(
            path: RouteNames.help,
            builder:
                (context, state) => const _PlaceholderScreen(
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
