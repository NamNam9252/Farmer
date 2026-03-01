import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';
import '../features/disease/presentation/screens/disease_screen.dart';
import '../shared/widgets/bottom_nav_bar.dart';
import '../core/theme/app_theme.dart';

final appRouter = GoRouter(
  initialLocation: RouteNames.disease,
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        final location = state.uri.path;
        int currentIndex = 0;
        if (location.startsWith(RouteNames.disease)) currentIndex = 1;
        if (location.startsWith(RouteNames.market)) currentIndex = 2;
        if (location.startsWith(RouteNames.help)) currentIndex = 3;

        // Detail screens don't show the shell
        // if (location == RouteNames.diseaseDetail) return child;

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
