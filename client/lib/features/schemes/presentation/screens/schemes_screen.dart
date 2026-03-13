import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../shared/widgets/language_toggle.dart';
import '../../../../router/route_names.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../shared/widgets/language_toggle.dart';
import '../providers/news_provider.dart';
import '../providers/schemes_provider.dart';
import '../widgets/news_card.dart';
import '../widgets/scheme_card.dart';

class SchemesScreen extends ConsumerStatefulWidget {
  const SchemesScreen({super.key});

  @override
  ConsumerState<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends ConsumerState<SchemesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _schemeSearchQuery = '';
  String _newsSearchQuery = '';
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
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)..addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';
    final isSchemesTab = _tabController.index == 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(isHindi),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(isHindi),
                _buildCategoriesSelection(isHindi),
                _buildResultsTitle(isHindi),
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
                  hasScrollBody: false,
                  child: _buildEmptyState(isHindi),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SchemeCard(scheme: filtered[index]),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.error))),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isHindi) {
    return SliverAppBar(
      expandedHeight: 110,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
            ),
          ),
        ),
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        title: Text(
          isHindi ? AppStrings.schemesTitleHindi : AppStrings.schemesTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: const [
        LanguageToggle(color: Colors.white),
        SizedBox(width: 12),
      ],
    );
  }

  Widget _buildSearchBar(bool isHindi) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          onChanged: (val) => setState(() => _searchQuery = val),
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: isHindi ? 'योजनाएं खोजें...' : 'Search schemes...',
            hintStyle: const TextStyle(color: AppColors.textHint, fontWeight: FontWeight.w400),
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(Icons.search_rounded, color: AppColors.primary, size: 24),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSelection(bool isHindi) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat['value']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                    width: 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ] : null,
                ),
                child: Text(
                  isHindi ? cat['hi']! : cat['en']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResultsTitle(bool isHindi) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
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
            isHindi ? 'उपलब्ध योजनाएं' : 'Available Schemes',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isHindi) {
    return Center(
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
            child: SvgPicture.string(AppIcons.schemes, width: 80, height: 80),
          ),
          const SizedBox(height: 16),
          Text(
            isHindi ? 'कोई योजना नहीं मिली' : 'No schemes found',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      )
    );
  }
}
