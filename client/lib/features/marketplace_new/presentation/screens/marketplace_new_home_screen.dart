import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../router/route_names.dart';
import '../providers/marketplace_new_provider.dart';
import '../../../../shared/widgets/shared_app_bar.dart';

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
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SharedHeader(
            title: isHindi ? 'मार्केटप्लेस' : 'Marketplace',
            subtitle: isHindi
                ? 'सीधी बिक्री. कोई बिचौलिया नहीं।'
                : 'Sell Direct. No Middlemen.',
            onLeadingPressed: () => context.go('/'),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _loadData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildManagementShortcuts(context, isHindi),
              const SizedBox(height: 24),
              _buildActionGrid(context, isHindi),
              const SizedBox(height: 32),
              _buildMySectionHeader(
                context, 
                isHindi ? 'मेरे आइटम' : 'My Items', 
                () => context.push(RouteNames.myListings),
              ),
              const _MyActiveListings(),
              const SizedBox(height: 24),
              _buildMySectionHeader(
                context, 
                isHindi ? 'मेरी मांग' : 'My Demands', 
                () => context.push(RouteNames.myListings),
              ),
              _MyDemands(userId: userId),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildManagementShortcuts(BuildContext context, bool isHindi) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
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
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context, bool isHindi) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: [
          _ActionCard(
            label: isHindi ? 'बेचने के लिए आइटम डालें' : 'Post Item to Sell',
            icon: Icons.add_business_rounded,
            color: const Color(0xFFE8F5E9),
            iconColor: Colors.green[800]!,
            onTap: () => context.push(RouteNames.postItem),
          ),
          _ActionCard(
            label: isHindi ? 'अपनी मांग डालें' : 'Post Demand',
            icon: Icons.record_voice_over_rounded,
            color: const Color(0xFFFFF3E0),
            iconColor: Colors.orange[800]!,
            onTap: () => context.push(RouteNames.postDemand),
          ),
          _ActionCard(
            label: isHindi ? 'आइटम देखें' : 'Browse Items',
            icon: Icons.shopping_basket_rounded,
            color: const Color(0xFFE3F2FD),
            iconColor: Colors.blue[800]!,
            onTap: () => context.push(RouteNames.browseItems),
          ),
          _ActionCard(
            label: isHindi ? 'खरीदार खोजें' : 'Browse Demands',
            icon: Icons.find_in_page_rounded,
            color: const Color(0xFFF3E5F5),
            iconColor: Colors.purple[800]!,
            onTap: () => context.push(RouteNames.browseDemands),
          ),
        ],
      ),
    );
  }

  Widget _buildMySectionHeader(BuildContext context, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.headline2),
          TextButton(
            onPressed: onTap,
            child: const Text('View All'),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: iconColor.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: iconColor),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: iconColor,
              ),
            ),
          ],
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
              width: 150,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        image: item.imageUrl != null && item.imageUrl!.isNotEmpty
                          ? DecorationImage(image: NetworkImage(item.imageUrl!), fit: BoxFit.cover)
                          : null,
                      ),
                      child: item.imageUrl == null || item.imageUrl!.isEmpty
                        ? const Center(child: Icon(Icons.image_outlined, color: Colors.grey))
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${item.pricePerUnit}', 
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
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
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
