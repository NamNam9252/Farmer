import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_app_bar.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../data/models/rental_models.dart';
import '../providers/rental_providers.dart';

class PostRentalAssetScreen extends ConsumerStatefulWidget {
  final RentalAsset? asset;
  const PostRentalAssetScreen({super.key, this.asset});

  @override
  ConsumerState<PostRentalAssetScreen> createState() => _PostRentalAssetScreenState();
}

class _PostRentalAssetScreenState extends ConsumerState<PostRentalAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late AssetType _selectedType;
  
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploading = false;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.asset?.title ?? '');
    _descriptionController = TextEditingController(text: widget.asset?.description ?? '');
    _priceController = TextEditingController(text: widget.asset?.basePrice.toString() ?? '');
    _selectedType = widget.asset?.type ?? AssetType.EQUIPMENT;
    _uploadedImageUrl = widget.asset?.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = ref.watch(languageProvider) == 'hi';
    final isEditing = widget.asset != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SharedHeader(
            title: isHindi 
                ? (isEditing ? 'अपडेट रेंटल' : 'रेंटल पोस्ट करें') 
                : (isEditing ? 'Update Rental' : 'Post Rental'),
            subtitle: isHindi 
                ? 'अपना उपकरण या जमीन किराए पर दें' 
                : 'Rent out your equipment or land',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Upload Section
                    GestureDetector(
                      onTap: _isUploading ? null : _showImagePickerOptions,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                          image: _uploadedImageUrl != null 
                              ? DecorationImage(
                                  image: NetworkImage(_uploadedImageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : _selectedImage != null
                                  ? DecorationImage(
                                      image: FileImage(_selectedImage!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                        ),
                        child: _isUploading
                            ? const Center(child: CircularProgressIndicator())
                            : (_uploadedImageUrl == null && _selectedImage == null)
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.grey.shade400),
                                      const SizedBox(height: 8),
                                      Text(
                                        isHindi ? 'फोटो जोड़ें' : 'Add Post Photo', 
                                        style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)
                                      ),
                                    ],
                                  )
                                : Container(
                                    alignment: Alignment.bottomRight,
                                    padding: const EdgeInsets.all(12),
                                    child: CircleAvatar(
                                      backgroundColor: AppColors.primary,
                                      radius: 18,
                                      child: const Icon(Icons.edit, color: Colors.white, size: 20),
                                    ),
                                  ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle(isHindi ? 'विवरण' : 'Details', isHindi),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: isHindi ? 'शीर्षक' : 'Title',
                        hintText: isHindi ? 'जैसे: ट्रैक्टर रेंटल' : 'e.g. Tractor for Rent',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value == null || value.isEmpty ? (isHindi ? 'कृपया शीर्षक दर्ज करें' : 'Please enter title') : null,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<AssetType>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        labelText: isHindi ? 'प्रकार' : 'Type',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: AssetType.values.map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(isHindi ? _getTypeNameHindi(type) : type.name),
                      )).toList(),
                      onChanged: (value) => setState(() => _selectedType = value!),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: isHindi ? 'विवरण' : 'Description',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle(isHindi ? 'मूल्य निर्धारण' : 'Pricing', isHindi),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: isHindi ? 'आधार मूल्य (₹/दिन)' : 'Base Price (₹/day)',
                        prefixIcon: const Icon(Icons.currency_rupee_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value == null || value.isEmpty ? (isHindi ? 'कृपया मूल्य दर्ज करें' : 'Please enter price') : null,
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        isHindi 
                          ? (isEditing ? 'अपडेट करें' : 'पोस्ट सबमिट करें') 
                          : (isEditing ? 'Update Entry' : 'Submit Post'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isHindi) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _isUploading = true;
        });

        final url = await _cloudinaryService.uploadImage(_selectedImage!);
        
        setState(() {
          _isUploading = false;
          if (url != null) {
            _uploadedImageUrl = url;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload image. Please check Cloudinary credentials.')),
            );
          }
        });
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_uploadedImageUrl == null && _selectedImage == null) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please upload an image for the rental')),
          );
          return;
      }

      if (_isUploading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please wait for image to finish uploading')),
        );
        return;
      }

      try {
        final price = double.parse(_priceController.text);
        final data = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'type': _selectedType.name,
          'basePrice': price,
          'imageUrl': _uploadedImageUrl,
        };

        if (widget.asset != null) {
          await ref.read(myAssetsProvider.notifier).updateAsset(widget.asset!.id, data);
        } else {
          await ref.read(myAssetsProvider.notifier).createAsset(data);
        }

        if (mounted) {
          ref.invalidate(rentalAssetsProvider);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.asset != null ? 'Rental updated successfully!' : 'Rental asset posted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  String _getTypeNameHindi(AssetType type) {
    switch (type) {
      case AssetType.PROPERTY: return 'जमीन';
      case AssetType.VEHICLE: return 'वाहन';
      case AssetType.EQUIPMENT: return 'उपकरण';
      case AssetType.OTHER: return 'अन्य';
    }
  }
}
