import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/crop_recommendation_provider.dart';

class CropRecommendationScreen extends ConsumerWidget {
  const CropRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cropRecommendationProvider);
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isHindi ? 'फसल सिफारिश' : 'Crop Recommendation'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isHindi ? 'सही फसल चुनें, अधिक मुनाफा कमाएं' : 'Choose the best crop, maximize profit',
                style: AppTextStyles.headline3,
              ),
              const SizedBox(height: 16),
              
              // Filter Inputs
              _buildFilters(context, ref, state, isHindi),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: state.isLoading ? null : () {
                  ref.read(cropRecommendationProvider.notifier).getRecommendation();
                },
                icon: state.isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.analytics_rounded),
                label: Text(isHindi ? 'सिफारिश प्राप्त करें' : 'Get Recommendation'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
              ),
              const SizedBox(height: 24),

              // Results Section
              if (state.error != null)
                _buildError(context, ref, state.error!, isHindi)
              else if (state.report != null)
                _buildReport(context, state.report!, isHindi)
              else if (!state.isLoading)
                _buildEmptyState(isHindi),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context, WidgetRef ref, state, bool isHindi) {
    final crops = AppConstants.indianCrops.take(10).toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isHindi ? 'पसंदीदा फसलें (वैकल्पिक)' : 'Preferred Crops (Optional)', style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: crops.map((cropLabel) {
              final cropValue = cropLabel.split(' (').first; // 'Wheat (गेहूं)' -> 'Wheat'
              final displayKey = isHindi ? cropLabel.split('(').last.replaceAll(')', '') : cropValue;
              final isSelected = state.preferredCrops.contains(cropValue);
              
              return FilterChip(
                label: Text(displayKey, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.textPrimary)),
                selected: isSelected,
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                onSelected: (_) {
                  ref.read(cropRecommendationProvider.notifier).togglePreferredCrop(cropValue);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isHindi) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.psychology_alt_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            isHindi 
                ? 'सिफारिश के लिए "प्राप्त करें" पर टैप करें।\nAI आपकी मिट्टी और बाजार का विश्लेषण करेगा।' 
                : 'Tap to get started.\nAI will analyze your local soil and market trends.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body2,
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error, bool isHindi) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          Text(error, textAlign: TextAlign.center, style: AppTextStyles.body2),
        ],
      ),
    );
  }

  Widget _buildReport(BuildContext context, dynamic report, bool isHindi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location & Soil Info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFDFF0FA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('\${report.district}, \${report.state}', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.landscape, color: Colors.brown, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isHindi ? 'मिट्टी: \${report.soilTypeHindi}' : 'Soil: \${report.soilType}',
                      style: AppTextStyles.body2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          isHindi ? 'शीर्ष सिफारिशें' : 'Top Recommendations',
          style: AppTextStyles.headline3,
        ),
        const SizedBox(height: 12),
        ...report.recommendations.map((crop) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildCropCard(crop, isHindi),
        )),
      ],
    );
  }

  Widget _buildCropCard(dynamic crop, bool isHindi) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text('#\${crop.rank}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHindi ? crop.cropHindi : crop.crop,
                      style: AppTextStyles.headline3,
                    ),
                    Text(
                      isHindi ? 'बाज़ार भाव: \${crop.currentMarketPrice}' : 'Market Price: \${crop.currentMarketPrice}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: crop.demandLevel == 'High' ? AppColors.success.withValues(alpha: 0.1) : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: crop.demandLevel == 'High' ? AppColors.success : AppColors.divider),
                ),
                child: Text(
                  '\${isHindi ? "मांग" : "Demand"}: \${crop.demandLevel}',
                  style: AppTextStyles.label.copyWith(
                      fontSize: 11, 
                      fontWeight: FontWeight.bold, 
                      color: crop.demandLevel == 'High' ? AppColors.success : AppColors.textPrimary
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isHindi ? crop.reasonHindi : crop.reason,
            style: AppTextStyles.body2,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildSmallStat(isHindi ? 'लागत' : 'Cost', crop.estimatedCostPerAcre, Colors.redAccent)),
              Container(width: 1, height: 40, color: AppColors.divider),
              Expanded(child: _buildSmallStat(isHindi ? 'आय' : 'Revenue', crop.estimatedRevenuePerAcre, Colors.blueAccent)),
              Container(width: 1, height: 40, color: AppColors.divider),
              Expanded(child: _buildSmallStat(isHindi ? 'मुनाफा' : 'Profit', crop.estimatedProfitPerAcre, AppColors.success)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        Text(
          value.split('-').first, // Show lower bound of range to fit nicely
          style: AppTextStyles.label.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
