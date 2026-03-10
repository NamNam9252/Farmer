import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class NotificationSheet extends ConsumerWidget {
  final bool isHindi;

  const NotificationSheet({super.key, required this.isHindi});

  static void show(BuildContext context, WidgetRef? ref, bool isHindi) {
    if (ref != null) {
      ref.read(notificationProvider.notifier).loadNotifications();
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => NotificationSheet(isHindi: isHindi),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Color(0xFFF5FBF6),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isHindi ? 'सूचनाएं' : 'Notifications',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.notifications.isEmpty
                    ? Center(child: Text(isHindi ? 'कोई सूचना नहीं' : 'No notifications'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.notifications.length,
                        itemBuilder: (context, index) {
                          final n = state.notifications[index];
                          return Card(
                            color: n.isRead ? Colors.white : const Color(0xFFE8F5E9),
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: n.isRead ? 0 : 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(n.body),
                              trailing: n.isRead ? null : const Icon(Icons.circle, color: Color(0xFF2E7D32), size: 12),
                              onTap: () {
                                ref.read(notificationProvider.notifier).markAsRead(n.id);
                                if (n.actionType == 'COMMUNITY_JOIN_REQUEST') {
                                   Navigator.pop(context);
                                   context.go('/community/${n.actionId}/requests');
                                } else if (n.actionType == 'COMMUNITY_JOIN_APPROVED') {
                                   Navigator.pop(context);
                                   context.go('/community/${n.actionId}');
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
