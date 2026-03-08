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

/// Detail screen for a single community.
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
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    final authState = ref.watch(authControllerProvider);
    final currentUserId = authState is Authenticated ? authState.user.id : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : state.error != null
              ? _buildError(state.error!, isHindi)
              : state.community != null
                  ? _buildContent(state, isHindi, currentUserId)
                  : const SizedBox.shrink(),
    );
  }

  Widget _buildContent(CommunityDetailState state, bool isHindi, String? currentUserId) {
    final community = state.community!;
    
    // Safety check: match IDs robustly
    final isMember = currentUserId != null &&
        (state.members.any((m) => m.userId.toString().trim() == currentUserId.toString().trim()) ||
            (community.createdBy != null && 
             (community.createdBy!.id.toString().trim() == currentUserId.toString().trim())) ||
            community.createdBy?.id == currentUserId);

    return CustomScrollView(
      slivers: [
        // Header
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go(RouteNames.home);
              }
            },
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              community.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (currentUserId != null && community.createdBy?.id == currentUserId)
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => JoinRequestsScreen(communityId: community.id),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.manage_accounts_rounded, color: Colors.white),
                              tooltip: isHindi ? 'अनुरोध प्रबंधित करें' : 'Manage Requests',
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _infoBadge(Icons.group_rounded,
                              '${community.memberCount} ${isHindi ? "सदस्य" : "members"}'),
                          const SizedBox(width: 12),
                          _infoBadge(
                              community.isPrivate
                                  ? Icons.lock_rounded
                                  : Icons.public_rounded,
                              community.isPrivate
                                  ? (isHindi ? 'निजी' : 'Private')
                                  : (isHindi ? 'सार्वजनिक' : 'Public')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ),
        ),

        // Body
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                if (community.description != null &&
                    community.description!.isNotEmpty) ...[
                  _sectionTitle(isHindi ? 'विवरण' : 'About'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      community.description!,
                      style: AppTextStyles.body2,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Members preview
                _sectionTitle(
                    isHindi ? 'सदस्य' : 'Members (${state.members.length})'),
                const SizedBox(height: 10),
                if (state.members.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: state.members.take(10).map((member) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.1),
                                child: Text(
                                  member.userName.isNotEmpty
                                      ? member.userName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  member.userName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: member.role == 'ADMIN'
                                      ? const Color(0xFFFFF3E0)
                                      : member.role == 'MODERATOR'
                                          ? const Color(0xFFE3F2FD)
                                          : AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  member.role,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: member.role == 'ADMIN'
                                        ? const Color(0xFFF57C00)
                                        : member.role == 'MODERATOR'
                                            ? const Color(0xFF1E88E5)
                                            : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                const SizedBox(height: 24),

                if (!isMember) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: community.isPending ? Colors.grey : AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: (state.isJoining || community.isPending)
                          ? null
                          : () => ref
                              .read(communityDetailProvider.notifier)
                              .joinCommunity(community.id),
                      child: state.isJoining
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              community.isPending 
                                  ? (isHindi ? 'अनुरोध लंबित है' : 'Request Pending')
                                  : (isHindi ? 'समुदाय में शामिल हों' : 'Join Community'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Chat Rooms Section
                InkWell(
                  onTap: isMember
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CommunityChatScreen(
                                communityId: community.id,
                                communityName: community.name,
                              ),
                            ),
                          );
                        }
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(isHindi ? 'पहले समुदाय में शामिल हों' : 'Join the community first')),
                          );
                        },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isMember ? AppColors.primary : AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isMember ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.forum_rounded, 
                              color: isMember ? AppColors.primary : AppColors.textHint, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isHindi ? 'चैट रूम' : 'Chat Rooms',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary)),
                              Text(isMember 
                                  ? (isHindi ? 'चर्चा में शामिल हों' : 'Join the discussion')
                                  : (isHindi ? 'शामिल होने के बाद उपलब्ध' : 'Available after joining'),
                                  style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: isMember ? AppColors.primary : AppColors.textHint),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                _comingSoonSection(
                  icon: Icons.volunteer_activism_rounded,
                  title: isHindi ? 'ऋण और क्राउडफंडिंग' : 'Loans & Crowdfunding',
                  subtitle: isHindi ? 'जल्द आ रहा है' : 'Coming Soon',
                ),
                const SizedBox(height: 12),
                _comingSoonSection(
                  icon: Icons.article_rounded,
                  title: isHindi ? 'पोस्ट और चर्चा' : 'Posts & Discussions',
                  subtitle: isHindi ? 'जल्द आ रहा है' : 'Coming Soon',
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.headline3,
    );
  }

  Widget _comingSoonSection({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.textHint, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '🔜',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error, bool isHindi) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64, color: AppColors.error.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(error,
                style: AppTextStyles.body2, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref
                  .read(communityDetailProvider.notifier)
                  .loadDetails(widget.communityId),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(isHindi ? 'पुनः प्रयास करें' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
