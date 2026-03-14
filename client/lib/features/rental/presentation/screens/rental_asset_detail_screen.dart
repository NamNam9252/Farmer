import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_app_bar.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../router/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../data/models/rental_models.dart';
import '../providers/rental_providers.dart';

class RentalAssetDetailScreen extends ConsumerStatefulWidget {
  final RentalAsset? asset;
  final String assetId;

  const RentalAssetDetailScreen({
    super.key,
    this.asset,
    required this.assetId,
  });

  @override
  ConsumerState<RentalAssetDetailScreen> createState() => _RentalAssetDetailScreenState();
}

class _RentalAssetDetailScreenState extends ConsumerState<RentalAssetDetailScreen> {
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 8));

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(myBidsProvider.notifier).loadAssetBids(widget.assetId);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = ref.watch(languageProvider) == 'hi';
    final bidsState = ref.watch(myBidsProvider);
    final asset = widget.asset;

    if (asset == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final authState = ref.watch(authControllerProvider);
    final currentUser = authState is Authenticated ? authState.user : null;
    final isOwner = currentUser != null && asset.owner?['id'] == currentUser.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SharedStickyHeader(
            title: isHindi ? 'रेंटल विवरण' : 'Rental Details',
            subtitle: asset.title,
            actions: [
              if (isOwner) ...[
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  onPressed: () => context.push(RouteNames.postRentalAsset, extra: asset),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.white),
                  onPressed: () => _confirmDelete(context, ref, asset.id, isHindi),
                ),
              ],
            ],
          ),
          if (asset.imageUrl != null)
            SliverToBoxAdapter(
              child: Container(
                height: 250,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  image: DecorationImage(
                    image: NetworkImage(asset.imageUrl!),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildAssetHeader(asset, isHindi),
                const SizedBox(height: 24),
                _buildDescription(asset, isHindi),
                const SizedBox(height: 24),
                _buildOwnerSection(asset, isHindi),
                const SizedBox(height: 32),
                _buildBidsSection(bidsState, isHindi, asset, isOwner),
                const SizedBox(height: 100), // Space for bottom button
              ]),
            ),
          ),
        ],
      ),
      bottomSheet: isOwner ? null : _buildBidAction(context, asset, isHindi),
    );
  }

  Widget _buildAssetHeader(RentalAsset asset, bool isHindi) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isHindi ? _getTypeNameHindi(asset.type) : asset.type.name,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '₹${asset.basePrice}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                isHindi ? ' /प्रति दिन' : ' /day',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            asset.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                isHindi ? 'सूचीबद्ध तिथि: ${_formatDate(asset.createdAt)}' : 'Listed on: ${_formatDate(asset.createdAt)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(RentalAsset asset, bool isHindi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isHindi ? 'विवरण' : 'Description',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          asset.description,
          style: TextStyle(color: Colors.grey[800], fontSize: 15, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildOwnerSection(RentalAsset asset, bool isHindi) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: const Icon(Icons.person_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.owner?['name'] ?? asset.owner?['email'] ?? (isHindi ? 'अज्ञात' : 'Unknown'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
            onPressed: () {
              // Navigate to chat
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBidsSection(RentalBidsState state, bool isHindi, RentalAsset asset, bool isOwner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isHindi ? 'हाल ही की बोलियां' : 'Recent Bids',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${state.bids.length} ${isHindi ? 'बोलियां' : 'Bids'}',
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (state.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (state.bids.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                isHindi ? 'अभी तक कोई बोली नहीं' : 'No bids yet',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.bids.length,
            itemBuilder: (context, index) {
              final bid = state.bids[index];
              return _BidCard(
                bid: bid,
                isHindi: isHindi,
                isOwner: isOwner,
                onAccept: () => _handleAcceptBid(ref, asset.id, bid.id),
              );
            },
          ),
      ],
    );
  }

  Future<void> _handleAcceptBid(WidgetRef ref, String assetId, String bidId) async {
    try {
      await ref.read(rentalBidsProvider(assetId).notifier).acceptBid(assetId, bidId);
      ref.invalidate(rentalAssetProvider(assetId)); // Refresh asset to see LOCKED status
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bid accepted successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildBidAction(BuildContext context, RentalAsset asset, bool isHindi) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _showBidSheet(context, asset, isHindi),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          isHindi ? 'अपनी बोली लगाएं' : 'Place Your Bid',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showBidSheet(BuildContext context, RentalAsset asset, bool isHindi) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isHindi ? 'अपनी बोली लगाएं' : 'Place Your Bid',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  isHindi 
                      ? 'मालिक को अपना सर्वश्रेष्ठ ऑफर भेजें' 
                      : 'Send your best offer to the owner',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isHindi ? 'बोली की राशि (₹/दिन)' : 'Bid Amount (₹/day)',
                    prefixIcon: const Icon(Icons.currency_rupee_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.date_range_rounded, color: AppColors.primary),
                  title: Text(isHindi ? 'किराये की अवधि' : 'Rental Duration'),
                  subtitle: Text('${_formatDate(_startDate)} - ${_formatDate(_endDate)}'),
                  trailing: TextButton(
                    onPressed: () async {
                      await _selectDateRange(context);
                      setModalState(() {});
                    },
                    child: Text(isHindi ? 'बदलें' : 'Change'),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _messageController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: isHindi ? 'एक संदेश जोड़ें (वैकल्पिक)' : 'Add a message (optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    if (_amountController.text.isEmpty) return;
                    
                    try {
                      final amount = double.parse(_amountController.text);
                      await ref.read(rentalRepositoryProvider).placeBid(
                        asset.id,
                        {
                          'amount': amount,
                          'startDate': _startDate.toUtc().toIso8601String(),
                          'endDate': _endDate.toUtc().toIso8601String(),
                          'message': _messageController.text,
                        },
                      );
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        ref.read(myBidsProvider.notifier).loadAssetBids(asset.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isHindi ? 'बोली सफलतापूर्वक लगाई गई!' : 'Bid placed successfully!')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(isHindi ? 'बोली सबमिट करें' : 'Submit Bid'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTypeNameHindi(AssetType type) {
    switch (type) {
      case AssetType.PROPERTY: return 'जमीन';
      case AssetType.VEHICLE: return 'वाहन';
      case AssetType.EQUIPMENT: return 'उपकरण';
      case AssetType.OTHER: return 'अन्य';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String assetId, bool isHindi) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isHindi ? 'लिस्टिंग हटाएं?' : 'Delete Listing?'),
        content: Text(isHindi ? 'यह क्रिया वापस नहीं ली जा सकती। क्या आप सुनिश्चित हैं?' : 'This action cannot be undone. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(isHindi ? 'रद्द करें' : 'Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(isHindi ? 'हटाएं' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(myAssetsProvider.notifier).deleteAsset(assetId);
      if (context.mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isHindi ? 'लिस्टिंग हटा दी गई' : 'Asset deleted')));
      }
    }
  }
}

class _BidCard extends StatelessWidget {
  final RentalBid bid;
  final bool isHindi;
  final bool isOwner;
  final VoidCallback? onAccept;

  const _BidCard({
    required this.bid,
    required this.isHindi,
    this.isOwner = false,
    this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(Icons.person_rounded, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bid.bidder?['name'] ?? bid.bidder?['email'] ?? (isHindi ? 'बोली लगाने वाला' : 'Bidder'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${bid.amount}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
              ),
            ],
          ),
          if (bid.message != null && bid.message!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              bid.message!,
              style: TextStyle(color: Colors.grey[700], fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.date_range_rounded, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${bid.startDate.day}/${bid.startDate.month} - ${bid.endDate.day}/${bid.endDate.month}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
              if (isOwner && bid.status == BidStatus.PENDING)
                ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(isHindi ? 'स्वीकार करें' : 'Accept', style: const TextStyle(fontSize: 12)),
                )
              else if (bid.status != BidStatus.PENDING)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(bid.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    bid.status.name,
                    style: TextStyle(color: _getStatusColor(bid.status), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BidStatus status) {
    switch (status) {
      case BidStatus.ACCEPTED: return Colors.green;
      case BidStatus.REJECTED: return Colors.red;
      case BidStatus.WITHDRAWN: return Colors.grey;
      case BidStatus.PENDING: return Colors.orange;
    }
  }
}
