import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../router/route_names.dart';
import '../providers/advisory_provider.dart';
import '../widgets/advisory_form.dart';
import '../widgets/recommendation_card.dart';
import '../../../../shared/widgets/language_toggle.dart';

class AdvisoryScreen extends ConsumerWidget {
  const AdvisoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(advisoryProvider);
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // --- App Bar ---
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            expandedHeight: 120,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.go(RouteNames.home);
                }
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                isHindi
                    ? AppStrings.advisoryTitleHindi
                    : AppStrings.advisoryTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(color: AppColors.primary),
            ),
            actions: const [
              LanguageToggle(color: Colors.white),
              SizedBox(width: 8),
            ],
          ),

          // --- Body ---
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Subtitle
                Text(
                  isHindi
                      ? AppStrings.advisorySubtitleHindi
                      : AppStrings.advisorySubtitle,
                  style: AppTextStyles.body2,
                ),
                const SizedBox(height: 20),

                // Form
                const AdvisoryForm(),
                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    icon: state.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.agriculture_rounded, size: 22),
                    label: Text(
                      state.isLoading
                          ? (isHindi ? 'लोड हो रहा है...' : 'Loading...')
                          : (isHindi
                              ? AppStrings.getAdvisoryHindi
                              : AppStrings.getAdvisory),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    onPressed: state.isLoading
                        ? null
                        : () => ref
                            .read(advisoryProvider.notifier)
                            .fetchRecommendation(),
                  ),
                ),
                const SizedBox(height: 24),

                // Error
                if (state.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            state.error!,
                            style: AppTextStyles.body2
                                .copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Results header
                if (state.results.isNotEmpty) ...[
                  Text(
                    isHindi
                        ? AppStrings.advisoryResultsHindi
                        : AppStrings.advisoryResults,
                    style: AppTextStyles.headline3,
                  ),
                  const SizedBox(height: 12),
                  ...state.results.map(
                    (r) => RecommendationCard(
                      recommendation: r,
                      isHindi: isHindi,
                    ),
                  ),
                ],

                // Empty state
                if (state.results.isEmpty &&
                    !state.isLoading &&
                    state.error == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.eco_outlined,
                            size: 56,
                            color:
                                AppColors.primary.withValues(alpha: 0.25),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isHindi
                                ? AppStrings.noAdvisoryHindi
                                : AppStrings.noAdvisory,
                            style: AppTextStyles.body2,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
