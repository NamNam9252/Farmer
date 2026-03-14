import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:telephony/telephony.dart';

/// Background message handler for incoming SMS.
/// MUST be a top-level function.
@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) {
  // Handle background message if needed.
  debugPrint("Background SMS received: ${message.body}");
}

/// A service that handles sending and receiving SMS programmatically.
class SmsService {
  static final SmsService _instance = SmsService._();
  factory SmsService() => _instance;
  SmsService._();

  final Telephony telephony = Telephony.instance;
  static const String smsRequiredPrefix = ')]k';

  /// Reads the server phone from .env (SMS_SERVER_PHONE).
  String get serverPhone => dotenv.env['SMS_SERVER_PHONE'] ?? '';

  /// Request SMS permissions and initialize listeners.
  Future<void> init() async {
    final bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted != true) {
      debugPrint("SMS permissions not granted");
    }
  }

  /// Sends an SMS silently in the background.
  Future<void> sendSilently(String text) async {
    final phone = serverPhone;
    if (phone.isEmpty) {
      throw Exception('SMS_SERVER_PHONE not configured in .env');
    }

    await telephony.sendSms(
      to: phone,
      message: '$smsRequiredPrefix $text',
    );
  }

  /// Listens for incoming SMS from the server phone number.
  void listenForReplies(Function(String) onReplyReceived) {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        if (message.address == serverPhone) {
          onReplyReceived(message.body ?? "");
        }
      },
      onBackgroundMessage: backgroundMessageHandler,
      listenInBackground: true,
    );
  }
}
