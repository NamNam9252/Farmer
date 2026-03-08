import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/language_provider.dart';
import '../providers/crop_recommendation_provider.dart';
import '../../domain/entities/crop_recommendation.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/crop_picker_sheet.dart';
import '../../../../shared/widgets/language_toggle.dart';

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
        title: const SizedBox.shrink(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
        actions: const [
          LanguageToggle(color: Colors.white),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero banner
              _buildHeroBanner(isHindi),
              const SizedBox(height: 16),

              // Filter Inputs
              _buildFilters(context, ref, state, isHindi),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () {
                        ref
                            .read(cropRecommendationProvider.notifier)
                            .getRecommendation();
                      },
                icon: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(
                    isHindi ? 'AI सिफारिश प्राप्त करें' : 'Get AI Recommendation'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 24),

              // Results Section
              if (state.error != null)
                _buildError(state.error!, isHindi)
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

  Widget _buildHeroBanner(bool isHindi) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHindi ? '🌾 AI फसल सलाहकार' : '🌾 AI Crop Recommendation',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isHindi
                      ? 'मिट्टी, मौसम और बाज़ार के आधार पर सर्वोत्तम फसल चुनें'
                      : 'Best crop by your soil, weather & market data',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.agriculture_rounded,
                color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(
      BuildContext context, WidgetRef ref, state, bool isHindi) {
    final selectedCrops = state.preferredCrops as List<String>;

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
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isHindi
                      ? 'पसंदीदा फसलें (वैकल्पिक)'
                      : 'Preferred Crops (Optional)',
                  style:
                      AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (selectedCrops.isNotEmpty)
                Text(
                  '${selectedCrops.length} ${isHindi ? "चयनित" : "selected"}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Selected crops preview
          if (selectedCrops.isNotEmpty) ...[
            SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: selectedCrops.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final cropId = selectedCrops[i];
                  final crop = CropCatalog.getById(cropId);
                  final emoji = crop?.emoji ?? '🌱';
                  final bgColor = crop?.bgColor ?? AppColors.surface;
                  final label = crop != null
                      ? (isHindi ? crop.nameHi : crop.nameEn)
                      : cropId;

                  return GestureDetector(
                    onTap: () {
                      ref
                          .read(cropRecommendationProvider.notifier)
                          .togglePreferredCrop(cropId);
                    },
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: bgColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.primary, width: 2),
                              ),
                              child: Center(
                                child: Text(emoji,
                                    style: const TextStyle(fontSize: 28)),
                              ),
                            ),
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 60,
                          child: Text(
                            label,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Open Crop Picker button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await showCropPickerSheet(
                  context: context,
                  isHindi: isHindi,
                  multiSelect: true,
                  maxSelection: 8,
                  initialSelected: selectedCrops,
                );
                if (result != null) {
                  // Clear old, set new
                  final notifier = ref.read(cropRecommendationProvider.notifier);
                  // Remove all existing
                  for (final old in List<String>.from(selectedCrops)) {
                    notifier.togglePreferredCrop(old);
                  }
                  // Add all newly selected
                  for (final crop in result) {
                    notifier.togglePreferredCrop(crop);
                  }
                }
              },
              icon: const Icon(Icons.grid_view_rounded, size: 18),
              label: Text(
                isHindi ? 'फसलें चुनें' : 'Choose Crops',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.4)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isHindi) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology_alt_outlined,
                size: 56, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            isHindi
                ? 'AI विश्लेषण के लिए ऊपर बटन दबाएं'
                : 'Tap the button above to start',
            style: AppTextStyles.headline3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isHindi
                ? 'AI आपकी मिट्टी, मौसम और बाज़ार का विश्लेषण करेगा\nऔर सर्वोत्तम फसल सुझाएगा।'
                : 'AI will analyse your local soil, weather\nand market trends to suggest the best crop.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body2,
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error, bool isHindi) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 44),
          const SizedBox(height: 12),
          Text(
            isHindi ? 'कुछ गड़बड़ हुई' : 'Something went wrong',
            style: AppTextStyles.headline3.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: 6),
          Text(error, textAlign: TextAlign.center, style: AppTextStyles.body2),
        ],
      ),
    );
  }

  Widget _buildReport(
      BuildContext context, CropRecommendationReport report, bool isHindi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location + Soil Card
        _buildLocationSoilCard(report, isHindi),
        const SizedBox(height: 12),

        // Weather row
        _buildWeatherRow(report, isHindi),
        const SizedBox(height: 24),

        // Section title
        Row(
          children: [
            const Icon(Icons.emoji_events_rounded,
                color: AppColors.accent, size: 22),
            const SizedBox(width: 8),
            Text(
              isHindi ? 'शीर्ष फसल सिफारिशें' : 'Top Crop Recommendations',
              style: AppTextStyles.headline2,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          isHindi
              ? 'आपकी मिट्टी और मौसम के लिए सबसे उपयुक्त फसलें'
              : 'Best suited crops for your soil and season',
          style: AppTextStyles.body2,
        ),
        const SizedBox(height: 16),

        // Crop Cards
        ...report.recommendations.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _CropCard(crop: entry.value, isHindi: isHindi),
          );
        }),

        // Summary Card
        _buildSummaryCard(report, isHindi),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildLocationSoilCard(
      CropRecommendationReport report, bool isHindi) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFDFF0FA),
            const Color(0xFFE8F5E9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${report.district}, ${report.state}',
                      style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.landscape_rounded,
                        color: Color(0xFF795548), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isHindi
                            ? '${isHindi ? "मिट्टी" : "Soil"}: ${report.soilTypeHindi}'
                            : 'Soil: ${report.soilType}',
                        style: AppTextStyles.body2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Text(
              report.currentSeason.split('/').first.trim(),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherRow(CropRecommendationReport report, bool isHindi) {
    return Row(
      children: [
        _WeatherChip(
          icon: Icons.thermostat_rounded,
          iconColor: const Color(0xFFE53935),
          label: '${report.temperature.round()}°C',
          sublabel: isHindi ? 'तापमान' : 'Temp',
        ),
        const SizedBox(width: 10),
        _WeatherChip(
          icon: Icons.water_drop_rounded,
          iconColor: const Color(0xFF1E88E5),
          label: '${report.humidity.round()}%',
          sublabel: isHindi ? 'नमी' : 'Humidity',
        ),
        const SizedBox(width: 10),
        _WeatherChip(
          icon: Icons.grain_rounded,
          iconColor: const Color(0xFF42A5F5),
          label: '${report.rainProbability.round()}%',
          sublabel: isHindi ? 'बारिश' : 'Rain',
        ),
      ],
    );
  }

  Widget _buildSummaryCard(CropRecommendationReport report, bool isHindi) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.summarize_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                isHindi ? 'AI सारांश' : 'AI Summary',
                style: AppTextStyles.label.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isHindi ? report.summaryHindi : report.summary,
            style: AppTextStyles.body2.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─── Crop Card ───────────────────────────────────────────────────────────────

class _CropCard extends StatelessWidget {
  const _CropCard({required this.crop, required this.isHindi});

  final CropRecommendation crop;
  final bool isHindi;

  // Returns a themed gradient + icon for each crop
  static const _cropVisuals = <String, Map<String, dynamic>>{
    'Watermelon': {
      'colors': [Color(0xFF81C784), Color(0xFF4CAF50)],
      'emoji': '🍉',
    },
    'Cucumber': {
      'colors': [Color(0xFF80CBC4), Color(0xFF26A69A)],
      'emoji': '🥒',
    },
    'Bitter Gourd': {
      'colors': [Color(0xFFA5D6A7), Color(0xFF388E3C)],
      'emoji': '🌿',
    },
    'Moong': {
      'colors': [Color(0xFFC5E1A5), Color(0xFF7CB342)],
      'emoji': '🫛',
    },
    'Guar': {
      'colors': [Color(0xFFFFCC80), Color(0xFFF57C00)],
      'emoji': '🌱',
    },
    'Wheat': {
      'colors': [Color(0xFFFFD54F), Color(0xFFF9A825)],
      'emoji': '🌾',
    },
    'Rice': {
      'colors': [Color(0xFFFFF9C4), Color(0xFFF9A825)],
      'emoji': '🍚',
    },
    'Mustard': {
      'colors': [Color(0xFFFFF176), Color(0xFFFDD835)],
      'emoji': '🌻',
    },
    'Tomato': {
      'colors': [Color(0xFFEF9A9A), Color(0xFFE53935)],
      'emoji': '🍅',
    },
    'Onion': {
      'colors': [Color(0xFFCE93D8), Color(0xFF8E24AA)],
      'emoji': '🧅',
    },
  };

  static Map<String, dynamic> _getVisual(String cropName) {
    return _cropVisuals[cropName] ??
        {
          'colors': [const Color(0xFF80CBC4), const Color(0xFF00897B)],
          'emoji': '🌱',
        };
  }

  Color _riskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'low':
        return AppColors.success;
      case 'high':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  String _riskLabel(String risk, bool isHindi) {
    if (isHindi) {
      switch (risk.toLowerCase()) {
        case 'low':
          return 'कम जोखिम';
        case 'high':
          return 'अधिक जोखिम';
        default:
          return 'मध्यम जोखिम';
      }
    }
    return '$risk Risk';
  }

  Color _demandColor(String demand) {
    switch (demand.toLowerCase()) {
      case 'high':
        return AppColors.success;
      case 'low':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  String _demandLabel(String demand, bool isHindi) {
    if (isHindi) {
      switch (demand.toLowerCase()) {
        case 'high':
          return 'उच्च मांग';
        case 'low':
          return 'कम मांग';
        default:
          return 'मध्यम मांग';
      }
    }
    return '$demand Demand';
  }

  @override
  Widget build(BuildContext context) {
    final visual = _getVisual(crop.crop);
    final gradColors = visual['colors'] as List<Color>;
    final emoji = visual['emoji'] as String;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.08), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image Placeholder ──────────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
            ),
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Rank badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '#${crop.rank}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  // Demand badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _demandColor(crop.demandLevel),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _demandLabel(crop.demandLevel, isHindi),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Crop emoji / image placeholder
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 52)),
                        const SizedBox(height: 4),
                        Text(
                          isHindi ? crop.cropHindi : crop.crop,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 8,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Card Body ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Market price + Risk badge row
                Row(
                  children: [
                    const Icon(Icons.currency_rupee_rounded,
                        size: 15, color: AppColors.textSecondary),
                    Expanded(
                      child: Text(
                        '${isHindi ? "बाज़ार भाव" : "Market Price"}: ${crop.currentMarketPrice}',
                        style: AppTextStyles.body2
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            _riskColor(crop.riskLevel).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _riskColor(crop.riskLevel)
                                .withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        _riskLabel(crop.riskLevel, isHindi),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _riskColor(crop.riskLevel),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Season + Duration row
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        crop.bestSeason,
                        style: AppTextStyles.caption
                            .copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.access_time_rounded,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      crop.growthDuration,
                      style: AppTextStyles.caption
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Reason
                Text(
                  isHindi ? crop.reasonHindi : crop.reason,
                  style: AppTextStyles.body2.copyWith(height: 1.5),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Financial stats
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          child: _StatColumn(
                        label: isHindi ? 'लागत' : 'Cost',
                        value: crop.estimatedCostPerAcre,
                        color: const Color(0xFFE53935),
                        icon: Icons.arrow_downward_rounded,
                      )),
                      Container(width: 1, height: 40, color: AppColors.divider),
                      Expanded(
                          child: _StatColumn(
                        label: isHindi ? 'आय' : 'Revenue',
                        value: crop.estimatedRevenuePerAcre,
                        color: const Color(0xFF1E88E5),
                        icon: Icons.arrow_upward_rounded,
                      )),
                      Container(width: 1, height: 40, color: AppColors.divider),
                      Expanded(
                          child: _StatColumn(
                        label: isHindi ? 'मुनाफा' : 'Profit',
                        value: crop.estimatedProfitPerAcre,
                        color: AppColors.success,
                        icon: Icons.trending_up_rounded,
                      )),
                    ],
                  ),
                ),

                // Risk Factors
                if (crop.riskFactors.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    isHindi ? '⚠️ जोखिम कारण' : '⚠️ Risk Factors',
                    style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: crop.riskFactors.map((factor) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color:
                                  AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          factor,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _WeatherChip extends StatelessWidget {
  const _WeatherChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sublabel,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Text(sublabel, style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final shortVal = value.split('-').first.trim();
    return Column(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 2),
        Text(
          shortVal,
          style: AppTextStyles.label.copyWith(
              color: color, fontWeight: FontWeight.w700, fontSize: 12),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
