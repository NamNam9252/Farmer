import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../shared/widgets/language_toggle.dart';
import '../providers/schemes_provider.dart';
import '../widgets/scheme_card.dart';

class SchemesScreen extends ConsumerStatefulWidget {
  const SchemesScreen({super.key});

  @override
  ConsumerState<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends ConsumerState<SchemesScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<Map<String, String>> _categories = [
    {'en': 'All', 'hi': 'सभी', 'value': 'All'},
    {'en': 'Seeds', 'hi': 'बीज', 'value': 'SEED'},
    {'en': 'Insurance', 'hi': 'बीमा', 'value': 'INSURANCE'},
    {'en': 'Subsidy', 'hi': 'सब्सिडी', 'value': 'SUBSIDY'},
    {'en': 'Loan', 'hi': 'ऋण', 'value': 'LOAN'},
    {'en': 'Training', 'hi': 'प्रशिक्षण', 'value': 'TRAINING'},
    {'en': 'Equipment', 'hi': 'उपकरण', 'value': 'EQUIPMENT'},
  ];

  @override
  Widget build(BuildContext context) {
    final schemesAsync = ref.watch(schemesControllerProvider);
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              isHindi ? AppStrings.schemesTitleHindi : AppStrings.schemesTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            actions: const [
              LanguageToggle(color: Colors.white),
              SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: isHindi ? 'योजनाएं खोजें...' : 'Search schemes...',
                        hintStyle: const TextStyle(color: AppColors.textHint),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      ),
                    ),
                  ),
                ),

                // Categories
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat['value'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(isHindi ? cat['hi']! : cat['en']!),
                          selected: isSelected,
                          onSelected: (val) => setState(() => _selectedCategory = cat['value']!),
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.divider,
                            ),
                          ),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Text(
                    isHindi ? 'उपलब्ध योजनाएं' : 'Available Schemes',
                    style: AppTextStyles.headline3,
                  ),
                ),
              ],
            ),
          ),
          schemesAsync.when(
            data: (schemes) {
              final filtered = schemes.where((s) {
                final titleMatch = s.title.toLowerCase().contains(_searchQuery.toLowerCase());
                final catMatch = _selectedCategory == 'All' || 
                                  (s.category?.toUpperCase() == _selectedCategory);
                return titleMatch && catMatch;
              }).toList();

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: AppColors.textHint.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text(
                          isHindi ? 'कोई योजना नहीं मिली' : 'No schemes found',
                          style: const TextStyle(color: AppColors.textHint, fontSize: 16),
                        ),
                      ],
                    )
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SchemeCard(scheme: filtered[index]),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              );
            },
            loading: () => SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
