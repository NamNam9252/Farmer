import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/notification_api.dart';
import '../../data/models/notification_model.dart';

class NotificationState {
  final bool isLoading;
  final bool hasLoaded;
  final List<NotificationModel> notifications;
  final String? error;

  NotificationState({
    this.isLoading = false,
    this.hasLoaded = false,
    this.notifications = const [],
    this.error,
  });

  NotificationState copyWith({
    bool? isLoading,
    bool? hasLoaded,
    List<NotificationModel>? notifications,
    String? error,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      notifications: notifications ?? this.notifications,
      error: error,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(NotificationState());

  final _api = NotificationApi();

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _api.getNotifications();
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        notifications: list,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _api.markAsRead(id);
      loadNotifications();
    } catch (e) {
      // ignore
    }
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>(
  (ref) => NotificationNotifier(),
);
