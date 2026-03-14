import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../router/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../../shared/widgets/shared_app_bar.dart';
import '../../../../shared/widgets/language_toggle.dart';
import '../providers/booked_labor_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    String name = isHindi ? 'किसान उपयोगकर्ता' : 'Farmer User';
    String roleLabel = isHindi ? 'खाता सक्रिय' : 'Account Active';

    if (authState is Authenticated) {
      name = authState.user.name;
      roleLabel = _mapRoleToLabel(authState.user.role, isHindi);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context, name, roleLabel, isHindi),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionTitle(isHindi ? 'सेटिंग्स' : 'Settings'),
                _buildSettingsCard(
                  icon: Icons.language_rounded,
                  title: isHindi ? 'भाषा' : 'Language',
                  subtitle: isHindi ? 'हिंदी / English' : 'English / हिंदी',
                  trailing: LanguageToggle(color: AppColors.primary),
                  onTap: () {
                    ref.read(languageProvider.notifier).state = lang == 'hi' ? 'en' : 'hi';
                  },
                ),
                const SizedBox(height: 24),

                _buildBookedLaborSection(ref, isHindi),
                const SizedBox(height: 24),

                _buildSectionTitle(isHindi ? 'खाता' : 'Account'),
                _buildSettingsCard(
                  icon: Icons.logout_rounded,
                  title: isHindi ? 'लॉग आउट' : 'Logout',
                  subtitle: isHindi ? 'इस डिवाइस से साइन आउट करें' : 'Sign out securely from this device',
                  iconColor: AppColors.error,
                  onTap: () => _confirmLogout(context, ref, isHindi),
                ),
                const SizedBox(height: 48),

                _buildLogoutButton(context, ref, isHindi),
                const SizedBox(height: 24),
                
                const Text(
                  'Farmer One Stop Solution',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String name,
    String role,
    bool isHindi,
  ) {
    return SharedStickyHeader(
      title: isHindi ? 'प्रोफ़ाइल' : 'My Profile',
      subtitle: '$name • $role',
      onBack: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          context.go(RouteNames.home);
        }
      },
      leading: Container(
        margin: const EdgeInsets.only(left: 12),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.person_rounded,
          size: 28,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
    );
  }

  Widget _buildSettingsCard({required IconData icon, required String title, required String subtitle, Widget? trailing, VoidCallback? onTap, Color iconColor = AppColors.primary}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                trailing ?? Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref, bool isHindi) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _confirmLogout(context, ref, isHindi),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: Text(isHindi ? 'लॉग आउट करें' : 'Logout Now'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF5350),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref, bool isHindi) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(isHindi ? 'लॉग आउट' : 'Logout'),
        content: Text(isHindi ? 'क्या आप वाकई लॉग आउट करना चाहते हैं?' : 'Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isHindi ? 'नहीं' : 'Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(isHindi ? 'हाँ, लॉग आउट' : 'Logout', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) context.go(RouteNames.login);
    }
  }

  Widget _buildBookedLaborSection(WidgetRef ref, bool isHindi) {
    final bookedLaborAsync = ref.watch(bookedLaborProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(isHindi ? 'मेरे बुक किए गए मददगार' : 'My Booked Helpers'),
        bookedLaborAsync.when(
          data: (bookings) {
            if (bookings.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    isHindi ? 'कोई मददगार बुक नहीं किया गया' : 'No helpers booked yet',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              );
            }

            return Column(
              children: bookings.map((booking) {
                final labor = booking['labor'];
                final user = labor['user'];
                final rate = booking['agreedRate'] ?? booking['wageAmount'] ?? 0;
                final status = (booking['status']?.toString() ?? 'REQUESTED').toUpperCase();
                final period = _bookingPeriod(
                  booking['startDate']?.toString(),
                  booking['endDate']?.toString(),
                );
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(user['name'][0].toUpperCase()),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${isHindi ? "मज़दूरी" : "Wage"}: ₹$rate',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${isHindi ? "फोन" : "Phone"}: ${user['phone'] ?? '-'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${isHindi ? "अवधि" : "Period"}: $period',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _bookingStatusLabel(status, isHindi),
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('Error: $err'),
        ),
      ],
    );
  }

  String _mapRoleToLabel(UserRole role, bool isHindi) {
    switch (role) {
      case UserRole.farmer: return isHindi ? 'किसान' : 'Farmer';
      case UserRole.buyer: return isHindi ? 'खरीदार' : 'Buyer';
      case UserRole.labor: return isHindi ? 'मज़दूर' : 'Labor';
      case UserRole.expert: return isHindi ? 'विशेषज्ञ' : 'Expert';
      case UserRole.admin: return isHindi ? 'एडमिन' : 'Admin';
    }
  }

  String _bookingPeriod(String? startIso, String? endIso) {
    final startDate = DateTime.tryParse(startIso ?? '');
    final endDate = DateTime.tryParse(endIso ?? '');
    if (startDate == null) return '-';

    String fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    if (endDate == null) return fmt(startDate);
    return '${fmt(startDate)} - ${fmt(endDate)}';
  }

  String _bookingStatusLabel(String status, bool isHindi) {
    switch (status) {
      case 'REQUESTED':
        return isHindi ? 'अनुरोधित' : 'Requested';
      case 'ACCEPTED':
        return isHindi ? 'स्वीकृत' : 'Accepted';
      case 'ONGOING':
        return isHindi ? 'चालू' : 'Ongoing';
      case 'COMPLETED':
        return isHindi ? 'पूर्ण' : 'Completed';
      default:
        return isHindi ? 'स्थिति' : 'Status';
    }
  }
}
