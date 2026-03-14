import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
// import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/language_provider.dart';
import '../providers/available_labor_provider.dart';
import '../../data/constants/labor_skills.dart';
import '../../data/api/labor_api.dart';
import '../../../../shared/widgets/shared_app_bar.dart';

class LaborListingScreen extends ConsumerWidget {
  const LaborListingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';
    final laborListAsync = ref.watch(availableLaborProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F3),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SharedStickyHeader(
            title: isHindi ? 'मददगार खोजें' : 'Get Helper',
            subtitle: isHindi ? 'खेती के कामों के लिए अनुभवी मददगार' : 'Experienced helpers for farm tasks',
            backgroundImage: 'assets/images/service_icons/smart_farming.png',
            onBack: () => Navigator.pop(context),
          ),
          laborListAsync.when(
            data: (laborers) {
              if (laborers.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search_rounded,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isHindi ? 'कोई मददगार उपलब्ध नहीं है' : 'No helpers available',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final labor = laborers[index];
                      final user = labor['user'];
                      final name = user['name'];
                      final phone = user['phone']?.toString() ?? '-';
                      final skills = labor['skills'] as List<dynamic>? ?? [];
                      final rate = labor['dailyRate'] ?? 0;
                      final exp = labor['experienceYears'] ?? 0;
                      final serviceRadius = labor['serviceRadiusKm'];

                      final translatedSkills = skills.map((skillKey) {
                        final skill = predefinedSkills.where((s) => s.key == skillKey).firstOrNull;
                        if (skill != null) {
                          return isHindi ? skill.hi : skill.en;
                        }
                        return skillKey.toString();
                      }).join(', ');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
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
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                    child: Text(
                                      name[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${isHindi ? "अनुभव" : "Experience"}: $exp ${isHindi ? "वर्ष" : "Years"}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹$rate',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF2E7D32),
                                        ),
                                      ),
                                      Text(
                                        isHindi ? '/दिन' : '/day',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              Text(
                                isHindi ? 'कौशल:' : 'Skills:',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                translatedSkills,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.phone_rounded, size: 15, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${isHindi ? 'संपर्क' : 'Contact'}: $phone',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              if (serviceRadius != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.radar_rounded, size: 15, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${isHindi ? 'सेवा क्षेत्र' : 'Service radius'}: ${serviceRadius.toString()} km',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _showBookingRequestDialog(context, labor, isHindi, ref),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    isHindi ? 'बुकिंग अनुरोध भेजें' : 'Send Booking Request',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: laborers.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (err, stack) => SliverFillRemaining(child: Center(child: Text('Error: $err'))),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Future<void> _showBookingRequestDialog(
    BuildContext context,
    dynamic labor,
    bool isHindi,
    WidgetRef ref,
  ) async {
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 1));
    final taskController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Text(isHindi ? 'बुकिंग अनुरोध' : 'Booking Request'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHindi
                          ? 'कार्य विवरण और तारीख अवधि चुनें'
                          : 'Add task details and choose date period',
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: taskController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: isHindi ? 'जैसे: कटाई, निराई, सिंचाई' : 'e.g. Harvesting, weeding, irrigation',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(isHindi ? 'शुरू तारीख' : 'Start date'),
                      subtitle: Text(_formatDate(startDate)),
                      trailing: const Icon(Icons.date_range_rounded),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            startDate = picked;
                            if (endDate.isBefore(startDate)) {
                              endDate = startDate;
                            }
                          });
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(isHindi ? 'अंतिम तारीख' : 'End date'),
                      subtitle: Text(_formatDate(endDate)),
                      trailing: const Icon(Icons.event_available_rounded),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate,
                          firstDate: startDate,
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => endDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(isHindi ? 'रद्द करें' : 'Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (taskController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isHindi ? 'कृपया कार्य विवरण लिखें' : 'Please enter task details',
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    await _handleBookingRequest(
                      context,
                      labor,
                      taskController.text.trim(),
                      startDate,
                      endDate,
                      isHindi,
                      ref,
                    );
                  },
                  child: Text(isHindi ? 'अनुरोध भेजें' : 'Send Request'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleBookingRequest(
    BuildContext context,
    dynamic labor,
    String taskDescription,
    DateTime startDate,
    DateTime endDate,
    bool isHindi,
    WidgetRef ref,
  ) async {
    try {
      final laborApi = LaborApi();
      final response = await laborApi.requestBooking(labor['id'], {
        'taskDescription': taskDescription,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'agreedRate': labor['dailyRate'],
      });

      if (context.mounted) {
        if (response.data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isHindi
                    ? 'बुकिंग अनुरोध भेज दिया गया। स्वीकृति का इंतजार करें।'
                    : 'Booking request sent. Waiting for labor acceptance.',
              ),
              backgroundColor: Colors.green,
            ),
          );
          ref.invalidate(availableLaborProvider);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? (isHindi ? 'त्रुटि हुई' : 'Error occurred')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      String errorMessage = isHindi
          ? 'बुकिंग अनुरोध भेजने में विफल'
          : 'Failed to send booking request';

      if (e is DioException) {
        final responseData = e.response?.data;
        if (responseData is Map<String, dynamic>) {
          final serverMessage = responseData['message']?.toString();
          if (serverMessage != null && serverMessage.trim().isNotEmpty) {
            errorMessage = serverMessage;
          }
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }
}
