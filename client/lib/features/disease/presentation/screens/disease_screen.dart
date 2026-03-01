import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_strings.dart';
import '../providers/disease_provider.dart';
import '../widgets/crop_selector_sheet.dart';
import '../widgets/disease_result_card.dart';
import '../widgets/past_reports_section.dart';
import '../widgets/image_preview_card.dart';
import '../widgets/tip_banner.dart';
import '../widgets/analyzing_overlay.dart';

class DiseaseScreen extends ConsumerStatefulWidget {
  const DiseaseScreen({super.key});

  @override
  ConsumerState<DiseaseScreen> createState() => _DiseaseScreenState();
}

class _DiseaseScreenState extends ConsumerState<DiseaseScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (file != null) {
        ref.read(diseaseAnalysisProvider.notifier).setImage(File(file.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access camera/gallery: $e')),
        );
      }
    }
  }

  void _showCropSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CropSelectorSheet(),
    );
  }

  Future<void> _analyze() async {
    final state = ref.read(diseaseAnalysisProvider);
    if (state.selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image first / पहले फोटो चुनें'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final lang = ref.read(languageProvider);
    await ref.read(diseaseAnalysisProvider.notifier).analyze(language: lang);

    final newState = ref.read(diseaseAnalysisProvider);
    if (newState.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newState.error!),
          backgroundColor: AppColors.error,
          action: SnackBarAction(
            label: AppStrings.tryAgain,
            textColor: Colors.white,
            onPressed: _analyze,
          ),
        ),
      );
    }

    // Refresh past reports
    ref.invalidate(pastReportsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diseaseAnalysisProvider);
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(isHindi, lang, ref),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          _buildHeroSection(isHindi),
                          const SizedBox(height: 20),
                          if (state.selectedImage == null) ...[
                            _buildActionButtons(isHindi),
                          ] else ...[
                            ImagePreviewCard(
                              image: state.selectedImage!,
                              onRetake: () {
                                ref.read(diseaseAnalysisProvider.notifier).clearAll();
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildCropSelector(isHindi, state.selectedCrop),
                            const SizedBox(height: 16),
                            if (state.result == null)
                              _buildAnalyzeButton(isHindi, state.isLoading),
                          ],
                          const SizedBox(height: 20),
                          if (state.result != null)
                            DiseaseResultCard(
                              report: state.result!,
                              isHindi: isHindi,
                              onRetake: () {
                                ref.read(diseaseAnalysisProvider.notifier).clearAll();
                              },
                            )
                          else ...[
                            const SizedBox(height: 8),
                            PastReportsSection(isHindi: isHindi),
                            const SizedBox(height: 32),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (state.isLoading) AnalyzingOverlay(isHindi: isHindi),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(bool isHindi, String lang, WidgetRef ref) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isHindi ? AppStrings.diseaseTitleHindi : AppStrings.diseaseTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            isHindi ? AppStrings.diseaseTitleHindi : 'Disease Analyser',
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
      actions: [
        // Language Toggle
        GestureDetector(
          onTap: () {
            ref.read(languageProvider.notifier).state =
                lang == 'hi' ? 'en' : 'hi';
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white38),
            ),
            child: Text(
              lang == 'hi' ? 'EN' : 'हि',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(bool isHindi) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.eco_rounded,
                size: 64,
                color: AppColors.primary,
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isHindi ? AppStrings.diseaseSubtitleHindi : AppStrings.diseaseSubtitle,
          style: AppTextStyles.headline2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          isHindi ? AppStrings.diseaseTapHintHindi : AppStrings.diseaseTapHint,
          style: AppTextStyles.body2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const TipBanner(),
      ],
    );
  }

  Widget _buildActionButtons(bool isHindi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActionButton(
          icon: Icons.camera_alt_rounded,
          label: isHindi ? AppStrings.takePhotoHindi : AppStrings.takePhoto,
          sublabel: isHindi ? AppStrings.takePhoto : AppStrings.takePhotoHindi,
          color: AppColors.primary,
          onTap: () => _pickImage(ImageSource.camera),
        ),
        const SizedBox(height: 12),
        _ActionButton(
          icon: Icons.photo_library_rounded,
          label: isHindi ? AppStrings.uploadGalleryHindi : AppStrings.uploadGallery,
          sublabel: isHindi ? AppStrings.uploadGallery : AppStrings.uploadGalleryHindi,
          color: AppColors.primaryDark,
          onTap: () => _pickImage(ImageSource.gallery),
        ),
      ],
    );
  }

  Widget _buildCropSelector(bool isHindi, String selectedCrop) {
    return GestureDetector(
      onTap: _showCropSelector,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectedCrop.isEmpty ? AppColors.divider : AppColors.primary,
            width: selectedCrop.isEmpty ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.grass_rounded,
              color: selectedCrop.isEmpty ? AppColors.textHint : AppColors.primary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHindi ? AppStrings.cropTypeHindi : AppStrings.cropType,
                    style: AppTextStyles.caption,
                  ),
                  Text(
                    selectedCrop.isEmpty
                        ? (isHindi ? 'फसल चुनें' : 'Select Crop')
                        : selectedCrop,
                    style: AppTextStyles.body1.copyWith(
                      color: selectedCrop.isEmpty
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton(bool isHindi, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : _analyze,
        icon: const Icon(Icons.biotech_rounded, size: 22),
        label: Text(
          isHindi ? AppStrings.analyzeHindi : AppStrings.analyze,
          style: AppTextStyles.button,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      elevation: 3,
      shadowColor: color.withOpacity(0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
