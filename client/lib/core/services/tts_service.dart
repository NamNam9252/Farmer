import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ttsServiceProvider = Provider((ref) => TtsService());

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  static const String _defaultHindiLanguage = 'hi-IN';

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _setHindiFriendlyVoice();
    await _flutterTts.setLanguage(_defaultHindiLanguage);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _setHindiFriendlyVoice() async {
    try {
      final dynamic voices = await _flutterTts.getVoices;
      if (voices is! List) {
        return;
      }

      for (final dynamic voice in voices) {
        if (voice is! Map) continue;
        final dynamic locale = voice['locale'];
        if (locale is String && locale.toLowerCase().startsWith('hi')) {
          await _flutterTts.setVoice({
            'name': '${voice['name'] ?? ''}',
            'locale': locale,
          });
          return;
        }
      }
    } catch (_) {
      // Ignore if voices are not available on this platform.
    }
  }

  Future<void> speak(String text, [String? languageCode]) async {
    // Keep Hindi default pronunciation even when callers send language hints.
    await _flutterTts.setLanguage(_defaultHindiLanguage);
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
