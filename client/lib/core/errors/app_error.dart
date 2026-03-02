enum AppErrorType { network, server, unauthorized, validation, unknown }

class AppError implements Exception {
  final String message;
  final AppErrorType type;
  final dynamic originalError;

  AppError({
    required this.message,
    this.type = AppErrorType.unknown,
    this.originalError,
  });

  @override
  String toString() => message;
}
