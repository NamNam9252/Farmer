import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/language_provider.dart';
import '../providers/community_provider.dart';
import '../../data/repository/community_repository.dart';
import '../../../../shared/widgets/shared_app_bar.dart';

class JoinRequestsScreen extends ConsumerStatefulWidget {
  final String communityId;
  const JoinRequestsScreen({super.key, required this.communityId});

  @override
  ConsumerState<JoinRequestsScreen> createState() => _JoinRequestsScreenState();
}

class _JoinRequestsScreenState extends ConsumerState<JoinRequestsScreen> {
  List<Map<String, dynamic>> requests = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final repo = CommunityRepository();
      final data = await repo.getJoinRequests(widget.communityId);
      setState(() {
        requests = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = ref.watch(languageProvider) == 'hi';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(isHindi),
          SliverFillRemaining(
            hasScrollBody: true,
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : error != null
                    ? _buildErrorState(error!, isHindi)
                    : requests.isEmpty
                        ? _buildEmptyState(isHindi)
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: requests.length,
                            itemBuilder: (context, index) {
                              final req = requests[index];
                              final user = req['user'] as Map<String, dynamic>;
                              return _buildRequestCard(req, user, isHindi);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isHindi) {
    return SharedSliverAppBar(
      title: isHindi ? 'शामिल होने के अनुरोध' : 'Join Requests',
      subtitle: isHindi 
          ? 'लंबित सदस्यताओं को प्रबंधित करें' 
          : 'Manage pending memberships',
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req, Map<String, dynamic> user, bool isHindi) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(user['name']?[0] ?? '?', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['name'] ?? 'Unknown User', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  Text(user['email'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Row(
              children: [
                _buildActionButton(Icons.check_rounded, Colors.green, () => _handleApprove(req['id'])),
                const SizedBox(width: 8),
                _buildActionButton(Icons.close_rounded, Colors.red, () => _handleReject(req['id'])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildEmptyState(bool isHindi) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20)]),
            child: const Icon(Icons.person_add_disabled_rounded, size: 64, color: AppColors.textHint),
          ),
          const SizedBox(height: 24),
          Text(isHindi ? 'कोई अनुरोध नहीं' : 'No Pending Requests', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          Text(isHindi ? 'सब कुछ अद्यतित है!' : 'Everything is up to date!', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, bool isHindi) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _loadRequests, child: Text(isHindi ? 'पुनः प्रयास करें' : 'Retry')),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApprove(String requestId) async {
    try {
      await ref.read(communityDetailProvider.notifier).approveJoinRequest(widget.communityId, requestId);
      _loadRequests();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _handleReject(String requestId) async {
    try {
      await ref.read(communityDetailProvider.notifier).rejectJoinRequest(widget.communityId, requestId);
      _loadRequests();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating));
    }
  }
}
