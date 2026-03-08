import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/language_provider.dart';
import '../providers/advisory_provider.dart';
import '../../../../shared/widgets/crop_picker_sheet.dart';

/// Input form widget for the advisory screen.
/// Contains crop, days, soil NPK, moisture, and pest toggle.
class AdvisoryForm extends ConsumerWidget {
  const AdvisoryForm({super.key});

  static const List<String> _crops = ['wheat', 'rice', 'tomato'];
  static const Map<String, String> _cropLabelsHi = {
    'wheat': 'गेहूं (Wheat)',
    'rice': 'धान (Rice)',
    'tomato': 'टमाटर (Tomato)',
  };
  static const Map<String, String> _cropLabelsEn = {
    'wheat': 'Wheat',
    'rice': 'Rice',
    'tomato': 'Tomato',
  };

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
        // --- Crop Selector (Image-based) ---
        _buildLabel(isHindi ? AppStrings.selectCropHindi : AppStrings.selectCrop),
        const SizedBox(height: 6),
        _buildCropSelector(context, ref, state, isHindi),
        const SizedBox(height: 16),

        // --- Days since sowing ---
        _buildLabel(
          '${isHindi ? AppStrings.daysSinceSowingHindi : AppStrings.daysSinceSowing}: ${state.daysSinceSowing}',
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            thumbColor: AppColors.primary,
            inactiveTrackColor: AppColors.primary.withValues(alpha: 0.15),
            overlayColor: AppColors.primary.withValues(alpha: 0.1),
          ),
          child: Slider(
            value: state.daysSinceSowing.toDouble(),
            min: 0,
            max: 120,
            divisions: 24,
            label: '${state.daysSinceSowing}',
            onChanged: (v) =>
                ref.read(advisoryProvider.notifier).setDays(v.toInt()),
          ),
        ),
        const SizedBox(height: 8),

        // --- Soil NPK Row ---
        Row(
          children: [
            Expanded(
              child: _buildLevelDropdown(
                label: isHindi ? AppStrings.soilNitrogenHindi : AppStrings.soilNitrogen,
                value: state.soilN,
                isHindi: isHindi,
                onChanged: (v) => ref.read(advisoryProvider.notifier).setSoilN(v!),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildLevelDropdown(
                label: isHindi ? AppStrings.soilPhosphorusHindi : AppStrings.soilPhosphorus,
                value: state.soilP,
                isHindi: isHindi,
                onChanged: (v) => ref.read(advisoryProvider.notifier).setSoilP(v!),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildLevelDropdown(
                label: isHindi ? AppStrings.soilPotassiumHindi : AppStrings.soilPotassium,
                value: state.soilK,
                isHindi: isHindi,
                onChanged: (v) => ref.read(advisoryProvider.notifier).setSoilK(v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // --- Soil Moisture ---
        _buildLevelDropdown(
          label: isHindi ? AppStrings.soilMoistureHindi : AppStrings.soilMoisture,
          value: state.soilMoisture,
          isHindi: isHindi,
          onChanged: (v) =>
              ref.read(advisoryProvider.notifier).setSoilMoisture(v!),
        ),
        const SizedBox(height: 16),

        // --- Pest Toggle ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isHindi ? AppStrings.pestReportedHindi : AppStrings.pestReported,
                style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w500),
              ),
              Switch.adaptive(
                value: state.pestReported,
                activeColor: AppColors.primary,
                onChanged: (v) =>
                    ref.read(advisoryProvider.notifier).setPestReported(v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.body2.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildCropSelector(
      BuildContext context, WidgetRef ref, AdvisoryState state, bool isHindi) {
    final crop = CropCatalog.getById(state.crop);
    final emoji = crop?.emoji ?? '🌾';
    final bgColor = crop?.bgColor ?? AppColors.surface;
    final label = crop != null
        ? (isHindi ? crop.nameHi : crop.nameEn)
        : state.crop;

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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        items: items,
        onChanged: onChanged,
        style: AppTextStyles.body1.copyWith(color: AppColors.textPrimary),
        dropdownColor: Colors.white,
      ),
    );
  }

  Widget _buildLevelDropdown({
    required String label,
    required String value,
    required bool isHindi,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabel(label),
        const SizedBox(height: 6),
        _buildDropdown<String>(
          value: value,
          items: _levels
              .map((l) => DropdownMenuItem(
                    value: l,
                    child: Text(
                      isHindi ? _levelLabelsHi[l]! : _levelLabelsEn[l]!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
