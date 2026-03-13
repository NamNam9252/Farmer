import 'dart:convert';

import 'package:http/http.dart' as http;

class TranslationApi {
  TranslationApi._();

  static final Map<String, String> _hindiCache = <String, String>{};

  static Future<String> toHindi(String text) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return cleaned;

    final cached = _hindiCache[cleaned];
    if (cached != null) {
      return cached;
    }

    try {
      final uri = Uri.https('translate.googleapis.com', '/translate_a/single', {
        'client': 'gtx',
        'sl': 'en',
        'tl': 'hi',
        'dt': 't',
        'q': cleaned,
      });

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return cleaned;
      }

      final decoded = jsonDecode(response.body) as List<dynamic>;
      final segments = decoded[0] as List<dynamic>;

      final translated =
          segments
              .map(
                (segment) => (segment as List<dynamic>).first?.toString() ?? '',
              )
              .join();

      if (translated.isEmpty) {
        return cleaned;
      }

      _hindiCache[cleaned] = translated;
      return translated;
    } catch (_) {
      return cleaned;
    }
  }
}
