import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../disease/presentation/providers/disease_provider.dart';
import '../providers/market_provider.dart';

class MarketBookScreen extends ConsumerWidget {
  const MarketBookScreen({super.key});

  void _showSelectionDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required List<String> options,
    required String currentValue,
    required Function(String) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppTextStyles.headline3),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
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
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                isHindi ? AppStrings.marketTitleHindi : AppStrings.marketTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(color: AppColors.primary),
            ),
            actions: [
              // Language Toggle
              GestureDetector(
                onTap: () {
                  ref.read(languageProvider.notifier).state =
                      lang == 'hi' ? 'en' : 'hi';
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white38),
                  ),
                  child: Center(
                    child: Text(
                      lang == 'hi' ? 'EN' : 'हि',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildFilters(context, ref, state, isHindi),
                const SizedBox(height: 24),
                if (state.isLoading)
                  const Center(child: Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: CircularProgressIndicator(),
                  ))
                else if (state.error != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            isHindi ? AppStrings.errorNetworkHindi : AppStrings.errorNetwork,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body1,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ref.read(marketProvider.notifier).fetchPrices(),
                            child: Text(isHindi ? AppStrings.tryAgainHindi : AppStrings.tryAgain),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (state.prices.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Text(isHindi ? AppStrings.noMarketDataHindi : AppStrings.noMarketData),
                    ),
                  )
                else
                  ...state.prices.map((price) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildPriceCard(context, price, isHindi),
                  )),
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
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _FilterBox(
              label: isHindi ? AppStrings.commodityHindi : AppStrings.commodity,
              value: state.selectedCommodity,
              icon: Icons.grass,
              onTap: () {
                _showSelectionDialog(
                  context: context,
                  ref: ref,
                  title: isHindi ? AppStrings.selectCommodityHindi : AppStrings.selectCommodity,
                  options: state.availableCommodities,
                  currentValue: state.selectedCommodity,
                  onSelected: (val) => ref.read(marketProvider.notifier).updateFilters(commodity: val),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _FilterBox(
              label: isHindi ? AppStrings.marketHindi : AppStrings.market,
              value: state.selectedMarket,
              icon: Icons.location_on,
              onTap: () {
                _showSelectionDialog(
                  context: context,
                  ref: ref,
                  title: isHindi ? AppStrings.selectMarketHindi : AppStrings.selectMarket,
                  options: state.availableMarkets,
                  currentValue: state.selectedMarket,
                  onSelected: (val) => ref.read(marketProvider.notifier).updateFilters(market: val),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: _FilterBox(
              label: isHindi ? AppStrings.dateHindi : AppStrings.date,
              value: state.selectedDate.split('-').last,
              icon: Icons.calendar_today,
              isSmall: true,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  final dateStr = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                  ref.read(marketProvider.notifier).updateFilters(date: dateStr);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(BuildContext context, dynamic price, bool isHindi) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPriceRow(isHindi ? AppStrings.averagePriceHindi : AppStrings.averagePrice, price.averagePrice, AppColors.primary, isHindi),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Expanded(child: _buildSmallPrice(isHindi ? AppStrings.minPriceHindi : AppStrings.minPrice, price.lowestPrice, AppColors.error)),
              Container(width: 1, height: 40, color: AppColors.divider),
              Expanded(child: _buildSmallPrice(isHindi ? AppStrings.maxPriceHindi : AppStrings.maxPrice, price.highestPrice, AppColors.warning)),
            ],
          ),
        ],
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
        const SizedBox(height: 8),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: AppTextStyles.headline1.copyWith(
            fontSize: 36,
            color: color,
          ),
        ),
        Text(
          isHindi ? AppStrings.perQuintalHindi : AppStrings.perQuintal,
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
  final bool isSmall;

  const _FilterBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(fontSize: 10),
            ),
            Text(
              value,
              style: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: isSmall ? 11 : 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
