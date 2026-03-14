// Simplified SMS Codec - Plain Text only
// (Removed Base91, Smaz, and ZLib to use simple text for SMS transport)

import 'dart:convert';
import 'dart:typed_data';

class SmsCodec {
  SmsCodec._();

  /// Identity encode - returns the text as is.
  static String encode(String text) => text;

  /// Identity decode - returns the text as is.
  static String decode(String smsText) => smsText;

  /// Legacy support: returns UTF-8 bytes for the text.
  static Uint8List encodeToBytes(String text) {
    return Uint8List.fromList(utf8.encode(text));
  }

  /// Legacy support: decodes UTF-8 bytes to text.
  static String decodeFromBytes(Uint8List payload) {
    return utf8.decode(payload);
  }

  /// Legacy support: returns text as is (no Base91).
  static String b91Encode(Uint8List data) {
    return utf8.decode(data);
  }

  /// Legacy support: returns UTF-8 bytes (no Base91).
  static Uint8List b91Decode(String input) {
    return Uint8List.fromList(utf8.encode(input));
  }
}
