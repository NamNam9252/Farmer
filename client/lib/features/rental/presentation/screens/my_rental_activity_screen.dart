import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../router/route_names.dart';
import '../../../../shared/widgets/shared_app_bar.dart';
import '../../data/models/rental_models.dart';
import '../providers/rental_providers.dart';
import '../widgets/rental_asset_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state.dart';

class MyRentalActivityScreen extends ConsumerStatefulWidget {
  const MyRentalActivityScreen({super.key});

  @override
  ConsumerState<MyRentalActivityScreen> createState() => _MyRentalActivityScreenState();
}

class _MyRentalActivityScreenState extends ConsumerState<MyRentalActivityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  void _loadData() {
    Future.microtask(() {
      ref.read(myAssetsProvider.notifier).loadMyAssets();
      ref.read(myBidsProvider.notifier).loadMyBids();
      ref.read(myRentalsProvider.notifier).loadRentals();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final isHindi = language == 'hi';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SharedStickyHeader(
            title: isHindi ? 'मेरी रेंटल गतिविधि' : 'My Rental Activity',
            subtitle: isHindi ? 'अपने रेंटल प्रबंधित करें' : 'Manage your rentals',
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorWeight: 3,
              tabs: [
                Tab(text: isHindi ? 'मेरी सूचियाँ' : 'My Listings'),
                Tab(text: isHindi ? 'मेरी बोलियाँ' : 'My Bids'),
                Tab(text: isHindi ? 'मेरे रेंटल' : 'My Rentals'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _MyListingsTab(isHindi: isHindi),
            _MyBidsTab(isHindi: isHindi),
            _MyRentalsTab(isHindi: isHindi),
          ],
        ),
      ),
    );
  }
}

class _MyListingsTab extends ConsumerWidget {
  final bool isHindi;
  const _MyListingsTab({required this.isHindi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myAssetsProvider);

    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.assets.isEmpty) {
      return Center(child: Text(isHindi ? 'कोई लिस्टिंग नहीं मिली' : 'No listings found'));
    }

    final authState = ref.watch(authControllerProvider);
    final currentUserId = authState is Authenticated ? authState.user.id : null;

    return RefreshIndicator(
      onRefresh: () async => ref.read(myAssetsProvider.notifier).loadMyAssets(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.assets.length,
        itemBuilder: (context, index) {
          final asset = state.assets[index];
          return RentalAssetCard(
            asset: asset,
            isHindi: isHindi,
            currentUserId: currentUserId,
            onTap: () => context.push(RouteNames.rentalAssetDetail.replaceAll(':id', asset.id), extra: asset),
          );
        },
      ),
    );
  }
}

class _MyBidsTab extends ConsumerWidget {
  final bool isHindi;
  const _MyBidsTab({required this.isHindi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myBidsProvider);
    
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.bids.isEmpty) {
      return Center(child: Text(isHindi ? 'कोई बोली नहीं मिली' : 'No bids found'));
    }

    return RefreshIndicator(
      onRefresh: () async => ref.read(myBidsProvider.notifier).loadMyBids(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.bids.length,
        itemBuilder: (context, index) {
          final bid = state.bids[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              title: Text(bid.asset?.title ?? 'Asset', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bid: ₹${bid.amount}/day'),
                  const SizedBox(height: 4),
                  _StatusBadge(status: bid.status),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => context.push(RouteNames.rentalAssetDetail.replaceAll(':id', bid.assetId)),
            ),
          );
        },
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BidStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case BidStatus.PENDING: color = Colors.orange; break;
      case BidStatus.ACCEPTED: color = Colors.green; break;
      case BidStatus.REJECTED: color = Colors.red; break;
      case BidStatus.WITHDRAWN: color = Colors.grey; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.name,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _MyRentalsTab extends ConsumerWidget {
  final bool isHindi;
  const _MyRentalsTab({required this.isHindi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myRentalsProvider);
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.rentals.isEmpty) return Center(child: Text(isHindi ? 'कोई रेंटल नहीं' : 'No active rentals'));

    return RefreshIndicator(
      onRefresh: () async => ref.read(myRentalsProvider.notifier).loadRentals(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.rentals.length,
        itemBuilder: (context, index) {
          final rental = state.rentals[index];
          final daysLeft = rental.endDate.difference(DateTime.now()).inDays;
          final ownerPhone = rental.asset?.owner?['phone']?.toString() ?? '';
          final showCallButton = ownerPhone.trim().isNotEmpty &&
              (rental.status == RentalStatus.UPCOMING || rental.status == RentalStatus.ACTIVE);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(rental.asset?.title ?? (isHindi ? 'किराये की वस्तु' : 'Rental Item'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(rental.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        rental.status.name,
                        style: TextStyle(color: _getStatusColor(rental.status), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.date_range_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text('${_formatDate(rental.startDate)} - ${_formatDate(rental.endDate)}', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    const Spacer(),
                    if (daysLeft > 0 && rental.status == RentalStatus.ACTIVE)
                      Text(
                        isHindi ? '$daysLeft दिन शेष' : '$daysLeft days left',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: const Icon(Icons.currency_rupee_rounded, size: 14, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₹${rental.agreedPrice}/day',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                if (showCallButton) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _makePhoneCall(context, ownerPhone),
                      icon: const Icon(Icons.call_rounded, size: 18),
                      label: Text(isHindi ? 'मालिक को कॉल करें' : 'Call Owner'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(RentalStatus status) {
    switch (status) {
      case RentalStatus.UPCOMING: return Colors.blue;
      case RentalStatus.ACTIVE: return Colors.green;
      case RentalStatus.COMPLETED: return Colors.grey;
      case RentalStatus.CANCELLED: return Colors.red;
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri(scheme: 'tel', path: phoneNumber.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('Could not open phone dialer')),
    );
  }
}
