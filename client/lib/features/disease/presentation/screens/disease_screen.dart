import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/services/language_provider.dart';
import '../providers/disease_provider.dart';
import '../../../../router/route_names.dart';
import '../widgets/crop_selector_sheet.dart';
import '../widgets/disease_result_card.dart';
import '../widgets/past_reports_section.dart';
import '../widgets/image_preview_card.dart';
import '../widgets/tip_banner.dart';
import '../widgets/analyzing_overlay.dart';
import '../../../../shared/widgets/shared_app_bar.dart';

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

    ref.invalidate(pastReportsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diseaseAnalysisProvider);
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnim,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeader(isHindi, lang),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 24),
                      if (state.selectedImage == null) ...[
                        _buildHeroVisual(isHindi),
                        const SizedBox(height: 32),
                        _buildActionGrid(isHindi),
                      ] else ...[
                        ImagePreviewCard(
                          image: state.selectedImage!,
                          onRetake: () {
                            ref
                                .read(diseaseAnalysisProvider.notifier)
                                .clearAll();
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildCropSelector(isHindi, state.selectedCrop),
                        const SizedBox(height: 20),
                        if (state.result == null)
                          _buildAnalyzeButton(isHindi, state.isLoading),
                      ],
                      const SizedBox(height: 24),
                      if (state.result != null)
                        DiseaseResultCard(
                          report: state.result!,
                          isHindi: isHindi,
                          onRetake: () {
                            ref
                                .read(diseaseAnalysisProvider.notifier)
                                .clearAll();
                          },
                        )
                      else ...[
                        const TipBanner(),
                        const SizedBox(height: 24),
                        PastReportsSection(isHindi: isHindi),
                      ],
                      // Increased padding to ensure no "scroll hang" at the bottom
                      const SizedBox(height: 180),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          if (state.isLoading) AnalyzingOverlay(isHindi: isHindi),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isHindi, String lang) {
    return SharedSliverAppBar(
      title: isHindi ? AppStrings.diseaseTitleHindi : AppStrings.diseaseTitle,
      subtitle: isHindi 
          ? 'तत्काल फसल निदान और उपचार' 
          : 'Instant crop diagnosis and treatment',
    );
  }

  Widget _buildHeroVisual(bool isHindi) {
    return Column(
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: SvgPicture.string(
              AppIcons.disease,
              width: 90,
              height: 90,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          isHindi
              ? AppStrings.diseaseSubtitleHindi
              : AppStrings.diseaseSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isHindi ? AppStrings.diseaseTapHintHindi : AppStrings.diseaseTapHint,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildActionGrid(bool isHindi) {
    return Row(
      children: [
        Expanded(
          child: _FeatureActionCard(
            svgData: AppIcons.cameraAction,
            label: isHindi ? AppStrings.takePhotoHindi : AppStrings.takePhoto,
            bgColor: const Color(0xFFE3F2FD),
            onTap: () => _pickImage(ImageSource.camera),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _FeatureActionCard(
            svgData: AppIcons.galleryAction,
            label: isHindi
                ? AppStrings.uploadGalleryHindi
                : AppStrings.uploadGallery,
            bgColor: const Color(0xFFFCE4EC),
            onTap: () => _pickImage(ImageSource.gallery),
          ),
        ),
      ],
    );
  }

  Widget _buildCropSelector(bool isHindi, String selectedCrop) {
    return GestureDetector(
      onTap: _showCropSelector,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selectedCrop.isEmpty ? AppColors.divider : AppColors.primary,
            width: selectedCrop.isEmpty ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selectedCrop.isEmpty
                    ? Colors.grey[100]
                    : AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.grass_rounded,
                color: selectedCrop.isEmpty ? Colors.grey : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHindi ? AppStrings.cropTypeHindi : AppStrings.cropType,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedCrop.isEmpty
                        ? (isHindi ? 'फसल चुनें' : 'Select Crop')
                        : selectedCrop,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: selectedCrop.isEmpty
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.expand_more_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton(bool isHindi, bool isLoading) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : _analyze,
        icon: const Icon(Icons.psychology_rounded, size: 22, color: Colors.white),
        label: Text(
          isHindi ? AppStrings.analyzeHindi : AppStrings.analyze,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

class _FeatureActionCard extends StatelessWidget {
  const _FeatureActionCard({
    required this.svgData,
    required this.label,
    required this.bgColor,
    required this.onTap,
  });

  final String svgData;
  final String label;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.string(
                  svgData,
                  width: 44,
                  height: 44,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
