import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/command_constants.dart';
import '../../router/app_router.dart';

final commandServiceProvider = Provider((ref) => CommandService(ref));

class CommandService {
  final Ref _ref;

  CommandService(this._ref);

  void processCommand(String input) {
    if (input.isEmpty) return;

    final route = CommandConstants.getRouteFromCommand(input);

    if (route != null) {
      _ref.read(appRouterProvider).go(route);
    } else {
      _showErrorSnackBar(input);
    }
  }

  void _showErrorSnackBar(String command) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger != null) {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Command "$command" not recognized. Try "home", "market", or "profile".'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
