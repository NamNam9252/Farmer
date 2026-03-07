import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../router/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../../auth/domain/entities/user.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    String? name;
    String? roleLabel;

    if (authState is Authenticated) {
      name = authState.user.name;
      roleLabel = _mapRoleToLabel(authState.user.role, isHindi);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isHindi ? 'प्रोफ़ाइल' : 'Profile'),
        actions: [
          // Language Toggle
          GestureDetector(
            onTap: () {
              ref.read(languageProvider.notifier).state =
                  lang == 'hi' ? 'en' : 'hi';
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white38),
              ),
              child: Text(
                lang == 'hi' ? 'EN' : 'हि',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile info card
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name ?? (isHindi ? 'किसान उपयोगकर्ता' : 'Farmer User'),
                            style: AppTextStyles.headline3,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            roleLabel ?? (isHindi ? 'खाता सक्रिय' : 'Account Active'),
                            style: AppTextStyles.body2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Account section
            Text(
              isHindi ? 'खाता' : 'Account',
              style: AppTextStyles.headline3,
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                    title: Text(isHindi ? 'लॉग आउट' : 'Logout'),
                    subtitle: Text(
                      isHindi
                          ? 'इस डिवाइस से सुरक्षित रूप से साइन आउट करें'
                          : 'Sign out safely from this device',
                    ),
                    onTap: () async {
                      await ref.read(authControllerProvider.notifier).logout();
                      if (context.mounted) {
                        context.go(RouteNames.login);
                      }
                    },
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Prominent Logout Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.logout_rounded, size: 22),
              label: Text(
                isHindi ? 'लॉग आउट करें' : 'Logout Now',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(isHindi ? 'लॉग आउट' : 'Logout'),
                    content: Text(
                      isHindi
                          ? 'क्या आप वाकई लॉग आउट करना चाहते हैं?'
                          : 'Are you sure you want to logout?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(isHindi ? 'नहीं' : 'No'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(isHindi ? 'हाँ, लॉग आउट' : 'Yes, Logout'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) {
                    context.go(RouteNames.login);
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Farmer One Stop Solution',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  String _mapRoleToLabel(UserRole role, bool isHindi) {
    switch (role) {
      case UserRole.farmer:
        return isHindi ? 'किसान' : 'Farmer';
      case UserRole.buyer:
        return isHindi ? 'खरीदार' : 'Buyer';
      case UserRole.labor:
        return isHindi ? 'मज़दूर' : 'Labor';
      case UserRole.expert:
        return isHindi ? 'विशेषज्ञ' : 'Expert';
      case UserRole.admin:
        return isHindi ? 'एडमिन' : 'Admin';
    }
  }
}
