import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/connectivity_service.dart';

/// Emits [true] when online, [false] when offline.
/// Starts by emitting the current status immediately.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  // Check initial state
  final initial = await ConnectivityService().isConnected();
  yield initial;

  // Then listen to changes
  await for (final results in ConnectivityService().connectivityStream) {
    final isOnline = results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);
    yield isOnline;
  }
});

/// One-shot future provider for the initial connectivity state.
final isOnlineProvider = FutureProvider<bool>((ref) async {
  return ConnectivityService().isConnected();
});
