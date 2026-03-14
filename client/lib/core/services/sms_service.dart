import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'sms_codec.dart';

/// Sends an encoded SMS message to the server's phone number via the native SMS app.
/// Now supports the packetized format for multi-chunk reassembly on the server.
class SmsService {
  static final SmsService _instance = SmsService._();
  factory SmsService() => _instance;
  SmsService._();

  static const int packetTypeRequest = 0;
  static const int packetTypeResponse = 1;

  /// Reads the server phone from .env (SMS_SERVER_PHONE).
  String get serverPhone => dotenv.env['SMS_SERVER_PHONE'] ?? '';

  /// Opens the native SMS app with [text] pre-filled.
  /// Splits large messages into multiple packets for server-side reassembly.
  Future<bool> sendEncoded(String text) async {
    final phone = serverPhone;
    if (phone.isEmpty) {
      throw Exception('SMS_SERVER_PHONE not configured in .env');
    }

    final sid = _randomSID();
    // 1. Encode text to raw binary (FLAG + COMPRESSED_DATA)
    final binary = SmsCodec.encodeToBytes(text);

    // 2. Split into chunks to fit within SMS character limits
    // Binary 110 bytes + 5 bytes header = 115 bytes -> ~142 chars Base91.
    const int chunkSize = 110;
    final int total = (binary.length / chunkSize).ceil();

    if (total == 0) return true;

    bool lastResult = false;
    for (int i = 0; i < total; i++) {
      final start = i * chunkSize;
      final int end = (start + chunkSize > binary.length)
          ? binary.length
          : start + chunkSize;
      final chunk = binary.sublist(start, end);

      // 3. Wrap chunk in a protocol packet
      final packet = _buildPacket(
        sid,
        i, // seq
        total, // total
        packetTypeRequest,
        chunk,
      );

      final uri = Uri(
        scheme: 'sms',
        path: phone,
        queryParameters: {'body': packet},
      );

      if (await canLaunchUrl(uri)) {
        lastResult = await launchUrl(uri);
        // Optional delay between launches if multiple packets
        if (total > 1) {
          await Future.delayed(const Duration(milliseconds: 600));
        }
      } else {
        throw Exception('Cannot launch SMS app on this device');
      }
    }

    return lastResult;
  }

  /// Builds a packet binary and returns it as a Base91 string.
  String _buildPacket(
    String sid,
    int seq,
    int total,
    int type,
    Uint8List payload,
  ) {
    if (sid.length != 2) throw Exception('SID must be 2 characters');

    final packetBytes = Uint8List(5 + payload.length);
    packetBytes[0] = sid.codeUnitAt(0);
    packetBytes[1] = sid.codeUnitAt(1);
    packetBytes[2] = seq;
    packetBytes[3] = total;
    packetBytes[4] = type;
    packetBytes.setRange(5, packetBytes.length, payload);

    return SmsCodec.b91Encode(packetBytes);
  }

  String _randomSID() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return chars[rand.nextInt(chars.length)] +
        chars[rand.nextInt(chars.length)];
  }
}
