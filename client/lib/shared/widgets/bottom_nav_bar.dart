import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/language_provider.dart';

class AppBottomNavBar extends ConsumerWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  final int currentIndex;
  final Widget child;

  static const List<
    ({
      String path,
      IconData icon,
      IconData activeIcon,
      String labelEn,
      String labelHi,
    })
  >
  _tabs = [
    (
      path: '/',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      labelEn: 'HOME',
      labelHi: 'होम',
    ),
    (
      path: '/disease',
      icon: Icons.eco_outlined,
      activeIcon: Icons.eco_rounded,
      labelEn: 'DISEASE',
      labelHi: 'रोग',
    ),
    (
      path: '/market',
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront_rounded,
      labelEn: 'MARKET',
      labelHi: 'बाज़ार',
    ),
    (
      path: '/profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      labelEn: 'PROFILE',
      labelHi: 'प्रोफ़ाइल',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children:
                  _tabs.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final tab = entry.value;
                    final isSelected = idx == currentIndex;
                    final label = isHindi ? tab.labelHi : tab.labelEn;

                    return GestureDetector(
                      onTap: () => context.go(tab.path),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? tab.activeIcon : tab.icon,
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : AppColors.textHint,
                              size: 24,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                color:
                                    isSelected
                                        ? AppColors.primary
                                        : AppColors.textHint,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
