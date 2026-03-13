import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/language_provider.dart';
import '../state/crop_recommendation_state.dart';
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
      backgroundColor: const Color(0xFFF6F8F6),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context, isHindi),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Filter Inputs
                  _buildFilters(context, ref, state, isHindi),
                  const SizedBox(height: 24),

                  _buildActionButton(ref, state, isHindi),
                  const SizedBox(height: 32),

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
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isHindi) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Text(
                  isHindi
                      ? 'मिट्टी और मौसम के आधार पर सर्वोत्तम फसल चुनें'
                      : 'Best crop based on your soil & weather',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        title: Text(
          isHindi ? 'AI फसल सलाहकार' : 'AI Crop Advisor',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
        ),
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
        SizedBox(width: 12),
      ],
    );
  }

  Widget _buildFilters(BuildContext context, WidgetRef ref, CropRecommendationState state, bool isHindi) {
    final selectedCrops = state.preferredCrops as List<String>;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHindi ? 'पसंदीदा फसलें' : 'Preferred Crops',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    Text(
                      isHindi ? 'वैकल्पिक चयन' : 'Optional selection',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (selectedCrops.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    '${selectedCrops.length}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Selected crops preview
          if (selectedCrops.isNotEmpty) ...[
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: selectedCrops.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (_, i) {
                  final cropId = selectedCrops[i];
                  final crop = CropCatalog.getById(cropId);
                  final emoji = crop?.emoji ?? '🌱';
                  final label = crop != null ? (isHindi ? crop.nameHi : crop.nameEn) : cropId;

                  return GestureDetector(
                    onTap: () => ref.read(cropRecommendationProvider.notifier).togglePreferredCrop(cropId),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F8E9),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1),
                              ),
                              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 30))),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                                child: const Icon(Icons.close_rounded, size: 10, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 64,
                          child: Text(
                            label,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
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
            const SizedBox(height: 12),
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
                  final notifier = ref.read(cropRecommendationProvider.notifier);
                  for (final old in List<String>.from(selectedCrops)) {
                    notifier.togglePreferredCrop(old);
                  }
                  for (final crop in result) {
                    notifier.togglePreferredCrop(crop);
                  }
                }
              },
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(isHindi ? 'फसलें चुनें' : 'Select Crops'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(WidgetRef ref, CropRecommendationState state, bool isHindi) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: state.isLoading ? null : () => ref.read(cropRecommendationProvider.notifier).getRecommendation(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: state.isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    isHindi ? 'AI सिफारिश प्राप्त करें' : 'Get AI Recommendation',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState(bool isHindi) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20)],
            ),
            child: const Icon(Icons.psychology_alt_outlined, size: 64, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            isHindi ? 'AI विश्लेषण शुरू करें' : 'Start AI Analysis',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              isHindi
                  ? 'AI आपकी मिट्टी, मौसम और बाज़ार का विश्लेषण करेगा और सर्वोत्तम फसल सुझाएगा।'
                  : 'AI will analyse soil, weather and market trends to suggest the best crops for you.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error, bool isHindi) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          Text(
            isHindi ? 'कुछ गड़बड़ हुई' : 'Something went wrong',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.error),
          ),
          const SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildReport(BuildContext context, CropRecommendationReport report, bool isHindi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLocationSoilCard(report, isHindi),
        const SizedBox(height: 16),
        _buildWeatherRow(report, isHindi),
        const SizedBox(height: 32),

        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFB300), size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHindi ? 'शीर्ष फसल सिफारिशें' : 'Top Recommendations',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                Text(
                  isHindi ? 'सबसे उपयुक्त फसलें' : 'Best suited crops for your field',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        ...report.recommendations.map((crop) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _CropCard(crop: crop, isHindi: isHindi),
            )),

        _buildSummaryCard(report, isHindi),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildLocationSoilCard(CropRecommendationReport report, bool isHindi) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Text('${report.district}, ${report.state}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.landscape_rounded, color: Color(0xFF795548), size: 16),
                    const SizedBox(width: 8),
                    Text(isHindi ? report.soilTypeHindi : report.soilType, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
            child: Text(
              report.currentSeason.split('/').first.trim(),
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherRow(CropRecommendationReport report, bool isHindi) {
    return Row(
      children: [
        _WeatherChip(icon: Icons.thermostat_rounded, color: const Color(0xFFFFEBEE), iconColor: const Color(0xFFE53935), label: '${report.temperature.round()}°C', sublabel: isHindi ? 'तापमान' : 'Temp'),
        const SizedBox(width: 12),
        _WeatherChip(icon: Icons.water_drop_rounded, color: const Color(0xFFE3F2FD), iconColor: const Color(0xFF1E88E5), label: '${report.humidity.round()}%', sublabel: isHindi ? 'नमी' : 'Humidity'),
        const SizedBox(width: 12),
        _WeatherChip(icon: Icons.grain_rounded, color: const Color(0xFFE1F5FE), iconColor: const Color(0xFF0288D1), label: '${report.rainProbability.round()}%', sublabel: isHindi ? 'बारिश' : 'Rain'),
      ],
    );
  }

  Widget _buildSummaryCard(CropRecommendationReport report, bool isHindi) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Text(isHindi ? 'AI मार्गदर्शन' : 'AI Guidance', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Text(isHindi ? report.summaryHindi : report.summary, style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF2E7D32), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _CropCard extends StatelessWidget {
  const _CropCard({required this.crop, required this.isHindi});
  final CropRecommendation crop;
  final bool isHindi;

  Color _riskColor(String risk) {
    if (risk.toLowerCase().contains('low')) return Colors.green;
    if (risk.toLowerCase().contains('high')) return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 130,
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF81C784), Color(0xFF4CAF50)]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Text('#${crop.rank}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 13)),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                    child: Text(crop.demandLevel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.eco_rounded, size: 48, color: Colors.white),
                      const SizedBox(height: 4),
                      Text(isHindi ? crop.cropHindi : crop.crop, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${isHindi ? "बाज़ार भाव" : "Market"}: ${crop.currentMarketPrice}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: _riskColor(crop.riskLevel).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: Text(crop.riskLevel, style: TextStyle(color: _riskColor(crop.riskLevel), fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(isHindi ? crop.reasonHindi : crop.reason, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFF9FBF9), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      _StatItem(label: isHindi ? 'लागत' : 'Cost', value: crop.estimatedCostPerAcre, color: Colors.red[700]!),
                      _StatItem(label: isHindi ? 'मुनाफा' : 'Profit', value: crop.estimatedProfitPerAcre, color: Colors.green[700]!, isBold: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherChip extends StatelessWidget {
  const _WeatherChip({required this.icon, required this.color, required this.iconColor, required this.label, required this.sublabel});
  final IconData icon;
  final Color color;
  final Color iconColor;
  final String label;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            Text(sublabel, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, required this.color, this.isBold = false});
  final String label;
  final String value;
  final Color color;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.w900 : FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
