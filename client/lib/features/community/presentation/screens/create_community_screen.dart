import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../core/services/location_service.dart';
import '../providers/community_provider.dart';
import '../../../../shared/widgets/shared_app_bar.dart';

class CreateCommunityScreen extends ConsumerStatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  ConsumerState<CreateCommunityScreen> createState() =>
      _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends ConsumerState<CreateCommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedType = 'GENERAL';
  bool _isPrivate = false;
  bool _isLoading = false;

  final Map<String, String> _typesEn = {
    'GENERAL': 'General',
    'CROP_BASED': 'Crop Based',
    'ROUND': 'Round',
    'RADIUS_BASED': 'Area Based',
  };

  final Map<String, String> _typesHi = {
    'GENERAL': 'सामान्य',
    'CROP_BASED': 'फसल आधारित',
    'ROUND': 'राउंड',
    'RADIUS_BASED': 'क्षेत्र आधारित',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final isHindi = ref.read(languageProvider) == 'hi';

    try {
      final loc = await LocationService.getCurrentLocation();
      await ref.read(communityListProvider.notifier).createCommunity(
            name: _nameController.text.trim(),
            description: _descController.text.trim(),
            type: _selectedType,
            isPrivate: _isPrivate,
            latitude: loc.latitude,
            longitude: loc.longitude,
            radiusKm: 50,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isHindi ? 'सफलतापूर्वक बनाया गया!' : 'Created successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = ref.watch(languageProvider) == 'hi';
    final typesMap = isHindi ? _typesHi : _typesEn;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(isHindi),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: _isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppColors.primary)))
                  : Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel(isHindi ? 'समुदाय का नाम' : 'Community Name'),
                          _buildTextField(
                            controller: _nameController,
                            hint: isHindi ? 'जैसे: जयपुर किसान यूनियन' : 'e.g. Jaipur Farmers Union',
                            validator: (val) => (val == null || val.trim().isEmpty) ? (isHindi ? 'नाम दर्ज करें' : 'Enter name') : null,
                          ),
                          const SizedBox(height: 24),
                          
                          _buildFieldLabel(isHindi ? 'विवरण (वैकल्पिक)' : 'Description (Optional)'),
                          _buildTextField(
                            controller: _descController,
                            hint: isHindi ? 'इस समुदाय के बारे में बताएं...' : 'Tell us about this community...',
                            maxLines: 4,
                          ),
                          const SizedBox(height: 24),

                          _buildFieldLabel(isHindi ? 'प्रकार' : 'Type'),
                          _buildDropdownField(typesMap),
                          const SizedBox(height: 24),

                          _buildPrivateToggle(isHindi),
                          const SizedBox(height: 40),

                          _buildSubmitButton(isHindi),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isHindi) {
    return SharedStickyHeader(
      title: isHindi ? 'नया समुदाय बनाएं' : 'Create New Community',
      subtitle: isHindi 
          ? 'समान रुचियों वाले किसानों का समूह शुरू करें' 
          : 'Start a group for farmers with shared interests',
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, String? Function(String?)? validator, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 14, color: AppColors.textHint, fontWeight: FontWeight.w400),
          contentPadding: const EdgeInsets.all(18),
          border: InputBorder.none,
          errorStyle: const TextStyle(height: 0),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField(Map<String, String> typesMap) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _selectedType,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          items: typesMap.entries.map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value))).toList(),
          onChanged: (val) => setState(() => _selectedType = val!),
          decoration: const InputDecoration(border: InputBorder.none),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildPrivateToggle(bool isHindi) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: SwitchListTile.adaptive(
        activeColor: AppColors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(isHindi ? 'निजी समुदाय' : 'Private Community', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        subtitle: Text(isHindi ? 'स्वीकृति आवश्यक होगी' : 'Approval required', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        value: _isPrivate,
        onChanged: (val) => setState(() => _isPrivate = val),
      ),
    );
  }

  Widget _buildSubmitButton(bool isHindi) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: Text(isHindi ? 'बनाएं' : 'Create Community', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
      ),
    );
  }
}
