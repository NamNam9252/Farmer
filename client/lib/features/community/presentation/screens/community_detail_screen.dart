import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../router/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../providers/community_provider.dart';
import 'community_chat_screen.dart';
import 'join_requests_screen.dart';
import '../../../../shared/widgets/shared_app_bar.dart';

class CommunityDetailScreen extends ConsumerStatefulWidget {
  const CommunityDetailScreen({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  final String communityId;
  final String communityName;

  @override
  ConsumerState<CommunityDetailScreen> createState() =>
      _CommunityDetailScreenState();
}

class _CommunityDetailScreenState
    extends ConsumerState<CommunityDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(communityDetailProvider.notifier).loadDetails(widget.communityId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityDetailProvider);
    final isHindi = ref.watch(languageProvider) == 'hi';
    final authState = ref.watch(authControllerProvider);
    final currentUserId = authState is Authenticated ? authState.user.id : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : state.error != null
              ? _buildErrorPlaceholder(state.error!, isHindi)
              : state.community != null
                  ? _buildContent(state, isHindi, currentUserId)
                  : const SizedBox.shrink(),
    );
  }

  Widget _buildContent(CommunityDetailState state, bool isHindi, String? currentUserId) {
    final community = state.community!;
    final isMember = currentUserId != null &&
        (state.members.any((m) => m.userId.toString().trim() == currentUserId.toString().trim()) ||
            community.createdBy?.id == currentUserId);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildHeader(community, isHindi, currentUserId),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 24),
              if (community.description?.isNotEmpty ?? false) ...[
                _buildSectionHeader(isHindi ? 'विवरण' : 'About'),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Text(community.description!, style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textPrimary)),
                ),
                const SizedBox(height: 24),
              ],
              
              _buildSectionHeader(isHindi ? 'सदस्य' : 'Members (${state.members.length})'),
              _buildMembersList(state.members),
              const SizedBox(height: 32),

              _buildActionSection(community, isMember, isHindi),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(dynamic community, bool isHindi, String? currentUserId) {
    final memberText = '${community.memberCount} ${isHindi ? "सदस्य" : "members"}';
    final privacyText = community.isPrivate
        ? (isHindi ? 'निजी' : 'Private')
        : (isHindi ? 'सार्वजनिक' : 'Public');

    return SharedSliverAppBar(
      title: community.name,
      subtitle: '$memberText • $privacyText',
      actions: [
        if (currentUserId != null && community.createdBy?.id == currentUserId) ...[
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JoinRequestsScreen(communityId: community.id))),
            icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
          ),
          IconButton(
            onPressed: () => _showDeleteConfirmation(context, isHindi),
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white70),
          ),
        ],
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
    );
  }

  Widget _buildMembersList(List<dynamic> members) {
    if (members.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: members.length > 5 ? 5 : members.length,
        padding: const EdgeInsets.all(8),
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 56, endIndent: 16),
        itemBuilder: (context, index) {
          final m = members[index];
          return ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(m.userName[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
            ),
            title: Text(m.userName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: m.role == 'ADMIN' ? const Color(0xFFFFF3E0) : const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                m.role,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: m.role == 'ADMIN' ? Colors.orange[800]! : AppColors.primary),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionSection(dynamic community, bool isMember, bool isHindi) {
    return Column(
      children: [
        if (!isMember)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: community.isPending ? null : () => ref.read(communityDetailProvider.notifier).joinCommunity(community.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 6,
                shadowColor: AppColors.primary.withValues(alpha: 0.3),
              ),
              child: Text(
                community.isPending ? (isHindi ? 'अनुरोध लंबित है' : 'Request Pending') : (isHindi ? 'समुदाय में शामिल हों' : 'Join Community'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
        if (isMember) ...[
          _buildToolCard(
            Icons.forum_rounded,
            isHindi ? 'चैट रूम' : 'Community Chat',
            isHindi ? 'चर्चा में शामिल हों' : 'Join the discussion',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => CommunityChatScreen(communityId: community.id, communityName: community.name))),
            isPrimary: true,
          ),
          const SizedBox(height: 12),
          _buildToolCard(Icons.volunteer_activism_rounded, isHindi ? 'ऋण और क्राउडफंडिंग' : 'Loans & Funding', isHindi ? 'जल्द आ रहा है' : 'Coming Soon', null),
          const SizedBox(height: 12),
          _buildToolCard(Icons.article_rounded, isHindi ? 'पोस्ट और चर्चा' : 'Posts & Feeds', isHindi ? 'जल्द आ रहा है' : 'Coming Soon', null),
        ],
      ],
    );
  }

  Widget _buildToolCard(IconData icon, String title, String subtitle, VoidCallback? onTap, {bool isPrimary = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isPrimary ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1) : null,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: isPrimary ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey[100], borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: isPrimary ? AppColors.primary : AppColors.textHint, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder(String error, bool isHindi) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 60, color: AppColors.error),
            const SizedBox(height: 20),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () => ref.read(communityDetailProvider.notifier).loadDetails(widget.communityId), child: Text(isHindi ? 'पुनः प्रयास करें' : 'Retry')),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, bool isHindi) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isHindi ? 'समुदाय हटाएं?' : 'Delete Community?'),
        content: Text(isHindi ? 'क्या आप वाकई इस समुदाय को हटाना चाहते हैं?' : 'Are you sure you want to delete this community?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(isHindi ? 'नहीं' : 'Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(communityDetailProvider.notifier).deleteCommunity(widget.communityId);
              if (mounted) context.go(RouteNames.community);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(isHindi ? 'हां, हटाएं' : 'Delete', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
