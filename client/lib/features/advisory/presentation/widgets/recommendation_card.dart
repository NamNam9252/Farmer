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
        return recommendation.stage.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _riskColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Accent Bar
            Container(
              height: 6,
              width: double.infinity,
              color: color,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildRiskBadge(color),
                      _buildStageChip(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    recommendation.action,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          recommendation.reason,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskBadge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_riskIcon(), size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            _riskLabel(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _stageLabel(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF2E7D32),
        ),
      ),
    );
  }
}
