import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../router/route_names.dart';
import '../../data/models/marketplace_new_models.dart';
import '../providers/marketplace_new_provider.dart';
import '../../../../shared/widgets/shared_app_bar.dart';
import '../../../../core/services/language_provider.dart';

class BrowseItemsScreen extends ConsumerStatefulWidget {
  const BrowseItemsScreen({super.key});

  @override
  ConsumerState<BrowseItemsScreen> createState() => _BrowseItemsScreenState();
}

class _BrowseItemsScreenState extends ConsumerState<BrowseItemsScreen> {
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(marketplaceItemsProvider.notifier).loadItems());
  }

  void _onCategorySelected(String? category) {
    setState(() => _selectedCategory = category);
    ref.read(marketplaceItemsProvider.notifier).loadItems(category: category);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketplaceItemsProvider);
    final isHindi = ref.watch(languageProvider) == 'hi';
    final categories = [
      'ALL', 'CROPS', 'FRUITS', 'VEGETABLES', 'GRAINS', 'SEEDS', 
      'FERTILIZERS', 'PESTICIDES', 'FARMING_EQUIPMENT', 
      'LIVESTOCK_PRODUCTS', 'OTHER'
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SharedHeader(
            title: isHindi ? 'उत्पाद खरीदें' : 'Buy Produce',
            subtitle: isHindi 
                ? 'सीधे उच्च गुणवत्ता वाले उत्पाद खरीदें' 
                : 'Buy quality produce directly',
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.filter_list_rounded, color: Colors.white, size: 18),
                ),
                onPressed: () {
                  // Show filter bottom sheet - logic placeholder
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          _buildCategoryFilters(categories),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.read(marketplaceItemsProvider.notifier).loadItems(category: _selectedCategory),
              child: state.isLoading 
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                  ? Center(child: Text('Error: ${state.error}'))
                  : state.items.isEmpty
                    ? const _EmptyState(message: 'No items found matching your criteria')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                        itemCount: state.items.length,
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return _ItemCard(
                            item: item,
                            onTap: () => context.push(RouteNames.itemDetail, extra: item),
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(List<String> categories) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = (_selectedCategory == null && cat == 'ALL') || _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat, style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              )),
              selected: isSelected,
              onSelected: (selected) {
                _onCategorySelected(cat == 'ALL' ? null : cat);
              },
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              shape: StadiumBorder(side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey[300]!)),
            ),
          );
        },
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onTap;

  const _ItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  image: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? DecorationImage(image: NetworkImage(item.imageUrl!), fit: BoxFit.cover)
                    : null,
                ),
                child: item.imageUrl == null || item.imageUrl!.isEmpty
                  ? const Icon(Icons.image_outlined, color: Colors.grey, size: 32)
                  : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.category,
                            style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          '₹${item.pricePerUnit}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.itemName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.scale_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(item.quantity, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(width: 12),
                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.location, 
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}
