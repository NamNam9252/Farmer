import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  final int currentIndex;
  final Widget child;

  static const List<({String path, IconData icon, IconData activeIcon, String label, String labelHindi})> _tabs = [
    (
      path: '/',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
      labelHindi: 'होम',
    ),
    (
      path: '/disease',
      icon: Icons.biotech_outlined,
      activeIcon: Icons.biotech_rounded,
      label: 'Disease',
      labelHindi: 'रोग',
    ),
    (
      path: '/market',
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront_rounded,
      label: 'Market',
      labelHindi: 'बाज़ार',
    ),
    (
      path: '/help',
      icon: Icons.support_agent_outlined,
      activeIcon: Icons.support_agent_rounded,
      label: 'Help',
      labelHindi: 'मदद',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
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
              children: _tabs.asMap().entries.map((entry) {
                final idx = entry.key;
                final tab = entry.value;
                final isSelected = idx == currentIndex;

                return GestureDetector(
                  onTap: () => context.go(tab.path),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? tab.activeIcon : tab.icon,
                          color: isSelected ? AppColors.primary : AppColors.textHint,
                          size: 24,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.labelHindi,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textHint,
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
