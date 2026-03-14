import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/services/language_provider.dart';
import '../providers/market_provider.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/shared_app_bar.dart';

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(marketProvider);
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context, ref),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildFiltersArea(context, ref, state, isHindi),
                const SizedBox(height: 24),
                _buildSearchButton(context, ref, state, isHindi),
                const SizedBox(height: 24),
                _buildResultsHeader(state, isHindi),
                const SizedBox(height: 12),
                if (state.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      backgroundColor: Color(0xFFE8F5E9),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
              ]),
            ),
          ),
          if (state.prices.isEmpty && !state.isLoading)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(isHindi),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = state.filteredPrices[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PriceCard(item: item),
                    );
                  },
                  childCount: state.filteredPrices.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';
    return SharedStickyHeader(
      title: isHindi ? 'बाज़ार भाव' : 'Market Prices',
      subtitle: isHindi 
          ? 'मंडियों से फसलों के वास्तविक समय के भाव' 
          : 'Real-time commodity prices from mandis',
      backgroundImage: 'assets/images/service_icons/market.png',
    );
  }

  Widget _buildFiltersArea(BuildContext context, WidgetRef ref, MarketState state, bool isHindi) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _IllustratedSelector(
                label: isHindi ? 'फ़सल चुनें' : 'Select Crop',
                value: state.selectedCommodity.isEmpty
                    ? (isHindi ? 'सभी' : 'All')
                    : state.selectedCommodity,
                svgData: AppIcons.market,
                onTap: () => _showDropdownPicker(
                  context,
                  title: isHindi ? 'फ़सल चुनें' : 'Select Crop',
                  items: state.availableCommodities,
                  selected: state.selectedCommodity,
                  onSelect: (val) => ref.read(marketProvider.notifier).updateCommodity(val),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _IllustratedSelector(
                label: isHindi ? 'राज्य' : 'State',
                value: state.selectedState.isEmpty
                    ? (isHindi ? 'चुनें' : 'Select')
                    : state.selectedState,
                svgData: AppIcons.locationAction,
                onTap: () => _showDropdownPicker(
                  context,
                  title: isHindi ? 'राज्य चुनें' : 'Select State',
                  items: state.availableStates,
                  selected: state.selectedState,
                  onSelect: (val) => ref.read(marketProvider.notifier).updateState(val),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _IllustratedSelector(
          label: isHindi ? 'जिला चुनें' : 'Select District',
          value: state.selectedDistrict.isEmpty
              ? (isHindi ? 'सभी जिले' : 'All Districts')
              : state.selectedDistrict,
          svgData: AppIcons.calendarAction,
          isFullWidth: true,
          onTap: () => _showDropdownPicker(
            context,
            title: isHindi ? 'जिला चुनें' : 'Select District',
            items: state.availableDistricts,
            selected: state.selectedDistrict,
            onSelect: (val) => ref.read(marketProvider.notifier).updateDistrict(val),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchButton(BuildContext context, WidgetRef ref, MarketState state, bool isHindi) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: state.isLoading
            ? null
            : () async {
                await ref.read(marketProvider.notifier).fetchPrices();
                final error = ref.read(marketProvider).error;
                if (error != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
        icon: const Icon(Icons.search_rounded, color: Colors.white, size: 22),
        label: Text(
          isHindi ? 'दाम देखें' : 'Search Prices',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildResultsHeader(MarketState state, bool isHindi) {
    if (state.prices.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isHindi ? 'ताज़ा भाव (${state.filteredPrices.length})' : 'Latest Prices (${state.filteredPrices.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isHindi) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20),
                ],
              ),
              child: SvgPicture.string(AppIcons.market, width: 80, height: 80),
            ),
            const SizedBox(height: 24),
            Text(
              isHindi ? 'जानकारी उपलब्ध नहीं है' : 'No data available',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              isHindi
                  ? 'उपलब्ध डेटा देखने के लिए ऊपर से फ़सल और राज्य चुनें।'
                  : 'Select a crop and state above to see available prices.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  void _showDropdownPicker(
    BuildContext context, {
    required String title,
    required List<String> items,
    required String? selected,
    required Function(String) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = item == selected;
                    return ListTile(
                      title: Text(
                        item,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                      onTap: () {
                        onSelect(item);
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
  }
}

class _IllustratedSelector extends StatelessWidget {
  const _IllustratedSelector({
    required this.label,
    required this.value,
    required this.svgData,
    required this.onTap,
    this.isFullWidth = false,
  });

  final String label;
  final String value;
  final String svgData;
  final VoidCallback onTap;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.string(svgData, width: 24, height: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.expand_more_rounded, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.item});
  final dynamic item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.commodity,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.market,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${item.district}, ${item.state}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _CircularPrice(label: 'औसत', price: item.averagePrice, unit: item.unit, color: Colors.blue),
              const Spacer(),
              _CircularPrice(label: 'न्यूनतम', price: item.lowestPrice, unit: item.unit, color: Colors.orange),
              const Spacer(),
              _CircularPrice(label: 'अधिकतम', price: item.highestPrice, unit: item.unit, color: Colors.green),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircularPrice extends StatelessWidget {
  const _CircularPrice({
    required this.label,
    required this.price,
    required this.unit,
    required this.color,
  });

  final String label;
  final double price;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Text(
            '₹${price.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$label (/$unit)',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
