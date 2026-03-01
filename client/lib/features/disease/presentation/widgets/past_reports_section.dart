import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_strings.dart';
import '../../data/models/disease_report_model.dart';
import '../providers/disease_provider.dart';
import '../screens/disease_detail_screen.dart';

class PastReportsSection extends ConsumerWidget {
  const PastReportsSection({super.key, required this.isHindi});

  final bool isHindi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(pastReportsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              isHindi ? AppStrings.pastReportsHindi : AppStrings.pastReports,
              style: AppTextStyles.headline3,
            ),
          ],
        ),
        const SizedBox(height: 14),
        reportsAsync.when(
          data: (reports) {
            if (reports.isEmpty) {
              return _EmptyReports(isHindi: isHindi);
            }
            return Column(
              children: reports
                  .take(5)
                  .map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ReportTile(
                          report: r,
                          isHindi: isHindi,
                        ),
                      ))
                  .toList(),
            );
          },
          loading: () => Column(
            children: List.generate(
              3,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: _ReportTileSkeleton(),
              ),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _EmptyReports extends StatelessWidget {
  const _EmptyReports({required this.isHindi});

  final bool isHindi;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.folder_open_rounded, size: 40, color: AppColors.textHint),
          const SizedBox(height: 8),
          Text(
            isHindi ? AppStrings.noReportsHindi : AppStrings.noReports,
            style: AppTextStyles.body2,
          ),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report, required this.isHindi});

  final DiseaseReportModel report;
  final bool isHindi;

  Color get _color {
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

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return isHindi ? AppStrings.todayHindi : AppStrings.today;
    if (diff.inDays == 1) return isHindi ? AppStrings.yesterdayHindi : AppStrings.yesterday;
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: AppColors.primary.withOpacity(0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DiseaseDetailScreen(report: report, isHindi: isHindi),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: report.imagePath.isNotEmpty
                      ? Image.file(
                          File(report.imagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.surface,
                            child: const Icon(Icons.image_not_supported,
                                color: AppColors.textHint),
                          ),
                        )
                      : Container(
                          color: AppColors.surface,
                          child: const Icon(Icons.eco_rounded,
                              color: AppColors.primary, size: 24),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHindi ? report.diseaseNameHindi : report.diseaseName,
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    if (report.cropName.isNotEmpty)
                      Text(
                        report.cropName,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isHindi
                                ? report.severity.labelHindi
                                : report.severity.label,
                            style: TextStyle(
                              fontSize: 11,
                              color: _color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDate(report.createdAt),
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(report.confidenceScore * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textHint, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportTileSkeleton extends StatelessWidget {
  const _ReportTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
