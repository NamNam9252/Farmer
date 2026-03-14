import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../router/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../../../shared/widgets/language_toggle.dart';
import '../../data/constants/labor_skills.dart';
import '../providers/labor_profile_provider.dart';
import '../providers/my_employments_provider.dart';
import '../providers/booking_requests_provider.dart';

class LaborHomeScreen extends ConsumerWidget {
  const LaborHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    String userName = isHindi ? 'मज़दूर' : 'Worker';
    String userPhone = '';
    String userEmail = '';
    String userStatus = 'ACTIVE';

    if (authState is Authenticated) {
      userName = authState.user.name;
      userPhone = authState.user.phone;
      userEmail = authState.user.email ?? '';
      userStatus = authState.user.status;
    }

    final initials = userName.isNotEmpty
        ? userName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '?';

    // Fetch skills from provider
    final profileAsync = ref.watch(laborProfileProvider);
    String displayRole = isHindi ? '👷 मज़दूर' : '👷 Labor';

    profileAsync.whenData((profile) {
      if (profile != null) {
        // Redirection logic for missing location
        if (profile['latitude'] == null || profile['longitude'] == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go(RouteNames.laborOnboarding);
          });
        }

        if (profile['skills'] != null) {
          final List<dynamic> rawSkills = profile['skills'];
          if (rawSkills.isNotEmpty) {
            final translatedSkills = rawSkills.take(3).map((skillKey) {
              final skill = predefinedSkills.where((s) => s.key == skillKey).firstOrNull;
              if (skill != null) {
                return isHindi ? skill.hi : skill.en;
              }
              return skillKey.toString();
            }).join(', ');
            
            displayRole = rawSkills.length > 3 
                ? '$translatedSkills...' 
                : translatedSkills;
          }
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            children: [
              // ── TOP BAR ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isHindi ? 'प्रोफ़ाइल' : 'Profile',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        const LanguageToggle(
                          color: Color(0xFF00897B),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showLogoutDialog(context, ref, isHindi),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── AVATAR + NAME ──
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00897B), Color(0xFF26A69A)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00897B).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    displayRole,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF00695C),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── CONTACT INFO CARD ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.phone_rounded,
                        iconColor: const Color(0xFF00897B),
                        label: isHindi ? 'फ़ोन' : 'Phone',
                        value: userPhone,
                      ),
                      if (userEmail.isNotEmpty) ...[
                        Divider(color: Colors.grey[100], height: 24),
                        _InfoRow(
                          icon: Icons.email_rounded,
                          iconColor: const Color(0xFFF57C00),
                          label: isHindi ? 'ईमेल' : 'Email',
                          value: userEmail,
                        ),
                      ],
                      Divider(color: Colors.grey[100], height: 24),
                      _InfoRow(
                        icon: Icons.verified_rounded,
                        iconColor: userStatus == 'ACTIVE'
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFF57C00),
                        label: isHindi ? 'स्थिति' : 'Status',
                        value: userStatus == 'ACTIVE'
                            ? (isHindi ? 'सक्रिय' : 'Active')
                            : (isHindi ? 'लंबित' : 'Pending'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _buildEmploymentsSection(ref, isHindi),

              const SizedBox(height: 14),
              _buildPendingRequestsBanner(context, ref, isHindi),

              const SizedBox(height: 20),

              // ── ACTION BUTTONS ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _ActionButton(
                      icon: Icons.edit_rounded,
                      iconColor: Colors.white,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00897B), Color(0xFF26A69A)],
                      ),
                      title: isHindi ? 'प्रोफ़ाइल संपादित करें' : 'Edit Profile',
                      subtitle: isHindi
                          ? 'अपनी जानकारी अपडेट करें'
                          : 'Update your information',
                      onTap: () => context.push(RouteNames.laborEditProfile),
                    ),
                    const SizedBox(height: 14),
                    _ActionButton(
                      icon: Icons.inbox_rounded,
                      iconColor: Colors.white,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF57C00), Color(0xFFFF9800)],
                      ),
                      title: isHindi ? 'बुकिंग अनुरोध' : 'Booking Requests',
                      subtitle: isHindi
                          ? 'किसानों के नए अनुरोध देखें'
                          : 'Review new farmer booking requests',
                      onTap: () => context.push(RouteNames.laborRequests),
                    ),
                    const SizedBox(height: 14),
                    _ActionButton(
                      icon: Icons.history_rounded,
                      iconColor: Colors.white,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5C6BC0), Color(0xFF7986CB)],
                      ),
                      title: isHindi ? 'कार्य स्थान बदलें' : 'Change Work Location',
                      subtitle: isHindi
                          ? 'GPS से नई लोकेशन सेट करें'
                          : 'Set or update location with GPS',
                      onTap: () => context.push(RouteNames.laborOnboarding),
                    ),
                    const SizedBox(height: 14),
                    _ActionButton(
                      icon: Icons.support_agent_rounded,
                      iconColor: Colors.white,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF78909C), Color(0xFF90A4AE)],
                      ),
                      title: isHindi ? 'सहायता' : 'Help & Support',
                      subtitle: isHindi
                          ? 'समस्या की रिपोर्ट करें'
                          : 'Report an issue or get help',
                      onTap: () => _showComingSoon(context, isHindi),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingRequestsBanner(BuildContext context, WidgetRef ref, bool isHindi) {
    final requestsAsync = ref.watch(bookingRequestsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return const SizedBox.shrink();
          }

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFCC80)),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: Color(0xFFE65100)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isHindi
                        ? 'आपके पास ${requests.length} नए बुकिंग अनुरोध हैं'
                        : 'You have ${requests.length} new booking requests',
                    style: const TextStyle(
                      color: Color(0xFFBF360C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(RouteNames.laborRequests),
                  child: Text(isHindi ? 'देखें' : 'View'),
                ),
              ],
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildEmploymentsSection(WidgetRef ref, bool isHindi) {
    final employmentsAsync = ref.watch(myEmploymentsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isHindi ? 'वर्तमान कार्य असाइनमेंट' : 'Current Work Assignments',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          employmentsAsync.when(
            data: (employments) {
              if (employments.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      isHindi ? 'कोई सक्रिय असाइनमेंट नहीं' : 'No active assignments',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                );
              }

              return Column(
                children: employments.map((emp) {
                  final farmer = emp['farmer'];
                  final user = farmer['user'];
                  final rate = emp['agreedRate'] ?? emp['wageAmount'] ?? 0;
                  final startDate = _formatDate(emp['startDate']?.toString());
                  final endDate = _formatDate(emp['endDate']?.toString());
                  final status = (emp['status']?.toString() ?? 'ACCEPTED').toUpperCase();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
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
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person_pin_rounded, color: Color(0xFF1976D2)),
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
                                  fontSize: 15,
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
                                '${isHindi ? "अवधि" : "Period"}: $startDate - $endDate',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _statusText(status, isHindi),
                            style: const TextStyle(
                              color: Color(0xFFE65100),
                              fontSize: 11,
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
      ),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '-';
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return isoDate;
    final d = parsed.day.toString().padLeft(2, '0');
    final m = parsed.month.toString().padLeft(2, '0');
    final y = parsed.year.toString();
    return '$d/$m/$y';
  }

  String _statusText(String status, bool isHindi) {
    if (status == 'ONGOING') return isHindi ? 'चालू' : 'Ongoing';
    if (status == 'COMPLETED') return isHindi ? 'पूर्ण' : 'Completed';
    return isHindi ? 'स्वीकृत' : 'Accepted';
  }

  void _showComingSoon(BuildContext context, bool isHindi) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isHindi ? 'जल्द आ रहा है!' : 'Coming Soon!',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF00897B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref, bool isHindi) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isHindi ? 'लॉगआउट' : 'Logout',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          isHindi ? 'क्या आप लॉगआउट करना चाहते हैं?' : 'Are you sure you want to logout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isHindi ? 'रद्द करें' : 'Cancel',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authControllerProvider.notifier).logout();
              context.go(RouteNames.login);
            },
            child: Text(
              isHindi ? 'लॉगआउट' : 'Logout',
              style: const TextStyle(
                color: Color(0xFFD32F2F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── INFO ROW ──
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── ACTION BUTTON ──
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.iconColor,
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Gradient gradient;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
