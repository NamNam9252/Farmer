import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/shared_app_bar.dart';
import '../providers/rental_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../../marketplace_new/presentation/widgets/marketplace_rental_toggle.dart';

class RentalHomeScreen extends ConsumerStatefulWidget {
  const RentalHomeScreen({super.key});

  @override
  ConsumerState<RentalHomeScreen> createState() => _RentalHomeScreenState();
}

class _RentalHomeScreenState extends ConsumerState<RentalHomeScreen> {
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
      ref.read(myAssetsProvider.notifier).loadMyAssets();
      ref.read(myRentalsProvider.notifier).loadRentals();
      ref.read(myBidsProvider.notifier).loadMyBids();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SharedStickyHeader(
            title: isHindi ? 'रेंटल हब' : 'Rental Hub',
            subtitle: isHindi
                ? 'उपकरण और जमीन किराए पर लें या दें'
                : 'Rent or Lease Equipment & Land',
            backgroundImage: 'assets/images/service_icons/marketplace.png',
            onBack: () => context.go(RouteNames.marketplaceNew),
          ),
          SliverToBoxAdapter(
            child: MarketplaceRentalToggle(
              isHindi: isHindi,
              marketplaceSelected: false,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(top: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildManagementShortcuts(context, isHindi),
                const SizedBox(height: 24),
                _buildActionGrid(context, isHindi),
                const SizedBox(height: 32),
                _buildSectionHeader(
                  context, 
                  isHindi ? 'मेरी सक्रिय लिस्टिंग' : 'My Active Listings', 
                  () => context.push(RouteNames.myRentalActivity),
                ),
                const _MyActiveAssetsList(),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  context, 
                  isHindi ? 'मेरे सक्रिय रेंटल' : 'My Active Rentals', 
                  () => context.push(RouteNames.myRentalActivity),
                ),
                const _MyActiveRentalsList(),
                const SizedBox(height: 120),
              ]),
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
              label: isHindi ? 'प्राप्त बोलियां' : 'Received Bids',
              icon: Icons.assignment_returned_rounded,
              onTap: () => context.push(RouteNames.myRentalActivity),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ShortcutButton(
              label: isHindi ? 'भेजी गई बोलियां' : 'Sent Bids',
              icon: Icons.send_rounded,
              onTap: () => context.push(RouteNames.myRentalActivity),
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
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.95,
        children: [
          _ActionCard(
            label: isHindi ? 'रेंटल पोस्ट करें' : 'Post Rental',
            subtitle: isHindi ? '(किराये पर दें)' : '(List for Rent)',
            icon: Icons.add_circle_outline_rounded,
            color: AppColors.cardMint,
            iconColor: AppColors.primary,
            onTap: () => context.push(RouteNames.postRentalAsset),
          ),
          _ActionCard(
            label: isHindi ? 'रेंटल ब्राउज़ करें' : 'Browse Rentals',
            subtitle: isHindi ? '(किराये पर लें)' : '(Rent from Others)',
            icon: Icons.search_rounded,
            color: AppColors.cardSky,
            iconColor: const Color(0xFF1565C0),
            onTap: () => context.push(RouteNames.browseRentals),
          ),
          _ActionCard(
            label: isHindi ? 'मेरी लिस्टिंग' : 'My Listings',
            subtitle: isHindi ? '(प्रबंधित करें)' : '(Manage)',
            icon: Icons.inventory_2_rounded,
            color: AppColors.cardLavender,
            iconColor: const Color(0xFF7B1FA2),
            onTap: () => context.push(RouteNames.myRentalActivity),
          ),
          _ActionCard(
            label: isHindi ? 'मेरी बोलियां' : 'My Bids',
            subtitle: isHindi ? '(बोली देखें)' : '(View Bids)',
            icon: Icons.gavel_rounded,
            color: const Color(0xFFFFF3E0),
            iconColor: const Color(0xFFE65100),
            onTap: () => context.push(RouteNames.myRentalActivity),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
    return GestureDetector(
      onTap: onTap,
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

class _MyActiveAssetsList extends ConsumerWidget {
  const _MyActiveAssetsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myAssetsProvider);
    
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.assets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('No active listings', style: TextStyle(color: Colors.grey, fontSize: 14)),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: state.assets.length,
        itemBuilder: (context, index) {
          final asset = state.assets[index];
          return GestureDetector(
            onTap: () => context.push(RouteNames.rentalAssetDetail.replaceAll(':id', asset.id), extra: asset),
            child: Container(
              width: 180,
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
                    asset.title, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${asset.basePrice}/day', 
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(Icons.vignette_rounded, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(asset.type.name, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    ],
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

class _MyActiveRentalsList extends ConsumerWidget {
  const _MyActiveRentalsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myRentalsProvider);
    
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.rentals.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('No active rentals', style: TextStyle(color: Colors.grey, fontSize: 14)),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: state.rentals.length,
        itemBuilder: (context, index) {
          final rental = state.rentals[index];
          return Container(
            width: 220,
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
                  rental.asset?.title ?? 'Rental Item', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${rental.agreedPrice}/day', 
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${rental.endDate.difference(DateTime.now()).inDays} days left', 
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    Text(
                      rental.status.name,
                      style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
