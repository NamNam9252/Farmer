import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ttsServiceProvider = Provider((ref) => TtsService());

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> speak(String text, String languageCode) async {
    // languageCode should be 'hi-IN' or 'en-US' etc.
    // Based on user request, system will analyze hi or en.
    String code = 'en-US';
    if (languageCode == 'hi') {
      code = 'hi-IN';
    } else if (languageCode == 'en') {
      code = 'en-US';
    } else {
      code = languageCode;
    }

    await _flutterTts.setLanguage(code);
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
