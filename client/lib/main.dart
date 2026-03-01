import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/disease/presentation/screens/disease_screen.dart';
import 'shared/widgets/bottom_nav_bar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: KisanSaathiApp()));
}

final _router = GoRouter(
  initialLocation: '/disease',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        final location = state.uri.path;
        int currentIndex = 0;
        if (location.startsWith('/disease')) currentIndex = 1;
        if (location.startsWith('/market')) currentIndex = 2;
        if (location.startsWith('/help')) currentIndex = 3;

        // Detail screens don't show the shell
        if (location == '/disease/detail') return child;

        return AppBottomNavBar(currentIndex: currentIndex, child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const _PlaceholderScreen(
            title: 'होम',
            subtitle: 'Home - Coming Soon',
            icon: Icons.home_rounded,
          ),
        ),
        GoRoute(
          path: '/disease',
          builder: (context, state) => const DiseaseScreen(),
        ),
        GoRoute(
          path: '/market',
          builder: (context, state) => const _PlaceholderScreen(
            title: 'बाज़ार',
            subtitle: 'Marketplace - Coming Soon',
            icon: Icons.storefront_rounded,
          ),
        ),
        GoRoute(
          path: '/help',
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

class KisanSaathiApp extends StatelessWidget {
  const KisanSaathiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Kisan Saathi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
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
