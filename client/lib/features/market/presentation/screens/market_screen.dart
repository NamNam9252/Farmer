import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/market_provider.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/language_toggle.dart';

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(marketProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('बाज़ार भाव'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go(RouteNames.home);
            }
          },
        ),
        actions: const [
          LanguageToggle(color: Colors.white),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFilters(context, ref, state),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
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
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.search_rounded, size: 20),
                  label: const Text('दाम देखें'),
                ),
              ),
              const SizedBox(height: 16),
              if (state.isLoading)
                const LinearProgressIndicator(
                  minHeight: 3,
                ),
              const SizedBox(height: 8),
              Expanded(
                child: state.prices.isEmpty
                    ? Center(
                        child: Text(
                          'उपलब्ध डेटा देखने के लिए ऊपर से फ़सल, मंडी और तारीख चुनें।',
                          style: AppTextStyles.body2,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        itemCount: state.prices.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = state.prices[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.commodity,
                                          style: AppTextStyles.headline3,
                                        ),
                                      ),
                                      Text(
                                        item.market,
                                        style: AppTextStyles.body2,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'तारीख: ${item.date}',
                                    style: AppTextStyles.caption,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _PriceChip(
                                        label: 'औसत',
                                        value: item.averagePrice,
                                        unit: item.unit,
                                      ),
                                      const SizedBox(width: 8),
                                      _PriceChip(
                                        label: 'न्यूनतम',
                                        value: item.lowestPrice,
                                        unit: item.unit,
                                      ),
                                      const SizedBox(width: 8),
                                      _PriceChip(
                                        label: 'अधिकतम',
                                        value: item.highestPrice,
                                        unit: item.unit,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(
    BuildContext context,
    WidgetRef ref,
    MarketState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _DropdownField<String>(
                label: 'फ़सल चुनें',
                value: state.selectedCommodity,
                items: state.commodities,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(marketProvider.notifier).selectCommodity(value);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DropdownField<String>(
                label: 'मंडी / राज्य',
                value: state.selectedMarket,
                items: state.markets,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(marketProvider.notifier).selectMarket(value);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DateField(
          date: state.selectedDate,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: state.selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              ref.read(marketProvider.notifier).selectDate(picked);
            }
          },
        ),
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: items.contains(value) ? value : null,
          items: items
              .map(
                (e) => DropdownMenuItem<T>(
                  value: e,
                  child: Text(e.toString()),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.date,
    required this.onTap,
  });

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year.toString().padLeft(4, '0')}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'तारीख चुनें',
                  style: AppTextStyles.caption,
                ),
                Text(
                  formatted,
                  style: AppTextStyles.body1,
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  const _PriceChip({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final double value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.caption,
          ),
          const SizedBox(width: 4),
          Text(
            '₹${value.toStringAsFixed(0)}/$unit',
            style: AppTextStyles.body2,
          ),
        ],
      ),
    );
  }
}

