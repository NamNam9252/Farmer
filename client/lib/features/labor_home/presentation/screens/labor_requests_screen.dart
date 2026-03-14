import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/api/labor_api.dart';
import '../providers/booking_requests_provider.dart';
import '../providers/my_employments_provider.dart';
import '../../../../shared/widgets/shared_app_bar.dart';

class LaborRequestsScreen extends ConsumerWidget {
  const LaborRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';
    final requestsAsync = ref.watch(bookingRequestsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F3),
      body: Column(
        children: [
          SharedHeader(
            backgroundImage: 'assets/images/service_icons/smart_farming.png',
            title: isHindi ? 'बुकिंग अनुरोध' : 'Booking Requests',
            subtitle: isHindi ? 'लंबित अनुरोध प्रबंधित करें' : 'Manage pending requests',
          ),
          Expanded(
            child: requestsAsync.when(
              data: (requests) {
                if (requests.isEmpty) {
                  return Center(
                    child: Text(
                      isHindi ? 'कोई लंबित अनुरोध नहीं' : 'No pending requests',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index] as Map<String, dynamic>;
                    final farmer = request['farmer'] as Map<String, dynamic>?;
                    final farmerUser = farmer?['user'] as Map<String, dynamic>?;
                    final farmerName = farmerUser?['name']?.toString() ?? (isHindi ? 'किसान' : 'Farmer');
                    final farmerPhone = farmerUser?['phone']?.toString() ?? '-';
                    final start = request['startDate']?.toString() ?? '';
                    final end = request['endDate']?.toString() ?? start;
                    final task = request['taskDescription']?.toString() ?? '-';
                    final rate = request['agreedRate']?.toString() ?? '-';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            farmerName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text('${isHindi ? 'फोन' : 'Phone'}: $farmerPhone'),
                          Text('${isHindi ? 'कार्य' : 'Task'}: $task'),
                          Text('${isHindi ? 'दर' : 'Rate'}: ₹$rate ${isHindi ? 'प्रति दिन' : 'per day'}'),
                          const SizedBox(height: 6),
                          Text(
                            '${isHindi ? 'अवधि' : 'Period'}: ${_formatDate(start)} - ${_formatDate(end)}',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _respond(context, ref, request['id'].toString(), 'reject', isHindi),
                                  child: Text(isHindi ? 'अस्वीकार' : 'Reject'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                  onPressed: () => _respond(context, ref, request['id'].toString(), 'accept', isHindi),
                                  child: Text(isHindi ? 'स्वीकार' : 'Accept'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('${isHindi ? 'त्रुटि' : 'Error'}: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(String iso) {
    if (iso.isEmpty) return '-';
    final date = DateTime.tryParse(iso);
    if (date == null) return iso;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref,
    String bookingId,
    String action,
    bool isHindi,
  ) async {
    try {
      final laborApi = LaborApi();
      await laborApi.respondToBookingRequest(bookingId, action);

      ref.invalidate(bookingRequestsProvider);
      ref.invalidate(myEmploymentsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'accept'
                  ? (isHindi ? 'अनुरोध स्वीकार किया गया' : 'Request accepted')
                  : (isHindi ? 'अनुरोध अस्वीकार किया गया' : 'Request rejected'),
            ),
            backgroundColor: action == 'accept' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${isHindi ? 'त्रुटि' : 'Error'}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
