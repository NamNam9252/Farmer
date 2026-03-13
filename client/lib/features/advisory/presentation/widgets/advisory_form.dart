import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/services/language_provider.dart';
import '../providers/advisory_provider.dart';
import '../../../../shared/widgets/crop_picker_sheet.dart';

class AdvisoryForm extends ConsumerWidget {
  const AdvisoryForm({super.key});

  static const List<String> _levels = ['low', 'medium', 'high'];
  static const Map<String, String> _levelLabelsHi = {
    'low': 'कम',
    'medium': 'मध्यम',
    'high': 'अधिक',
  };
  static const Map<String, String> _levelLabelsEn = {
    'low': 'Low',
    'medium': 'Medium',
    'high': 'High',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(advisoryProvider);
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCropSelector(context, ref, state, isHindi),
        const SizedBox(height: 24),

        _buildSectionHeader(isHindi ? AppStrings.daysSinceSowingHindi : AppStrings.daysSinceSowing, '🌱'),
        _buildDaysSlider(ref, state),
        const SizedBox(height: 16),

        _buildSectionHeader(isHindi ? 'मिट्टी के पोषक तत्व' : 'Soil Nutrients', '🧪'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildLevelPicker(
                label: isHindi ? 'N' : 'Nitrogen',
                value: state.soilN,
                isHindi: isHindi,
                onChanged: (v) => ref.read(advisoryProvider.notifier).setSoilN(v),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildLevelPicker(
                label: isHindi ? 'P' : 'Phosphorus',
                value: state.soilP,
                isHindi: isHindi,
                onChanged: (v) => ref.read(advisoryProvider.notifier).setSoilP(v),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildLevelPicker(
                label: isHindi ? 'K' : 'Potassium',
                value: state.soilK,
                isHindi: isHindi,
                onChanged: (v) => ref.read(advisoryProvider.notifier).setSoilK(v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildLevelPicker(
          label: isHindi ? AppStrings.soilMoistureHindi : AppStrings.soilMoisture,
          value: state.soilMoisture,
          isHindi: isHindi,
          isFullWidth: true,
          onChanged: (v) => ref.read(advisoryProvider.notifier).setSoilMoisture(v),
        ),
        const SizedBox(height: 24),

        _buildSectionHeader(isHindi ? AppStrings.pestReportedHindi : AppStrings.pestReported, '🐛'),
        const SizedBox(height: 8),
        _buildPestToggle(ref, state, isHindi),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String emoji) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildCropSelector(BuildContext context, WidgetRef ref, AdvisoryState state, bool isHindi) {
    final crop = CropCatalog.getById(state.crop);
    final emoji = crop?.emoji ?? '🌾';
    final label = crop != null ? (isHindi ? crop.nameHi : crop.nameEn) : state.crop;

    return GestureDetector(
      onTap: () async {
        final result = await showCropPickerSheet(
          context: context,
          isHindi: isHindi,
          multiSelect: false,
          initialSelected: [state.crop],
        );
        if (result != null && result.isNotEmpty) {
          ref.read(advisoryProvider.notifier).setCrop(result.first);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHindi ? AppStrings.selectCropHindi : AppStrings.selectCrop,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.swap_horiz_rounded, color: AppColors.textHint, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysSlider(WidgetRef ref, AdvisoryState state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${state.daysSinceSowing} Days',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              thumbColor: Colors.white,
              inactiveTrackColor: Colors.grey[200],
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 4),
            ),
            child: Slider(
              value: state.daysSinceSowing.toDouble(),
              min: 0,
              max: 120,
              divisions: 24,
              onChanged: (v) => ref.read(advisoryProvider.notifier).setDays(v.toInt()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelPicker({
    required String label,
    required String value,
    required bool isHindi,
    required Function(String) onChanged,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: isFullWidth ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          isFullWidth 
            ? Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: _buildLevelButtons(value, isHindi, onChanged))
            : Column(children: _buildLevelButtons(value, isHindi, onChanged, isVertical: true)),
        ],
      ),
    );
  }

  List<Widget> _buildLevelButtons(String current, bool isHindi, Function(String) onSelect, {bool isVertical = false}) {
    return _levels.map((l) {
      final isSelected = current == l;
      final label = isHindi ? _levelLabelsHi[l]! : _levelLabelsEn[l]!;
      
      return GestureDetector(
        onTap: () => onSelect(l),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: isVertical ? const EdgeInsets.only(bottom: 6) : EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[200]!),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildPestToggle(WidgetRef ref, AdvisoryState state, bool isHindi) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: state.pestReported ? AppColors.error.withValues(alpha: 0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.bug_report_rounded,
              color: state.pestReported ? AppColors.error : AppColors.textHint,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHindi ? AppStrings.pestReportedHindi : AppStrings.pestReported,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Text(
                  isHindi ? 'क्या आपने कीड़े देखे हैं?' : 'Have you seen any pests?',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: state.pestReported,
            activeColor: AppColors.primary,
            onChanged: (v) => ref.read(advisoryProvider.notifier).setPestReported(v),
          ),
        ],
      ),
    );
  }
}
