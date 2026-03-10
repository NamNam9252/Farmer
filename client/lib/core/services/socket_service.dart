import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/app_constants.dart';
import '../services/secure_storage_service.dart';
import '../../router/app_router.dart';
import '../../shared/widgets/notification_alert.dart';
import '../../features/notifications/presentation/widgets/notification_sheet.dart';
import '../../features/notifications/presentation/providers/notification_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/language_provider.dart';

class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? _socket;
  final SecureStorageService _secureStorage = SecureStorageService();
  
  final _notificationStreamController = StreamController<dynamic>.broadcast();
  Stream<dynamic> get notificationStream => _notificationStreamController.stream;

  bool get isConnected => _socket?.connected ?? false;

  final Set<String> _processedNotificationIds = {};

  void connect() async {
    if (_socket?.connected == true) return;

    final token = await _secureStorage.getToken();
    if (token == null) return;

    // Extract base URL without /api/v1
    final uri = Uri.parse(AppConstants.baseUrl);
    final socketUrl = '${uri.scheme}://${uri.host}:${uri.port}';

    if (_socket == null) {
      _socket = io.io(socketUrl, 
        io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build()
      );

      _socket!.onConnect((_) => print('Connected to Socket.io'));
      
      _socket!.on('new_notification', (data) {
        final id = data['id']?.toString() ?? '';
        if (id.isNotEmpty) {
          if (_processedNotificationIds.contains(id)) {
            print('Notification $id already processed, skipping.');
            return;
          }
          _processedNotificationIds.add(id);
          // Keep the set small
          if (_processedNotificationIds.length > 100) {
            _processedNotificationIds.remove(_processedNotificationIds.first);
          }
        }

        print('Received new notification via socket: $data');
        _notificationStreamController.add(data);
        _showCustomOverlayNotification(data);
      });

      _socket!.onDisconnect((_) => print('Disconnected from Socket.io'));
    } else {
      // Just update auth if socket exists but is disconnected
      _socket!.io.options?['auth'] = {'token': token};
      _socket!.connect();
    }
  }

  void _showCustomOverlayNotification(dynamic data) {
    final overlay = rootNavigatorKey.currentState?.overlay;
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => NotificationAlert(
        title: data['title'] ?? 'New Notification',
        body: data['body'] ?? '',
        onDismiss: () {
          entry.remove();
        },
        onOpen: () {
          final ctx = rootNavigatorKey.currentContext!;
          final container = ProviderScope.containerOf(ctx);
          final lang = container.read(languageProvider);
          
          // Use the container to fetch notifications before showing
          container.read(notificationProvider.notifier).loadNotifications();
          
          NotificationSheet.show(ctx, null, lang == 'hi');
        },
      ),
    );

    overlay.insert(entry);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _processedNotificationIds.clear();
  }
}
