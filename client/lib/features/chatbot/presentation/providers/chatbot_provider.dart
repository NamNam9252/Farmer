import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/api/chatbot_api.dart';
import '../../data/models/chat_models.dart';
import '../../../../core/constants/command_constants.dart';
import '../../../../router/app_router.dart';
import '../../../../core/services/location_provider.dart';

// ─── State ────────────────────────────────────────────────
class ChatbotState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isOffline;
  final String? error;
  final String? selectedImagePath;

  const ChatbotState({
    this.messages = const [],
    this.isLoading = false,
    this.isOffline = false,
    this.error,
    this.selectedImagePath,
  });

  ChatbotState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isOffline,
    String? error,
    String? selectedImagePath,
    bool clearImage = false,
  }) {
    return ChatbotState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isOffline: isOffline ?? this.isOffline,
      error: error,
      selectedImagePath: clearImage ? null : (selectedImagePath ?? this.selectedImagePath),
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────
class ChatbotNotifier extends StateNotifier<ChatbotState> {
  final Ref _ref;
  final ChatbotApi _api = ChatbotApi();
  final ImagePicker _picker = ImagePicker();

  ChatbotNotifier(this._ref) : super(const ChatbotState()) {
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    state = state.copyWith(
      messages: [
        ChatMessage(
          role: 'assistant',
          content:
              'नमस्ते! 🌾 मैं कृषिमित्र हूँ — आपका AI सहायक।\n\nHello! I\'m KrishiMitra — your AI farming assistant.\n\nI can help you with:\n🌤️ Weather updates\n📊 Market prices\n🛒 Buy/sell on marketplace\n👥 Find communities\n🌱 Crop recommendations\n🔍 Disease detection\n👷 Find & book farm helpers\n\nBataiye, kya madad chahiye? (How can I help?)',
          ttsMessage: 'Namaste! Main KrishiMitra hoon, aapka AI sahayak. Hello! I am KrishiMitra, your AI farming assistant. Tell me, how can I help you today?',
          languageHint: 'hi',
        ),
      ],
    );
  }

  Future<void> sendMessage(String text, {BuildContext? context, bool isVoice = false}) async {
    if (text.trim().isEmpty && state.selectedImagePath == null) return;

    // Add user message
    final String? imagePath = state.selectedImagePath;
    final userMessage = ChatMessage(
      role: 'user', 
      content: text.trim(),
      imagePath: imagePath,
      isLocalImage: imagePath != null,
    );
    final updatedMessages = [...state.messages, userMessage];

    // Add loading indicator
    final loadingMessage = ChatMessage(
      role: 'assistant',
      content: '',
      isLoading: true,
    );

    state = state.copyWith(
      messages: [...updatedMessages, loadingMessage],
      isLoading: true,
      error: null,
      clearImage: true,
    );

    try {
      // Build conversation history (exclude loading/system messages)
      final history = updatedMessages
          .where((m) => !m.isLoading && m.role != 'system')
          .toList();

      // Keep last 20 messages only
      final trimmedHistory =
          history.length > 20 ? history.sublist(history.length - 20) : history;

      // Get current location
      final locationState = _ref.read(locationProvider);
      final lat = locationState.position?.latitude;
      final lng = locationState.position?.longitude;

      final response = await _api.sendMessage(
        message: text.trim(),
        conversationHistory: trimmedHistory,
        lat: lat,
        lng: lng,
        imagePath: imagePath,
      );

      final assistantMessage = ChatMessage(
        role: 'assistant',
        content: response.message,
        action: response.action,
        languageHint: response.languageHint,
        ttsMessage: response.ttsMessage,
        ttsLanguageHint: response.ttsLanguageHint,
      );

      // Remove loading message and add real response
      final newMessages =
          updatedMessages.where((m) => !m.isLoading).toList()
            ..add(assistantMessage);

      state = state.copyWith(
        messages: newMessages,
        isLoading: false,
        isOffline: false,
      );

      // Handle navigation action if context is available
      if (context != null && response.action != null) {
        _handleAction(response.action!, context);
      }
    } catch (e) {
      // Try offline fallback
      final offlineResult = _handleOffline(text.trim(), context);

      // Remove loading message
      final newMessages = updatedMessages.where((m) => !m.isLoading).toList();

      if (offlineResult != null) {
        newMessages.add(ChatMessage(
          role: 'assistant',
          content: offlineResult,
        ));
        state = state.copyWith(
          messages: newMessages,
          isLoading: false,
          isOffline: true,
        );
      } else {
        newMessages.add(ChatMessage(
          role: 'assistant',
          content:
              '⚠️ AI assistant is currently unavailable. Please check your internet connection.\n\n(ऑफलाइन मोड) You can still use basic commands like:\n• "home" — Go to home page\n• "mandi" — View mandi prices\n• "market" / "bazar" — Browse marketplace\n• "disease" — Disease detection\n• "community" — Communities\n• "profile" — Your profile',
        ));
        state = state.copyWith(
          messages: newMessages,
          isLoading: false,
          isOffline: true,
        );
      }
    }
  }

  String? _handleOffline(String input, BuildContext? context) {
    final route = CommandConstants.getRouteFromCommand(input);
    if (route != null && context != null) {
      _ref.read(appRouterProvider).go(route);
      return '📍 Navigating you to the page... (offline mode)';
    }
    return null;
  }

  void _handleAction(AgentAction action, BuildContext context) {
    if (action.type == 'navigate' && action.route != null) {
      // Delay slightly so user can see the message
      Future.delayed(const Duration(milliseconds: 800), () {
        _ref.read(appRouterProvider).go(action.route!);
      });
    }
  }

  Future<void> confirmAction(String action, Map<String, dynamic> payload) async {
    try {
      state = state.copyWith(isLoading: true);

      await _api.confirmAction(
        action: action,
        payload: payload,
      );

      final confirmMessage = ChatMessage(
        role: 'assistant',
        content: '✅ Done! Action completed successfully.',
      );

      state = state.copyWith(
        messages: [...state.messages, confirmMessage],
        isLoading: false,
      );
    } catch (e) {
      final errorMessage = ChatMessage(
        role: 'assistant',
        content: '❌ Action failed: ${e.toString()}',
      );

      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
      );
    }
  }

  void clearChat() {
    state = const ChatbotState();
    _addWelcomeMessage();
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        state = state.copyWith(selectedImagePath: image.path);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to pick image: $e');
    }
  }

  void clearSelectedImage() {
    state = state.copyWith(clearImage: true);
  }
}

// ─── Provider ─────────────────────────────────────────────
final chatbotProvider =
    StateNotifierProvider<ChatbotNotifier, ChatbotState>((ref) {
  return ChatbotNotifier(ref);
});
