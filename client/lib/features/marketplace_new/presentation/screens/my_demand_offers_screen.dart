import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/marketplace_new_provider.dart';

class MyDemandOffersScreen extends ConsumerStatefulWidget {
  const MyDemandOffersScreen({super.key});

  @override
  ConsumerState<MyDemandOffersScreen> createState() => _MyDemandOffersScreenState();
}

class _MyDemandOffersScreenState extends ConsumerState<MyDemandOffersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() => ref.read(demandOffersProvider.notifier).loadOffers());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(demandOffersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Supply Offers'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.white,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Received'),
                Tab(text: 'My Offers'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOfferList(state.incomingOffers, state.isLoading, true),
          _buildOfferList(state.sentOffers, state.isLoading, false),
        ],
      ),
    );
  }

  Widget _buildOfferList(List<dynamic> offers, bool isLoading, bool isIncoming) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (offers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No offers found', style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: offers.length,
      itemBuilder: (context, index) {
        final offer = offers[index];
        final otherPartyName = isIncoming ? (offer.seller?['name'] ?? 'Seller') : (offer.buyer?['name'] ?? 'Buyer');
        final otherPartyPhone = isIncoming ? (offer.seller?['phone'] ?? '') : (offer.buyer?['phone'] ?? '');
        final status = offer.status as String;

        Color statusColor;
        switch (status) {
          case 'ACCEPTED': statusColor = AppColors.success; break;
          case 'REJECTED': statusColor = AppColors.error; break;
          default: statusColor = AppColors.warning;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                offer.demand?.itemName ?? 'Deleted Demand',
                                style: AppTextStyles.headline3.copyWith(fontSize: 18),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isIncoming ? 'From: $otherPartyName' : 'To: $otherPartyName',
                                style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusChip(status, statusColor),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _infoItem(Icons.scale_outlined, 'Qty: ${offer.quantityAvailable}'),
                        const SizedBox(width: 20),
                        _infoItem(Icons.currency_rupee_rounded, 'Price: ₹${offer.offeredPrice}', isPrimary: true),
                      ],
                    ),
                  ],
                ),
              ),

              if (offer.message != null && offer.message!.toString().isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    offer.message!,
                    style: AppTextStyles.body2.copyWith(fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                  ),
                ),

              // Actions Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (isIncoming && status == 'PENDING') ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => ref.read(demandOffersProvider.notifier).rejectOffer(offer.id),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('REJECT'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => ref.read(demandOffersProvider.notifier).acceptOffer(offer.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          child: const Text('ACCEPT'),
                        ),
                      ),
                    ] else if (status == 'ACCEPTED' && otherPartyPhone.isNotEmpty)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _makePhoneCall(otherPartyPhone),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 2,
                            shadowColor: AppColors.success.withValues(alpha: 0.3),
                          ),
                          icon: const Icon(Icons.call, size: 18),
                          label: Text('CONTACT $otherPartyName'.toUpperCase()),
                        ),
                      )
                    else 
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.divider),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              status == 'REJECTED' ? 'Offer Declined' : 'Waiting for Decision',
                              style: AppTextStyles.body2.copyWith(color: AppColors.textHint),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoItem(IconData icon, String text, {bool isPrimary = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isPrimary ? AppColors.primary : AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: isPrimary ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    // Requires url_launcher
  }
}
