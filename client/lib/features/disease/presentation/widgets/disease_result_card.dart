import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_strings.dart';
import '../../data/models/disease_report_model.dart';
import '../screens/disease_detail_screen.dart';

class DiseaseResultCard extends StatelessWidget {
  const DiseaseResultCard({
    super.key,
    required this.report,
    required this.isHindi,
    required this.onRetake,
  });

  final DiseaseReportModel report;
  final bool isHindi;
  final VoidCallback onRetake;

  Color get _severityColor {
    switch (report.severity) {
      case DiseaseSeverity.high:
        return AppColors.diseaseHigh;
      case DiseaseSeverity.medium:
        return AppColors.diseaseMedium;
      case DiseaseSeverity.low:
        return AppColors.diseaseLow;
      case DiseaseSeverity.none:
        return AppColors.diseaseNone;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _severityColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _severityColor.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const Divider(height: 1),
          _buildBody(context),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _severityColor.withOpacity(0.06),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _severityColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              report.isHealthy ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHindi ? report.diseaseNameHindi : report.diseaseName,
                  style: AppTextStyles.headline3.copyWith(
                    color: _severityColor,
                    fontSize: 17,
                  ),
                ),
                if (report.cropName.isNotEmpty)
                  Text(
                    report.cropName,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          // Confidence badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  '${(report.confidenceScore * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  isHindi ? 'सटीक' : 'sure',
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Severity row
          Row(
            children: [
              _InfoChip(
                icon: Icons.bar_chart_rounded,
                label: isHindi ? AppStrings.severityHindi : AppStrings.severity,
                value: isHindi
                    ? report.severity.labelHindi
                    : report.severity.label,
                color: _severityColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Description snippet
          Text(
            isHindi ? report.descriptionHindi : report.description,
            style: AppTextStyles.body2.copyWith(height: 1.5),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if ((isHindi ? report.treatmentsHindi : report.treatments).isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              isHindi ? '💊 ${AppStrings.treatmentHindi}:' : '💊 ${AppStrings.treatment}:',
              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ...(isHindi ? report.treatmentsHindi : report.treatments)
                .take(2)
                .map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                          Expanded(
                            child: Text(t, style: AppTextStyles.body2),
                          ),
                        ],
                      ),
                    )),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onRetake,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(isHindi ? AppStrings.retakeHindi : AppStrings.retake),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DiseaseDetailScreen(
                    report: report,
                    isHindi: isHindi,
                  ),
                ),
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(isHindi ? AppStrings.viewDetailsHindi : AppStrings.viewDetails),
              style: ElevatedButton.styleFrom(
                backgroundColor: _severityColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
