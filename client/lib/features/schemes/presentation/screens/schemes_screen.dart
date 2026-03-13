import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isHindi ? 'समाचार और योजनाएं' : 'News and Schemes',
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: isHindi ? 'योजनाएं' : 'Schemes'),
            Tab(text: isHindi ? 'समाचार' : 'News'),
          ],
        ),
      ),
      body: Column(
        children: [
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
                onChanged: (val) {
                  setState(() {
                    if (isSchemesTab) {
                      _schemeSearchQuery = val;
                    } else {
                      _newsSearchQuery = val;
                    }
                  });
                },
                decoration: InputDecoration(
                  hintText:
                      isSchemesTab
                          ? (isHindi ? 'योजनाएं खोजें...' : 'Search schemes...')
                          : (isHindi ? 'समाचार खोजें...' : 'Search news...'),
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ),
                ),
              ),
            ),
          ),
          if (isSchemesTab)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children:
                    _categories.map((cat) {
                      final isSelected = _selectedCategory == cat['value'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(isHindi ? cat['hi']! : cat['en']!),
                          selected: isSelected,
                          onSelected:
                              (_) => setState(
                                () => _selectedCategory = cat['value']!,
                              ),
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color:
                                isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : AppColors.divider,
                            ),
                          ),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
              ),
            ),
          const SizedBox(height: 10),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildSchemesTab(isHindi), _buildNewsTab(isHindi)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchemesTab(bool isHindi) {
    final schemesAsync = ref.watch(schemesControllerProvider);

    return schemesAsync.when(
      data: (schemes) {
        final filtered =
            schemes.where((s) {
              final titleMatch = s.title.toLowerCase().contains(
                _schemeSearchQuery.toLowerCase(),
              );
              final catMatch =
                  _selectedCategory == 'All' ||
                  (s.category?.toUpperCase() == _selectedCategory);
              return titleMatch && catMatch;
            }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 64,
                  color: AppColors.textHint.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  isHindi ? 'कोई योजना नहीं मिली' : 'No schemes found',
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SchemeCard(scheme: filtered[index], isHindi: isHindi),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildNewsTab(bool isHindi) {
    final newsAsync = ref.watch(newsProvider);

    return newsAsync.when(
      data: (newsItems) {
        final filtered =
            newsItems.where((n) {
              final q = _newsSearchQuery.toLowerCase();
              return n.title.toLowerCase().contains(q) ||
                  n.content.toLowerCase().contains(q) ||
                  (n.source ?? '').toLowerCase().contains(q);
            }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 64,
                  color: AppColors.textHint.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  isHindi ? 'कोई समाचार नहीं मिला' : 'No news found',
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NewsCard(news: filtered[index], isHindi: isHindi),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}