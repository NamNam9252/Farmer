import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../router/route_names.dart';
import '../providers/advisory_provider.dart';
import '../widgets/advisory_form.dart';
import '../widgets/recommendation_card.dart';
import '../../../../shared/widgets/shared_app_bar.dart';

class AdvisoryScreen extends ConsumerWidget {
  const AdvisoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(advisoryProvider);
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context, isHindi),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),
                Text(
                  isHindi
                      ? AppStrings.advisorySubtitleHindi
                      : AppStrings.advisorySubtitle,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                
                const AdvisoryForm(),
                const SizedBox(height: 32),

                _buildSubmitButton(ref, state, isHindi),
                const SizedBox(height: 24),

                if (state.error != null) _buildErrorCard(state.error!),

                if (state.results.isNotEmpty) ...[
                  _buildResultsHeader(isHindi),
                  const SizedBox(height: 12),
                  ...state.results.map(
                    (r) => RecommendationCard(
                      recommendation: r,
                      isHindi: isHindi,
                    ),
                  ),
                  const SizedBox(height: 120),
                ] else if (!state.isLoading && state.error == null)
                  _buildEmptyState(isHindi),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isHindi) {
    return SharedStickyHeader(
      title: isHindi ? AppStrings.advisoryTitleHindi : AppStrings.advisoryTitle,
      subtitle: isHindi 
          ? 'आपकी खेती की जरूरतों के लिए विशेषज्ञ सलाह' 
          : 'Expert advice for your farming needs',
      backgroundImage: 'assets/images/service_icons/crop_advisory.png',
      showBackButton: true,
      onBack: () => context.pop(),
    );
  }

  Widget _buildSubmitButton(WidgetRef ref, AdvisoryState state, bool isHindi) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: state.isLoading
            ? null
            : () => ref.read(advisoryProvider.notifier).fetchRecommendation(),
        icon: state.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
        label: Text(
          state.isLoading
              ? (isHindi ? 'जारी है...' : 'Processing...')
              : (isHindi ? AppStrings.getAdvisoryHindi : AppStrings.getAdvisory),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_rounded, color: AppColors.error, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader(bool isHindi) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isHindi ? AppStrings.advisoryResultsHindi : AppStrings.advisoryResults,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isHindi) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20),
                ],
              ),
              child: SvgPicture.string(AppIcons.advisory, width: 80, height: 80),
            ),
            const SizedBox(height: 24),
            Text(
              isHindi ? AppStrings.noAdvisoryHindi : AppStrings.noAdvisory,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
