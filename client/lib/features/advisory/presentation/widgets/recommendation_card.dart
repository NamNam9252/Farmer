import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/recommendation.dart';

/// Card widget showing a single advisory recommendation.
class RecommendationCard extends StatelessWidget {
  const RecommendationCard({
    super.key,
    required this.recommendation,
    required this.isHindi,
  });

  final Recommendation recommendation;
  final bool isHindi;

  Color _riskColor() {
    switch (recommendation.riskLevel) {
      case 'High':
        return AppColors.error;
      case 'Medium':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  String _riskLabel() {
    switch (recommendation.riskLevel) {
      case 'High':
        return isHindi ? AppStrings.riskHighHindi : AppStrings.riskHigh;
      case 'Medium':
        return isHindi ? AppStrings.riskMediumHindi : AppStrings.riskMedium;
      default:
        return isHindi ? AppStrings.riskLowHindi : AppStrings.riskLow;
    }
  }

  IconData _riskIcon() {
    switch (recommendation.riskLevel) {
      case 'High':
        return Icons.warning_rounded;
      case 'Medium':
        return Icons.info_outline_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  String _stageLabel() {
    if (!isHindi) return recommendation.stage.toUpperCase();
    switch (recommendation.stage) {
      case 'germination':
        return 'अंकुरण';
      case 'vegetative':
        return 'वानस्पतिक';
      case 'flowering':
        return 'फूल';
      case 'fruiting':
        return 'फलन';
      default:
        return recommendation.stage;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _riskColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: risk badge + stage
            Row(
              children: [
                // Risk badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_riskIcon(), size: 14, color: color),
                      const SizedBox(width: 4),
                      Text(
                        _riskLabel(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Stage chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _stageLabel(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action
            Text(
              recommendation.action,
              style: AppTextStyles.body1.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),

            // Reason
            Text(
              recommendation.reason,
              style: AppTextStyles.body2.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
