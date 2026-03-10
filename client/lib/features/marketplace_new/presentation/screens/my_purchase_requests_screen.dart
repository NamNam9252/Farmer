import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/marketplace_new_provider.dart';

class MyPurchaseRequestsScreen extends ConsumerStatefulWidget {
  const MyPurchaseRequestsScreen({super.key});

  @override
  ConsumerState<MyPurchaseRequestsScreen> createState() => _MyPurchaseRequestsScreenState();
}

class _MyPurchaseRequestsScreenState extends ConsumerState<MyPurchaseRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() => ref.read(purchaseRequestsProvider.notifier).loadRequests());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Orders & Requests'),
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
                Tab(text: 'Incoming'),
                Tab(text: 'My Requests'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestList(state.incomingRequests, state.isLoading, true),
          _buildRequestList(state.sentRequests, state.isLoading, false),
        ],
      ),
    );
  }

  Widget _buildRequestList(List<dynamic> requests, bool isLoading, bool isIncoming) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No requests found', style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        final otherPartyName = isIncoming ? (req.buyer?['name'] ?? 'Buyer') : (req.seller?['name'] ?? 'Seller');
        final otherPartyPhone = isIncoming ? (req.buyer?['phone'] ?? '') : (req.seller?['phone'] ?? '');
        final status = req.status as String;
        
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
              // Header Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: req.item?.imageUrl != null && req.item!.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: req.item!.imageUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey.shade100),
                            errorWidget: (context, url, error) => Container(color: Colors.grey.shade100, child: const Icon(Icons.image)),
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: AppColors.surface,
                            child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                          ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  req.item?.itemName ?? 'Deleted Item',
                                  style: AppTextStyles.headline3.copyWith(fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _buildStatusChip(status, statusColor),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isIncoming ? 'Buyer: $otherPartyName' : 'Seller: $otherPartyName',
                            style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Req. Quantity: ${req.requestedQuantity}',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              if (req.message != null && req.message!.toString().isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    req.message!,
                    style: AppTextStyles.body2.copyWith(fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (isIncoming && status == 'PENDING') ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => ref.read(purchaseRequestsProvider.notifier).rejectRequest(req.id),
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
                          onPressed: () => ref.read(purchaseRequestsProvider.notifier).acceptRequest(req.id),
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
                              status == 'REJECTED' ? 'Request Declined' : 'Waiting for Response',
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

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
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
    // Implementation for url_launcher
  }
}
