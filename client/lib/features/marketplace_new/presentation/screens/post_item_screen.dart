import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../router/route_names.dart';
import '../../data/models/marketplace_new_models.dart';
import '../providers/marketplace_new_provider.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../shared/widgets/shared_app_bar.dart';

class PostItemScreen extends ConsumerStatefulWidget {
  final MarketplaceItem? item;
  const PostItemScreen({super.key, this.item});

  @override
  ConsumerState<PostItemScreen> createState() => _PostItemScreenState();
}

class _PostItemScreenState extends ConsumerState<PostItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = 'CROPS';
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploading = false;

  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.itemName;
      _quantityController.text = widget.item!.quantity;
      _priceController.text = widget.item!.pricePerUnit.toString();
      _locationController.text = widget.item!.location;
      _descriptionController.text = widget.item!.description ?? '';
      _uploadedImageUrl = widget.item!.imageUrl;
      _selectedCategory = widget.item!.category;
    }
  }

  final List<String> _categories = [
    'CROPS', 'FRUITS', 'VEGETABLES', 'GRAINS', 'SEEDS', 
    'FERTILIZERS', 'PESTICIDES', 'FARMING_EQUIPMENT', 
    'LIVESTOCK_PRODUCTS', 'OTHER'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
            const SnackBar(content: Text('Please upload an image of the item')),
          );
          return;
      }

      if (_isUploading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please wait for image to finish uploading')),
        );
        return;
      }

      final notifier = ref.read(marketplaceItemsProvider.notifier);
      final data = {
        'itemName': _nameController.text,
        'category': _selectedCategory,
        'quantity': _quantityController.text,
        'pricePerUnit': double.parse(_priceController.text),
        'location': _locationController.text,
        'description': _descriptionController.text,
        'imageUrl': _uploadedImageUrl,
      };

      try {
        if (widget.item != null) {
          await notifier.updateItem(widget.item!.id, data);
        } else {
          await notifier.createItem(data);
        }
        
        ref.read(marketplaceMyListingsProvider.notifier).refresh();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.item != null ? 'Item updated!' : 'Item listed successfully!')),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SharedHeader(
            title: widget.item != null ? 'Edit Item' : 'Post Item to Sell',
            subtitle: widget.item != null 
                ? 'Update your listing details' 
                : 'List your produce for buyers',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Upload Section
              GestureDetector(
                onTap: _isUploading ? null : _showImagePickerOptions,
                child: Container(
                  height: 200,
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
                                Text('Add Item Photo', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name (e.g. Wheat, Mango)',
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity (e.g. 100 kg)',
                        prefixIcon: Icon(Icons.scale_outlined),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price per Unit',
                        prefixIcon: Icon(Icons.currency_rupee_rounded),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isUploading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: Text(
                  _isUploading 
                    ? 'UPLOADING IMAGE...' 
                    : (widget.item != null ? 'SAVE CHANGES' : 'LIST ITEM'), 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
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
}
