import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../router/route_names.dart';
import '../providers/marketplace_new_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state.dart';

class MyListingsScreen extends ConsumerStatefulWidget {
  const MyListingsScreen({super.key});

  @override
  ConsumerState<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends ConsumerState<MyListingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    final authState = ref.read(authControllerProvider);
    if (authState is Authenticated) {
      final userId = authState.user.id;
      Future.microtask(() {
        ref.read(marketplaceMyItemsProvider.notifier).loadUserItems(userId);
        ref.read(marketplaceMyDemandsProvider.notifier).loadUserDemands(userId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Listings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Items'),
            Tab(text: 'My Demands'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _MyItemsList(),
          const _MyDemandsList(),
        ],
      ),
    );
  }
}

class _MyItemsList extends ConsumerWidget {
  const _MyItemsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(marketplaceMyItemsProvider);
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.items.isEmpty) return const Center(child: Text('You haven\'t posted any items yet.'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.items.length,
      itemBuilder: (context, index) {
        final item = state.items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('₹${item.pricePerUnit} • ${item.quantity}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.itemDetail, extra: item),
          ),
        );
      },
    );
  }
}

class _MyDemandsList extends ConsumerWidget {
  const _MyDemandsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(marketplaceMyDemandsProvider);
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.demands.isEmpty) return const Center(child: Text('You haven\'t posted any demands yet.'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.demands.length,
      itemBuilder: (context, index) {
        final demand = state.demands[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(demand.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Target: ₹${demand.expectedPrice} • Need: ${demand.quantityNeeded}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RouteNames.demandDetail, extra: demand),
          ),
        );
      },
    );
  }
}
