import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../core/services/location_service.dart';
import '../providers/community_provider.dart';

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
    final lang = ref.read(languageProvider);
    final isHindi = lang == 'hi';

    try {
      final loc = await LocationService.getCurrentLocation();
      await ref.read(communityListProvider.notifier).createCommunity(
            name: _nameController.text.trim(),
            description: _descController.text.trim(),
            type: _selectedType,
            isPrivate: _isPrivate,
            latitude: loc.latitude,
            longitude: loc.longitude,
            radiusKm: 50, // Default 50km
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isHindi
              ? 'समुदाय सफलतापूर्वक बनाया गया!'
              : 'Community created successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';
    final typesMap = isHindi ? _typesHi : _typesEn;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isHindi ? 'नया समुदाय बनाएं' : 'Create Community'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHindi ? 'समुदाय का नाम' : 'Community Name',
                      style: AppTextStyles.headline3,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: isHindi
                            ? 'जैसे: जयपुर किसान यूनियन'
                            : 'e.g. Jaipur Farmers Union',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return isHindi
                              ? 'कृपया नाम दर्ज करें'
                              : 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isHindi ? 'विवरण (वैकल्पिक)' : 'Description (Optional)',
                      style: AppTextStyles.headline3,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: isHindi
                            ? 'इस समुदाय के बारे में बताएं...'
                            : 'Tell us about this community...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isHindi ? 'प्रकार' : 'Type',
                      style: AppTextStyles.headline3,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: typesMap.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedType = val);
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: SwitchListTile(
                        activeThumbColor: AppColors.primary,
                        title: Text(
                          isHindi ? 'निजी समुदाय' : 'Private Community',
                          style: AppTextStyles.body1,
                        ),
                        subtitle: Text(
                          isHindi
                              ? 'शामिल होने के लिए स्वीकृति की आवश्यकता होगी'
                              : 'Will require approval to join',
                          style: AppTextStyles.caption,
                        ),
                        value: _isPrivate,
                        onChanged: (val) => setState(() => _isPrivate = val),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _submit,
                        child: Text(
                          isHindi ? 'बनाएं' : 'Create',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
