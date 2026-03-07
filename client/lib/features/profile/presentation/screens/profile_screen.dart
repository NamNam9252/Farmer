import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../router/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../../auth/domain/entities/user.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    String? name;
    String? roleLabel;

    if (authState is Authenticated) {
      name = authState.user.name;
      roleLabel = _mapRoleToLabel(authState.user.role);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('प्रोफ़ाइल'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                            name ?? 'Farmer User',
                            style: AppTextStyles.headline3,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            roleLabel ?? 'खाता सक्रिय',
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
            Text(
              'खाता',
              style: AppTextStyles.headline3,
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                    title: const Text('लॉग आउट'),
                    subtitle: const Text('इस डिवाइस से सुरक्षित रूप से साइन आउट करें'),
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
            Text(
              'Farmer One Stop Solution',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  String _mapRoleToLabel(UserRole role) {
    switch (role) {
      case UserRole.farmer:
        return 'किसान';
      case UserRole.buyer:
        return 'खरीदार';
      case UserRole.labor:
        return 'मज़दूर';
      case UserRole.expert:
        return 'विशेषज्ञ';
      case UserRole.admin:
        return 'एडमिन';
    }
  }
}

