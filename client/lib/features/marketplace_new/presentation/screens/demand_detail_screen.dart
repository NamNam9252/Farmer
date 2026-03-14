import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../router/route_names.dart';
import '../../data/models/marketplace_new_models.dart';
import '../providers/marketplace_new_provider.dart';
import '../../../../shared/widgets/shared_app_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state.dart';

class DemandDetailScreen extends ConsumerWidget {
  final MarketplaceDemand demand;
  const DemandDetailScreen({super.key, required this.demand});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demandsState = ref.watch(marketplaceDemandsProvider);
    final myDemandsState = ref.watch(marketplaceMyDemandsProvider);
    
    final latestDemand = demandsState.demands.firstWhere((d) => d.id == demand.id, orElse: () => 
                         myDemandsState.demands.firstWhere((d) => d.id == demand.id, orElse: () => demand));

    final authState = ref.watch(authControllerProvider);
    final userId = authState is Authenticated ? authState.user.id : '';
    final isOwner = latestDemand.buyerId == userId;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SharedStickyHeader(
            title: latestDemand.itemName,
            subtitle: '₹${latestDemand.expectedPrice} • ${latestDemand.category}',
            onBack: () => context.pop(),
            backgroundImage: 'assets/icons/icon_marketplace.png',
            actions: [
              if (isOwner) ...[
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                  ),
                  onPressed: () => context.pushNamed(RouteNames.postDemand, extra: latestDemand),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_rounded, color: Colors.white, size: 18),
                  ),
                  onPressed: () => _showDeleteConfirmation(context, ref),
                ),
                const SizedBox(width: 8),
              ] else ...[
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.report_problem_rounded, color: Colors.white, size: 18),
                  ),
                  onPressed: () => _showReportDialog(context, ref),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 18, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(demand.location, style: const TextStyle(color: Colors.grey, fontSize: 15)),
                    const SizedBox(width: 24),
                    const Icon(Icons.shopping_cart_rounded, size: 18, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('Need: ${latestDemand.quantityNeeded}', style: const TextStyle(color: Colors.grey, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 32),
                const Text('Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                  demand.description ?? 'No extra details provided.',
                  style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                ),
                const SizedBox(height: 40),
                const Text('Buyer Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.person_outline), backgroundColor: Color(0xFFFFF3E0)),
                  title: Text(demand.buyer?['name'] ?? 'Buyer'),
                  subtitle: const Text('Verified Member'),
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isOwner ? null : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => _showOfferDialog(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF6C00),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('SEND SUPPLY OFFER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Demand'),
        content: const Text('Are you sure you want to delete this demand?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              await ref.read(marketplaceDemandsProvider.notifier).deleteDemand(demand.id);
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
        title: const Text('Report Demand'),
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
              await ref.read(marketplaceDemandsProvider.notifier).reportDemand(
                demand.id,
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

  void _showOfferDialog(BuildContext context, WidgetRef ref) {
    final quantityController = TextEditingController();
    final priceController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Supply Offer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Quantity I have (e.g. 200 kg)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'My Offered Price'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: messageController,
                decoration: const InputDecoration(labelText: 'Message (Optional)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (quantityController.text.isEmpty || priceController.text.isEmpty) return;
              try {
                final api = ref.read(marketplaceApiProvider);
                await api.sendDemandOffer({
                  'demandId': demand.id,
                  'quantityAvailable': quantityController.text,
                  'offeredPrice': double.parse(priceController.text),
                  'message': messageController.text,
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer sent successfully!')));
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
