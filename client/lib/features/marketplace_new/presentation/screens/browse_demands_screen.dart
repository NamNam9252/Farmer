import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../router/route_names.dart';
import '../../data/models/marketplace_new_models.dart';
import '../providers/marketplace_new_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state.dart';

class BrowseDemandsScreen extends ConsumerStatefulWidget {
  const BrowseDemandsScreen({super.key});

  @override
  ConsumerState<BrowseDemandsScreen> createState() => _BrowseDemandsScreenState();
}

class _BrowseDemandsScreenState extends ConsumerState<BrowseDemandsScreen> {
  String? _selectedCategory;

  void _onCategorySelected(String? category) {
    setState(() => _selectedCategory = category);
    ref.read(marketplaceDemandsProvider.notifier).loadDemands(category: category);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(marketplaceDemandsProvider.notifier).loadDemands());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketplaceDemandsProvider);
    final categories = [
      'ALL', 'CROPS', 'FRUITS', 'VEGETABLES', 'GRAINS', 'SEEDS', 
      'FERTILIZERS', 'PESTICIDES', 'FARMING_EQUIPMENT', 
      'LIVESTOCK_PRODUCTS', 'OTHER'
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Buyer Demands'),
      ),
      body: Column(
        children: [
          _buildCategoryFilters(categories),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.read(marketplaceDemandsProvider.notifier).loadDemands(category: _selectedCategory),
              child: state.isLoading 
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                  ? Center(child: Text('Error: ${state.error}'))
                  : state.demands.isEmpty
                    ? const _EmptyState(message: 'No demands found')
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.demands.length,
                        itemBuilder: (context, index) {
                          final demand = state.demands[index];
                          return _DemandCard(
                            demand: demand,
                            onTap: () => context.push(RouteNames.demandDetail, extra: demand),
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
              )),
              selected: isSelected,
              onSelected: (selected) {
                _onCategorySelected(cat == 'ALL' ? null : cat);
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFEF6C00), // Orange for demands
              checkmarkColor: Colors.white,
            ),
          );
        },
      ),
    );
  }
}

class _DemandCard extends StatelessWidget {
  final dynamic demand;
  final VoidCallback onTap;

  const _DemandCard({required this.demand, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      demand.category,
                      style: const TextStyle(color: Color(0xFFE65100), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    'Target: ₹${demand.expectedPrice}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFE65100)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                demand.itemName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                   const Icon(Icons.shopping_cart_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Needed: ${demand.quantityNeeded}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const Spacer(),
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(demand.location, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
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
          Icon(Icons.search_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}
