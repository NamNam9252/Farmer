import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_icons.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    final tabs = [
      _NavTab(
        path: '/',
        labelEn: 'Home',
        labelHi: 'होम',
        activeSvg: AppIcons.navHome(active: true),
        inactiveSvg: AppIcons.navHome(active: false),
      ),
      _NavTab(
        path: '/disease',
        labelEn: 'Disease',
        labelHi: 'रोग',
        activeSvg: AppIcons.navDisease(active: true),
        inactiveSvg: AppIcons.navDisease(active: false),
      ),
      _NavTab(
        path: '/market',
        labelEn: 'Market',
        labelHi: 'बाज़ार',
        activeSvg: AppIcons.navMarket(active: true),
        inactiveSvg: AppIcons.navMarket(active: false),
      ),
      _NavTab(
        path: '/profile',
        labelEn: 'Profile',
        labelHi: 'प्रोफ़ाइल',
        activeSvg: AppIcons.navProfile(active: true),
        inactiveSvg: AppIcons.navProfile(active: false),
      ),
    ];

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: tabs.asMap().entries.map((entry) {
                final idx = entry.key;
                final tab = entry.value;
                final isSelected = idx == currentIndex;
                final label = isHindi ? tab.labelHi : tab.labelEn;

                return GestureDetector(
                  onTap: () => context.go(tab.path),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: SvgPicture.string(
                            isSelected
                                ? tab.activeSvg
                                : tab.inactiveSvg,
                            key: ValueKey(isSelected),
                            width: 26,
                            height: 26,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 220),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textHint,
                            letterSpacing: 0.1,
                          ),
                          child: Text(label),
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

class _NavTab {
  const _NavTab({
    required this.path,
    required this.labelEn,
    required this.labelHi,
    required this.activeSvg,
    required this.inactiveSvg,
  });

  final String path;
  final String labelEn;
  final String labelHi;
  final String activeSvg;
  final String inactiveSvg;
}
