import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'command_service.dart';

final voiceServiceProvider = Provider((ref) => VoiceService(ref));

class VoiceService {
  final Ref _ref;
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  VoiceService(this._ref);

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    _isInitialized = await _speech.initialize();
    return _isInitialized;
  }

  Future<void> startListening({
    required Function(String) onResult,
    required Function(bool) onListeningChanged,
  }) async {
    final initialized = await initialize();
    if (!initialized) return;

    onListeningChanged(true);
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          onListeningChanged(false);
          onResult(result.recognizedWords);
          _ref.read(commandServiceProvider).processCommand(result.recognizedWords);
        }
      },
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;
}
