import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/shared_app_bar.dart';
import '../../data/models/rental_models.dart';
import '../providers/rental_providers.dart';
import '../widgets/rental_asset_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state.dart';

class BrowseRentalsScreen extends ConsumerStatefulWidget {
  const BrowseRentalsScreen({super.key});

  @override
  ConsumerState<BrowseRentalsScreen> createState() => _BrowseRentalsScreenState();
}

class _BrowseRentalsScreenState extends ConsumerState<BrowseRentalsScreen> {
  AssetType? _selectedType;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(rentalAssetsProvider.notifier).loadAssets());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rentalAssetsProvider);
    final isHindi = ref.watch(languageProvider) == 'hi';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SharedStickyHeader(
            title: isHindi ? 'रेंटल ब्राउज़ करें' : 'Browse Rentals',
            subtitle: isHindi 
                ? 'किराए के लिए उपलब्ध सभी चीजें'
                : 'All available items for rent',
            backgroundImage: 'assets/images/service_icons/marketplace.png',
          ),
          SliverToBoxAdapter(
            child: _buildTypeFilters(isHindi),
          ),
          if (state.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            _buildSliverContent(state, isHindi),
        ],
      ),
    );
  }

  Widget _buildTypeFilters(bool isHindi) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _TypeChip(
            label: isHindi ? 'सभी' : 'ALL',
            isSelected: _selectedType == null,
            onTap: () => setState(() => _selectedType = null),
          ),
          ...AssetType.values.map((type) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _TypeChip(
              label: isHindi ? _getTypeNameHindi(type) : type.name,
              isSelected: _selectedType == type,
              onTap: () => setState(() => _selectedType = type),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSliverContent(RentalAssetsState state, bool isHindi) {
    if (state.error != null) return SliverFillRemaining(child: Center(child: Text('Error: ${state.error}')));
    
    final authState = ref.watch(authControllerProvider);
    final currentUserId = authState is Authenticated ? authState.user.id : null;

    final filteredAssets = (state.assets.where((a) => a.ownerId != currentUserId)).where((a) {
      if (_selectedType == null) return true;
      return a.type == _selectedType;
    }).toList();

    if (filteredAssets.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                isHindi ? 'कोई रेंटल नहीं मिला' : 'No rentals found',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final asset = filteredAssets[index];
            return RentalAssetCard(
              asset: asset,
              isHindi: isHindi,
              currentUserId: currentUserId,
              onTap: () => context.push(RouteNames.rentalAssetDetail.replaceAll(':id', asset.id), extra: asset),
            );
          },
          childCount: filteredAssets.length,
        ),
      ),
    );
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

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: StadiumBorder(side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey[300]!)),
    );
  }
}
