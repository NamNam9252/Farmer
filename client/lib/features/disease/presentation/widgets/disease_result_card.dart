import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/disease_report.dart';
import 'buy_medicine_card.dart';

class DiseaseResultCard extends StatelessWidget {
  const DiseaseResultCard({
    super.key,
    required this.report,
    required this.isHindi,
    required this.onRetake,
  });

  final DiseaseReport report;
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
          color: _severityColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _severityColor.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (report.isOffline) _buildOfflineWarning(),
          _buildHeader(),
          _buildConfidenceBar(),
          const Divider(height: 1),
          _buildBody(context),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildOfflineWarning() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isHindi
                  ? "यह परिणाम सटीक नहीं हो सकता है। बेहतर विश्लेषण के लिए इंटरनेट से जुड़ें।"
                  : "This result may not be accurate. Connect to internet for better analysis.",
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.eco_rounded,
              size: 100,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              child: Center(
                child: Image.asset(
                  report.isHealthy 
                    ? 'assets/icons/ic_crop_advisory.png' // Repurposing as healthy
                    : 'assets/icons/ic_disease.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                ),
              ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHindi ? report.diseaseNameHindi : report.diseaseName,
                      style: AppTextStyles.headline2.copyWith(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isHindi ? report.diseaseNameHindi : report.diseaseName, // Subtitle/Hindi
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warning,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isHindi ? report.severity.labelHindi : report.severity.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (report.cropName.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(color: Colors.white54),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.grass_rounded, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  report.cropName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            isHindi ? AppStrings.confidenceHindi : AppStrings.confidence,
            style: const TextStyle(
              color: AppColors.textHint,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: report.confidenceScore,
              backgroundColor: AppColors.divider,
              color: AppColors.primary,
              minHeight: 6,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(report.confidenceScore * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDescriptionSection(),
          const Divider(height: 1),
          _buildTreatmentSection(),
          const Divider(height: 1),
          _buildPreventionSection(),
          if (report.productLinks.isNotEmpty) ...[
            const Divider(height: 1),
            _buildBuyMedicineSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                isHindi ? 'विवरण' : 'Description',
                style: AppTextStyles.headline3.copyWith(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isHindi ? report.descriptionHindi : report.description,
            style: AppTextStyles.body2.copyWith(height: 1.5, color: const Color(0xFF424242)),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentSection() {
    final items = isHindi ? report.treatmentsHindi : report.treatments;
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_services_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                isHindi ? AppStrings.treatmentHindi : AppStrings.treatment,
                style: AppTextStyles.headline3.copyWith(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: AppTextStyles.body2.copyWith(height: 1.5, color: const Color(0xFF424242)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPreventionSection() {
    final items = isHindi ? report.preventionsHindi : report.preventions;
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                isHindi ? AppStrings.preventionHindi : AppStrings.prevention,
                style: AppTextStyles.headline3.copyWith(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.primaryLight,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTextStyles.body2.copyWith(height: 1.5, color: const Color(0xFF424242)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBuyMedicineSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront_rounded, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                isHindi ? 'दवा खरीदें' : 'Buy Medicine',
                style: AppTextStyles.headline3.copyWith(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isHindi ? 'सबसे सस्ते किसान-अनुकूल मूल्य' : 'Cheapest farmer-friendly prices',
            style: const TextStyle(color: AppColors.textHint, fontSize: 12),
          ),
          const SizedBox(height: 12),
          BuyMedicineCard(
            productLinks: report.productLinks,
            isHindi: isHindi,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onRetake,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            isHindi ? AppStrings.retakeHindi : 'Scan Again',
            style: AppTextStyles.button.copyWith(fontSize: 15),
          ),
        ),
      ),
    );
  }
}
