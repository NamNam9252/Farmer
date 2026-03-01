import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_strings.dart';
import '../../data/models/disease_report_model.dart';
import '../widgets/buy_medicine_card.dart';

class DiseaseDetailScreen extends StatelessWidget {
  const DiseaseDetailScreen({
    super.key,
    required this.report,
    required this.isHindi,
  });

  final DiseaseReportModel report;
  final bool isHindi;

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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeroImage(),
            ),
            title: Text(
              isHindi ? AppStrings.diseaseFoundHindi : AppStrings.diseaseFound,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildDescriptionCard(),
                  const SizedBox(height: 16),
                  _buildTreatmentCard(),
                  const SizedBox(height: 16),
                  _buildPreventionCard(),
                  const SizedBox(height: 16),
                  if (report.productLinks.isNotEmpty)
                    BuyMedicineCard(
                      productLinks: report.productLinks,
                      isHindi: isHindi,
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        report.imagePath.isNotEmpty
            ? Image.file(
                File(report.imagePath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.surface,
                  child: const Icon(Icons.image_not_supported, size: 64, color: AppColors.textHint),
                ),
              )
            : Container(color: AppColors.surface),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _severityColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isHindi
                      ? report.severity.labelHindi
                      : report.severity.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (report.cropName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white38),
                  ),
                  child: Text(
                    report.cropName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: report.isHealthy
            ? AppColors.diseaseNone.withOpacity(0.08)
            : _severityColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: report.isHealthy
              ? AppColors.diseaseNone.withOpacity(0.3)
              : _severityColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: report.isHealthy ? AppColors.diseaseNone : _severityColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              report.isHealthy ? Icons.check_circle_rounded : Icons.warning_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHindi ? report.diseaseNameHindi : report.diseaseName,
                  style: AppTextStyles.headline3.copyWith(
                    color: report.isHealthy ? AppColors.diseaseNone : _severityColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${isHindi ? AppStrings.confidenceHindi : AppStrings.confidence}: ',
                      style: AppTextStyles.caption,
                    ),
                    Text(
                      '${(report.confidenceScore * 100).toStringAsFixed(0)}%',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return _InfoCard(
      icon: Icons.info_outline_rounded,
      title: isHindi ? 'विवरण' : 'Description',
      child: Text(
        isHindi ? report.descriptionHindi : report.description,
        style: AppTextStyles.body2.copyWith(height: 1.6),
      ),
    );
  }

  Widget _buildTreatmentCard() {
    final items = isHindi ? report.treatmentsHindi : report.treatments;
    if (items.isEmpty) return const SizedBox.shrink();

    return _InfoCard(
      icon: Icons.medical_services_outlined,
      iconColor: AppColors.primary,
      title: isHindi ? AppStrings.treatmentHindi : AppStrings.treatment,
      child: Column(
        children: items.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.value,
                    style: AppTextStyles.body2.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPreventionCard() {
    final items = isHindi ? report.preventionsHindi : report.preventions;
    if (items.isEmpty) return const SizedBox.shrink();

    return _InfoCard(
      icon: Icons.shield_outlined,
      iconColor: AppColors.accent,
      title: isHindi ? AppStrings.preventionHindi : AppStrings.prevention,
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    color: AppColors.primaryLight, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: AppTextStyles.body2.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.child,
    this.iconColor = AppColors.primary,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.headline3.copyWith(fontSize: 16),
              ),
            ],
          ),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }
}
