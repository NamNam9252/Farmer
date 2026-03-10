import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/marketplace_new_models.dart';
import '../providers/marketplace_new_provider.dart';

class PostDemandScreen extends ConsumerStatefulWidget {
  final MarketplaceDemand? demand;
  const PostDemandScreen({super.key, this.demand});

  @override
  ConsumerState<PostDemandScreen> createState() => _PostDemandScreenState();
}

class _PostDemandScreenState extends ConsumerState<PostDemandScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'CROPS';

  @override
  void initState() {
    super.initState();
    if (widget.demand != null) {
      _nameController.text = widget.demand!.itemName;
      _quantityController.text = widget.demand!.quantityNeeded;
      _priceController.text = widget.demand!.expectedPrice.toString();
      _locationController.text = widget.demand!.location;
      _descriptionController.text = widget.demand!.description ?? '';
      _selectedCategory = widget.demand!.category;
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

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final notifier = ref.read(marketplaceDemandsProvider.notifier);
      final data = {
        'itemName': _nameController.text,
        'category': _selectedCategory,
        'quantityNeeded': _quantityController.text,
        'expectedPrice': double.parse(_priceController.text),
        'location': _locationController.text,
        'description': _descriptionController.text,
      };

      try {
        if (widget.demand != null) {
          await notifier.updateDemand(widget.demand!.id, data);
        } else {
          await notifier.createDemand(data);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.demand != null ? 'Demand updated!' : 'Demand posted successfully!')),
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
      appBar: AppBar(
        title: Text(widget.demand != null ? 'Edit Demand' : 'Post Demand'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Needed',
                  prefixIcon: Icon(Icons.search_rounded),
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
                        labelText: 'Quantity Needed',
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
                        labelText: 'Expected Price',
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
                  labelText: 'Additional Details',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFFEF6C00), // Orange for demands
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(widget.demand != null ? 'SAVE CHANGES' : 'POST DEMAND', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
