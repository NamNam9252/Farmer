import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../router/route_names.dart';
import '../../data/models/marketplace_new_models.dart';
import '../providers/marketplace_new_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state.dart';

class ItemDetailScreen extends ConsumerWidget {
  final MarketplaceItem item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsState = ref.watch(marketplaceItemsProvider);
    final myItemsState = ref.watch(marketplaceMyItemsProvider);
    
    // Find the latest version of this item from either provider (it should be in both ideally after refresh)
    final latestItem = itemsState.items.firstWhere((i) => i.id == item.id, orElse: () => 
                       myItemsState.items.firstWhere((i) => i.id == item.id, orElse: () => item));

    final authState = ref.watch(authControllerProvider);
    final userId = authState is Authenticated ? authState.user.id : '';
    final isOwner = latestItem.sellerId == userId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (isOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => context.pushNamed(RouteNames.postItem, extra: latestItem),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(context, ref),
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.report_problem_outlined, color: Colors.orange),
              onPressed: () => _showReportDialog(context, ref),
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            automaticallyImplyLeading: false, // Custom leading if needed
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.grey[100],
                child: latestItem.imageUrl != null && latestItem.imageUrl!.isNotEmpty
                  ? Image.network(latestItem.imageUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.image_outlined, size: 64, color: Colors.grey),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${latestItem.pricePerUnit}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(latestItem.category, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(latestItem.itemName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(item.location, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(width: 16),
                    const Icon(Icons.scale_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('Stock: ${latestItem.quantity}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  item.description ?? 'No description provided.',
                  style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                ),
                const SizedBox(height: 32),
                const Text('Seller Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(item.seller?['name'] ?? 'Unknown Seller'),
                  subtitle: const Text('Verified Seller'),
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
      bottomSheet: isOwner ? null : Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: ElevatedButton(
          onPressed: () => _showRequestDialog(context, ref),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('SEND PURCHASE REQUEST', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text('Are you sure you want to delete this listing?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              await ref.read(marketplaceItemsProvider.notifier).deleteItem(item.id);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                context.pop(); // Go back from detail
              }
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Listing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Reason'),
              items: ['Spam', 'Inappropriate Content', 'Fraud', 'Incorrect Information', 'Other']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => reasonController.text = val ?? '',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description (Optional)'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) return;
              await ref.read(marketplaceItemsProvider.notifier).reportItem(
                item.id,
                reasonController.text.toUpperCase().replaceAll(' ', '_'),
                descController.text,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted')));
              }
            },
            child: const Text('SUBMIT'),
          ),
        ],
      ),
    );
  }

  void _showRequestDialog(BuildContext context, WidgetRef ref) {
    final quantityController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Purchase Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: 'Quantity Requested (e.g. 50 kg)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: messageController,
              decoration: const InputDecoration(labelText: 'Message (Optional)'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (quantityController.text.isEmpty) return;
              try {
                final api = ref.read(marketplaceApiProvider);
                await api.sendPurchaseRequest({
                  'itemId': item.id,
                  'requestedQuantity': quantityController.text,
                  'message': messageController.text,
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent successfully!')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('SEND'),
          ),
        ],
      ),
    );
  }
}
