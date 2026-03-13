import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/voice_service.dart';
import '../../../../core/services/language_provider.dart';
import '../providers/chatbot_provider.dart';
import '../../data/models/chat_models.dart';
import '../../../../router/app_router.dart';
import '../widgets/message_bubble.dart';
import '../widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/shared_app_bar.dart';
import '../../../../core/services/tts_service.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isListening = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    final hasImage = ref.read(chatbotProvider).selectedImagePath != null;
    
    if (text.isEmpty && !hasImage) return;
    
    _controller.clear();
    ref.read(chatbotProvider.notifier).sendMessage(text, context: context, isVoice: false);
    _scrollToBottom();
  }

  void _sendVoiceMessage(String text) {
    if (text.trim().isEmpty) return;
    _controller.clear();
    ref.read(chatbotProvider.notifier).sendMessage(text, context: context, isVoice: true);
    _scrollToBottom();
  }

  Future<void> _startListening() async {
    // Stop any current TTS when user starts talking
    ref.read(ttsServiceProvider).stop();
    
    final voiceService = ref.read(voiceServiceProvider);
    setState(() => _isListening = true);
    _pulseController.repeat(reverse: true);

    await voiceService.startListening(
      onResult: (text) {
        _sendVoiceMessage(text);
        setState(() => _isListening = false);
        _pulseController.stop();
        _pulseController.reset();
      },
      onListeningChanged: (listening) {
        if (_isListening != listening) {
          setState(() => _isListening = listening);
        }
        if (!listening) {
          _pulseController.stop();
          _pulseController.reset();
        }
      },
    );
  }

  void _stopListening() {
    ref.read(voiceServiceProvider).stopListening();
    setState(() => _isListening = false);
    _pulseController.stop();
    _pulseController.reset();
  }

  void _handleConfirmAction(AgentAction action) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        action: action,
        onConfirm: () {
          Navigator.pop(ctx);
          ref.read(chatbotProvider.notifier).confirmAction(
                action.confirmAction!,
                Map<String, dynamic>.from(action.confirmPayload),
              );
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }

  void _handleNavigation(String route) {
    ref.read(appRouterProvider).go(route);
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatbotProvider);
    final isHindi = ref.watch(languageProvider) == 'hi';

    // Auto-scroll when new messages arrive
    ref.listen<ChatbotState>(chatbotProvider, (prev, next) {
      if (prev != null && next.messages.length > prev.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      body: Column(
        children: [
          SharedHeader(
            title: isHindi ? 'कृषिमित्र' : 'KrishiMitra',
            subtitle: chatState.isOffline
                ? (isHindi ? 'ऑफलाइन' : 'Offline')
                : (isHindi ? 'ऑनलाइन' : 'Online'),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 18),
                ),
                onSelected: (value) {
                  if (value == 'clear') {
                    ref.read(chatbotProvider.notifier).clearChat();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, size: 20, color: AppColors.textPrimary),
                        const SizedBox(width: 8),
                        Text(isHindi ? 'चैट साफ करें' : 'Clear chat'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          // Offline banner
          if (chatState.isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: AppColors.warning.withValues(alpha: 0.15),
              child: Row(
                children: [
                   const Icon(Icons.wifi_off_rounded, size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Text(
                    isHindi ? 'ऑफलाइन मोड — बेसिक कमांड्स उपलब्ध' : 'Offline mode — Basic commands available',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                final msg = chatState.messages[index];
                return MessageBubble(
                  message: msg,
                  onConfirmAction: msg.action?.type == 'confirm'
                      ? () => _handleConfirmAction(msg.action!)
                      : null,
                  onNavigateAction: msg.action?.route != null
                      ? () => _handleNavigation(msg.action!.route!)
                      : null,
                );
              },
            ),
          ),

          // Input area
          _buildInputArea(chatState),
        ],
      ),
    );
  }


  Widget _buildInputArea(ChatbotState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            if (state.selectedImagePath != null) _buildImagePreview(state),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Image picker button
                IconButton(
                  onPressed: () => _showImageSourcePicker(),
                  icon: const Icon(Icons.attach_file_rounded, color: AppColors.primary),
                ),
                // Text input
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F8F5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: _isListening ? 'Listening...' : 'Type your message...',
                        hintStyle: TextStyle(
                          color: _isListening ? AppColors.primary : AppColors.textHint,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Mic button
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isListening ? 1.0 + (_pulseController.value * 0.15) : 1.0,
                      child: GestureDetector(
                        onLongPressStart: (_) => _startListening(),
                        onLongPressEnd: (_) => _stopListening(),
                        onTap: _isListening ? _stopListening : _startListening,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _isListening
                                ? AppColors.error
                                : AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Icon(
                            _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                            color: _isListening ? Colors.white : AppColors.primary,
                            size: 22,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),

                // Send button
                GestureDetector(
                  onTap: state.isLoading ? null : _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      state.isLoading ? Icons.hourglass_top_rounded : Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(ChatbotState state) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(state.selectedImagePath!),
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                right: -4,
                top: -4,
                child: GestureDetector(
                  onTap: () => ref.read(chatbotProvider.notifier).clearSelectedImage(),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF616161)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                ref.read(chatbotProvider.notifier).pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                ref.read(chatbotProvider.notifier).pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
