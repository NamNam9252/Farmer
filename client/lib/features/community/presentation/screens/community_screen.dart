import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../router/route_names.dart';
import '../../../../core/services/location_provider.dart';
import '../providers/community_provider.dart';
import '../widgets/community_card.dart';
import 'community_detail_screen.dart';
import 'create_community_screen.dart';
import '../../../../shared/widgets/shared_app_bar.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  @override
  void initState() {
    super.initState();
    _loadCommunities();
  }

  Future<void> _loadCommunities() async {
    final locState = ref.read(locationProvider);
    final communityState = ref.read(communityListProvider);

    if (communityState.communities.isNotEmpty && locState.position != null) {
      return;
    }

    try {
      if (locState.position == null) {
        await ref.read(locationProvider.notifier).refreshLocation();
      }
      
      final loc = ref.read(locationProvider).position;
      if (loc != null) {
        ref.read(communityListProvider.notifier).loadNearby(
              loc.latitude,
              loc.longitude,
            );
      }
    } catch (_) {
      ref.read(communityListProvider.notifier).loadNearby(26.8347, 75.6510);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityListProvider);
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateCommunityScreen(),
            ),
          );
        },
        elevation: 6,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          isHindi ? 'समुदाय बनाएं' : 'Create Community',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final location = ref.read(locationProvider);
          await ref.read(communityListProvider.notifier).loadNearby(
                location.position?.latitude ?? 0.0,
                location.position?.longitude ?? 0.0,
              );
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildHeader(isHindi),
            if (state.isLoading && state.communities.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else if (state.error != null)
              SliverFillRemaining(
                child: _buildErrorState(isHindi, state.error!),
              )
            else if (state.communities.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(isHindi),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final community = state.communities[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: CommunityCard(
                          community: community,
                          isHindi: isHindi,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CommunityDetailScreen(
                                  communityId: community.id,
                                  communityName: community.name,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    childCount: state.communities.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isHindi) {
    return SharedStickyHeader(
      title: isHindi ? 'किसान समुदाय' : 'Farmer Communities',
      subtitle: isHindi 
          ? 'अपने क्षेत्र के किसानों से जुड़ें' 
          : 'Connect with farmers in your region',
      backgroundImage: 'assets/images/service_icons/community_fund.png',
      showBackButton: true,
      onBack: () => context.pop(),
    );
  }

  Widget _buildEmptyState(bool isHindi) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20),
                ],
              ),
              child: SvgPicture.string(AppIcons.community, width: 80, height: 80),
            ),
            const SizedBox(height: 24),
            Text(
              isHindi
                  ? 'आपके आस-पास कोई समुदाय नहीं मिला'
                  : 'No communities found nearby',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isHindi
                  ? 'नया समुदाय बनाकर शुरुआत करें!'
                  : 'Start by creating a new community!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isHindi, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 60, color: AppColors.error),
            const SizedBox(height: 20),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCommunities,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(isHindi ? 'पुनः प्रयास करें' : 'Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
