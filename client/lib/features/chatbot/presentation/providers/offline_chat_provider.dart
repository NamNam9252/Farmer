import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/chat_models.dart';
import '../../../../core/services/sms_service.dart';

// ─── State ────────────────────────────────────────────────────────────────────
class OfflineChatState {
  final List<ChatMessage> messages;
  final bool isSending;
  final String? error;

  const OfflineChatState({
    this.messages = const [],
    this.isSending = false,
    this.error,
  });

  OfflineChatState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    String? error,
  }) {
    return OfflineChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────
class OfflineChatNotifier extends StateNotifier<OfflineChatState> {
  static const _prefsKey = 'offline_chat_history';

  OfflineChatNotifier() : super(const OfflineChatState()) {
    _loadMessages();
    _addWelcomeIfEmpty();
    _initSms();
  }

  void _initSms() {
    SmsService().init();
    SmsService().listenForReplies((text) {
      receiveReply(text);
    });
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = (jsonDecode(raw) as List)
          .map((m) => _messageFromJson(m as Map<String, dynamic>))
          .toList();
      if (list.isNotEmpty) {
        state = state.copyWith(messages: list);
      }
    } catch (_) {}
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.messages.map(_messageToJson).toList());
    await prefs.setString(_prefsKey, encoded);
  }

  void _addWelcomeIfEmpty() {
    if (state.messages.isNotEmpty) return;
    state = state.copyWith(
      messages: [
        ChatMessage(
          role: 'assistant',
          content:
              '📶 आप ऑफलाइन मोड में हैं।\n\n'
              'You are in **Offline Mode**.\n\n'
              'Type your farming question and tap Send. '
              'Your message will be sent automatically via SMS.\n\n'
              '• 📤 Your question → Sent automatically\n'
              '• 📥 Server replies appear here automatically\n\n'
              'बताइये, क्या सहायता चाहिए?',
        ),
      ],
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(role: 'user', content: text.trim());
    final pendingMsg = ChatMessage(
      role: 'assistant',
      content:
          '⏳ Sending via SMS…\n'
          'Await response here.',
      isLoading: false,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, pendingMsg],
      isSending: true,
      error: null,
    );

    try {
      await SmsService().sendSilently(text.trim());
      state = state.copyWith(isSending: false);
    } catch (e) {
      // Replace pending bubble with error
      final msgs = [...state.messages];
      msgs.removeLast(); // remove pending
      msgs.add(ChatMessage(
        role: 'assistant',
        content: '❌ Failed to send SMS: ${e.toString()}',
      ));
      state = state.copyWith(messages: msgs, isSending: false, error: e.toString());
    }

    await _saveMessages();
  }

  void receiveReply(String text) {
    if (text.trim().isEmpty) return;

    try {
      final replyMsg = ChatMessage(role: 'assistant', content: text.trim());
      state = state.copyWith(messages: [...state.messages, replyMsg]);
      _saveMessages();
    } catch (e) {
      state = state.copyWith(
        error: 'Processing error: $e',
        messages: [
          ...state.messages,
          ChatMessage(
            role: 'assistant',
            content: '❌ Could not process server reply.',
          ),
        ],
      );
    }
  }

  void clearChat() {
    state = const OfflineChatState();
    _addWelcomeIfEmpty();
    _saveMessages();
  }

  // ── JSON helpers (lightweight, no dependency) ──────────────────────────────
  Map<String, dynamic> _messageToJson(ChatMessage m) => {
        'id': m.id,
        'role': m.role,
        'content': m.content,
        'timestamp': m.timestamp.toIso8601String(),
      };

  ChatMessage _messageFromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as String?,
        role: j['role'] as String,
        content: j['content'] as String,
        timestamp: DateTime.tryParse(j['timestamp'] as String? ?? '') ?? DateTime.now(),
      );
}

// ─── Provider ─────────────────────────────────────────────────────────────────
final offlineChatProvider =
    StateNotifierProvider<OfflineChatNotifier, OfflineChatState>((ref) {
  return OfflineChatNotifier();
});
