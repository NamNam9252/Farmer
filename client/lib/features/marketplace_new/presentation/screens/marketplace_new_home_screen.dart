import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../router/route_names.dart';
import '../providers/marketplace_new_provider.dart';
import '../../../../shared/widgets/shared_app_bar.dart';
import '../widgets/marketplace_rental_toggle.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state.dart';

class MarketplaceNewHomeScreen extends ConsumerStatefulWidget {
  const MarketplaceNewHomeScreen({super.key});

  @override
  ConsumerState<MarketplaceNewHomeScreen> createState() => _MarketplaceNewHomeScreenState();
}

class _MarketplaceNewHomeScreenState extends ConsumerState<MarketplaceNewHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final authState = ref.read(authControllerProvider);
    if (authState is Authenticated) {
      final userId = authState.user.id;
      ref.read(marketplaceItemsProvider.notifier).loadItems();
      ref.read(marketplaceDemandsProvider.notifier).loadDemands();
      ref.read(marketplaceMyItemsProvider.notifier).loadUserItems(userId);
      ref.read(marketplaceMyDemandsProvider.notifier).loadUserDemands(userId);
      ref.read(purchaseRequestsProvider.notifier).loadRequests();
      ref.read(demandOffersProvider.notifier).loadOffers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';
    final authState = ref.watch(authControllerProvider);
    final userId = authState is Authenticated ? authState.user.id : '';

    return Scaffold(
      backgroundColor: AppColors.skyLight,
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ── Sticky Marketplace Header ──
            SharedStickyHeader(
              title: 'Marketplace',
              backgroundImage: 'assets/images/service_icons/marketplace.png',
              subtitle: isHindi ? 'सीधी बिक्री. कोई बिचौलिया नहीं।' : 'Sell Direct. No Middlemen.',
              showBackButton: true,
              onBack: () => context.go('/'),
              expandedHeight: 180,
              collapsedHeight: 100,
            ),

            // ── Body ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MarketplaceRentalToggle(
                              isHindi: isHindi,
                              marketplaceSelected: true,
                            ),
                            const SizedBox(height: 20),
                            _buildManagementShortcuts(context, isHindi),
                            const SizedBox(height: 20),
                            _buildActionGrid(context, isHindi),
                            const SizedBox(height: 24),
                            _buildFeaturedHeader(context, isHindi),
                            const _MyActiveListings(),
                            const SizedBox(height: 20),
                            _buildMySectionHeader(
                              context,
                              isHindi ? 'मेरी मांग' : 'My Demands',
                              () => context.push(RouteNames.myListings),
                            ),
                            _MyDemands(userId: userId),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildManagementShortcuts(BuildContext context, bool isHindi) {
    return Row(
        children: [
          Expanded(
            child: _ShortcutButton(
              label: isHindi ? 'खरीद अनुरोध' : 'Requests',
              icon: Icons.mark_email_unread_rounded,
              onTap: () => context.push(RouteNames.myPurchaseRequests),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ShortcutButton(
              label: isHindi ? 'आपूर्ति प्रस्ताव' : 'Offers',
              icon: Icons.local_offer_rounded,
              onTap: () => context.push(RouteNames.myDemandOffers),
            ),
          ),
        ],
      );
  }

  Widget _buildActionGrid(BuildContext context, bool isHindi) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 0.95,
      children: [
        _ActionCard(
          label: isHindi ? 'हार्वेस्ट लिस्ट करें' : 'List Your Harvest',
          subtitle: isHindi ? '(आइटम पोस्ट करें)' : '(Post Item)',
          icon: Icons.agriculture_rounded,
          color: AppColors.cardMint,
          iconColor: AppColors.primary,
          onTap: () => context.push(RouteNames.postItem),
        ),
        _ActionCard(
          label: isHindi ? 'उपज ब्राउज़ करें' : 'Browse Produce',
          subtitle: isHindi ? '(आइटम देखें)' : '(Browse Items)',
          icon: Icons.shopping_cart_rounded,
          color: AppColors.cardSky,
          iconColor: const Color(0xFF1565C0),
          onTap: () => context.push(RouteNames.browseItems),
        ),
        _ActionCard(
          label: isHindi ? 'मांग पोस्ट करें' : 'Post Your Demand',
          subtitle: isHindi ? '(मांग पोस्ट करें)' : '(Post Demand)',
          icon: Icons.campaign_rounded,
          color: AppColors.cardPeach,
          iconColor: const Color(0xFFF57C00),
          onTap: () => context.push(RouteNames.postDemand),
        ),
        _ActionCard(
          label: isHindi ? 'मांग खोजें' : 'Search Demands',
          subtitle: isHindi ? '(मांग ब्राउज़ करें)' : '(Browse Demands)',
          icon: Icons.search_rounded,
          color: AppColors.cardLavender,
          iconColor: const Color(0xFF7B1FA2),
          onTap: () => context.push(RouteNames.browseDemands),
        ),
      ],
    );
  }

  Widget _buildFeaturedHeader(BuildContext context, bool isHindi) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isHindi ? 'फीचर्ड आइटम' : 'Featured Items',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: () => context.push(RouteNames.browseItems),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                isHindi ? 'सभी देखें' : 'View All',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMySectionHeader(BuildContext context, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.label,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: iconColor.withValues(alpha: 0.12), width: 1),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: iconColor),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MyActiveListings extends ConsumerWidget {
  const _MyActiveListings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(marketplaceMyItemsProvider);
    
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('No active listings', style: AppTextStyles.body2),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: state.items.length,
        itemBuilder: (context, index) {
          final item = state.items[index];
          return GestureDetector(
            onTap: () => context.push(RouteNames.itemDetail, extra: item),
            child: Container(
              width: 152,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: AppColors.warmCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.skyLight,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        image: item.imageUrl != null && item.imageUrl!.isNotEmpty
                          ? DecorationImage(image: NetworkImage(item.imageUrl!), fit: BoxFit.cover)
                          : null,
                      ),
                      child: item.imageUrl == null || item.imageUrl!.isEmpty
                        ? Center(child: Icon(Icons.eco_rounded, color: AppColors.primary.withValues(alpha: 0.5), size: 32))
                        : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.itemName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${item.pricePerUnit}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MyDemands extends ConsumerWidget {
  final String userId;
  const _MyDemands({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(marketplaceMyDemandsProvider);
    final myDemands = state.demands;
    
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (myDemands.isEmpty) {
       return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('No active demands', style: AppTextStyles.body2),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: myDemands.length,
        itemBuilder: (context, index) {
          final demand = myDemands[index];
          return GestureDetector(
            onTap: () => context.push(RouteNames.demandDetail, extra: demand),
            child: Container(
              width: 200,
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warmCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    demand.itemName, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Needed: ${demand.quantityNeeded}', 
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    'Target: ₹${demand.expectedPrice}', 
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShortcutButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ShortcutButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.warmCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
