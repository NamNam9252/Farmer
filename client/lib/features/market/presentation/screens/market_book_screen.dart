import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/language_provider.dart';
import '../providers/market_provider.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/shared_app_bar.dart';

class MarketBookScreen extends ConsumerWidget {
  const MarketBookScreen({super.key});

  void _showSelectionDialog({
    required BuildContext context,
    required String title,
    required List<String> options,
    required String currentValue,
    required Function(String) onSelected,
    bool allowClear = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setState) {
            final filtered = searchQuery.isEmpty
                ? options
                : options
                    .where((o) => o.toLowerCase().contains(searchQuery.toLowerCase()))
                    .toList();
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(title, style: AppTextStyles.headline3),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          onChanged: (val) => setState(() => searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (allowClear)
                        ListTile(
                          leading: const Icon(Icons.clear_all, color: Colors.grey),
                          title: const Text('All (No filter)', style: TextStyle(color: Colors.grey)),
                          onTap: () {
                            onSelected('');
                            Navigator.pop(context);
                          },
                        ),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final option = filtered[index];
                            final isSelected = option == currentValue;
                            return ListTile(
                              title: Text(
                                option,
                                style: AppTextStyles.body1.copyWith(
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                                  : null,
                              onTap: () {
                                onSelected(option);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(marketProvider);
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SharedSliverAppBar(
            title: isHindi ? 'मंडी भाव' : 'Crop Prices',
            onLeadingPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go(RouteNames.home);
              }
            },
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildFilters(context, ref, state, isHindi),
                const SizedBox(height: 16),

                // Search stage message banner
                if (state.message.isNotEmpty && !state.isLoading)
                  _buildStageBanner(state),

                // Category chips
                if (!state.isLoading && state.categories.length > 1)
                  _buildCategoryChips(ref, state, isHindi),

                const SizedBox(height: 12),

                if (state.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 100),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (state.error != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            isHindi ? 'कुछ गलत हो गया' : 'Something went wrong',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body1,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ref.read(marketProvider.notifier).fetchPrices(),
                            child: Text(isHindi ? 'पुनः प्रयास करें' : 'Try Again'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (state.filteredPrices.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Text(isHindi ? 'कोई डेटा नहीं मिला' : 'No data found'),
                    ),
                  )
                else
                  ...state.filteredPrices.map((price) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildPriceCard(context, price, isHindi),
                      )),

                // Suggestions section
                if (!state.isLoading && state.suggestedCrops.isNotEmpty)
                  _buildSuggestions(ref, state, isHindi),

                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, WidgetRef ref, MarketState state, bool isHindi) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _FilterBox(
                  label: isHindi ? 'राज्य' : 'State',
                  value: state.selectedState.isEmpty ? (isHindi ? 'चुनें' : 'Select') : state.selectedState,
                  icon: Icons.map_rounded,
                  onTap: () {
                    _showSelectionDialog(
                      context: context,
                      title: isHindi ? 'राज्य चुनें' : 'Select State',
                      options: state.availableStates,
                      currentValue: state.selectedState,
                      onSelected: (val) => ref.read(marketProvider.notifier).updateState(val),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterBox(
                  label: isHindi ? 'जिला' : 'District',
                  value: state.selectedDistrict.isEmpty
                      ? (isHindi ? 'सभी' : 'All')
                      : state.selectedDistrict,
                  icon: Icons.location_on_rounded,
                  onTap: () {
                    _showSelectionDialog(
                      context: context,
                      title: isHindi ? 'जिला चुनें' : 'Select District',
                      options: state.availableDistricts,
                      currentValue: state.selectedDistrict,
                      onSelected: (val) => ref.read(marketProvider.notifier).updateDistrict(val),
                      allowClear: true,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _FilterBox(
            label: isHindi ? 'फसल' : 'Commodity',
            value: state.selectedCommodity.isEmpty
                ? (isHindi ? 'सभी फसलें' : 'All Commodities')
                : state.selectedCommodity,
            icon: Icons.grass_rounded,
            onTap: () {
              _showSelectionDialog(
                context: context,
                title: isHindi ? 'फसल चुनें' : 'Select Commodity',
                options: state.availableCommodities,
                currentValue: state.selectedCommodity,
                onSelected: (val) {
                  if (val.isEmpty) {
                    ref.read(marketProvider.notifier).clearCommodity();
                  } else {
                    ref.read(marketProvider.notifier).updateCommodity(val);
                  }
                },
                allowClear: true,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStageBanner(MarketState state) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (state.searchStage) {
      case 'exact_match':
        bgColor = const Color(0xFFE8F5E9);
        textColor = Colors.green[800]!;
        icon = Icons.check_circle_outline;
        break;
      case 'state_level':
      case 'national':
        bgColor = const Color(0xFFFFF3E0);
        textColor = Colors.orange[800]!;
        icon = Icons.info_outline;
        break;
      default:
        bgColor = const Color(0xFFFFEBEE);
        textColor = Colors.red[800]!;
        icon = Icons.warning_amber_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.message,
              style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(WidgetRef ref, MarketState state, bool isHindi) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: state.categories.length + 1, // +1 for "All"
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isActive = state.activeCategoryFilter == null;
            return ChoiceChip(
              label: Text(isHindi ? 'सभी' : 'All'),
              selected: isActive,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isActive ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              onSelected: (_) => ref.read(marketProvider.notifier).filterByCategory(null),
            );
          }
          final category = state.categories[index - 1];
          final isActive = state.activeCategoryFilter == category;
          return ChoiceChip(
            label: Text(category),
            selected: isActive,
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isActive ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            onSelected: (_) => ref.read(marketProvider.notifier).filterByCategory(category),
          );
        },
      ),
    );
  }

  Widget _buildSuggestions(WidgetRef ref, MarketState state, bool isHindi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          isHindi ? 'इस क्षेत्र में उपलब्ध फसलें' : 'Available in this area',
          style: AppTextStyles.headline3.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: state.suggestedCrops.take(15).map((crop) {
            return ActionChip(
              label: Text(crop, style: const TextStyle(fontSize: 12)),
              avatar: const Icon(Icons.search, size: 14),
              onPressed: () {
                ref.read(marketProvider.notifier).updateCommodity(crop);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceCard(BuildContext context, dynamic price, bool isHindi) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.08), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Market + Commodity badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.store_rounded, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      price.market,
                      style: AppTextStyles.headline3.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${price.district}, ${price.state}',
                      style: AppTextStyles.caption.copyWith(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  price.commodity,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          // Variety & Grade row
          if (price.variety.isNotEmpty || price.grade.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (price.variety.isNotEmpty)
                  _infoTag(isHindi ? 'किस्म' : 'Variety', price.variety),
                if (price.variety.isNotEmpty && price.grade.isNotEmpty) const SizedBox(width: 8),
                if (price.grade.isNotEmpty)
                  _infoTag(isHindi ? 'ग्रेड' : 'Grade', price.grade),
              ],
            ),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Modal (average) price — big
          _buildPriceRow(
            isHindi ? 'मोडल मूल्य' : 'MODAL PRICE',
            price.averagePrice,
            AppColors.primary,
            isHindi,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),

          // Min / Max row
          Row(
            children: [
              Expanded(child: _buildSmallPrice(isHindi ? 'न्यूनतम' : 'Min', price.lowestPrice, AppColors.error)),
              Container(width: 1, height: 40, color: AppColors.divider),
              Expanded(child: _buildSmallPrice(isHindi ? 'अधिकतम' : 'Max', price.highestPrice, const Color(0xFFF57F17))),
            ],
          ),

          // Date footer
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.calendar_today, size: 12, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                price.date,
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTag(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildPriceRow(String label, double value, Color color, bool isHindi) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.caption.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: AppTextStyles.headline1.copyWith(fontSize: 34, color: color),
        ),
        Text(
          isHindi ? 'प्रति क्विंटल' : 'per quintal',
          style: AppTextStyles.body2,
        ),
      ],
    );
  }

  Widget _buildSmallPrice(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: AppTextStyles.headline3.copyWith(color: color),
        ),
      ],
    );
  }
}

class _FilterBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _FilterBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.caption.copyWith(fontSize: 10, color: Colors.grey[500]),
                  ),
                  Text(
                    value,
                    style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
