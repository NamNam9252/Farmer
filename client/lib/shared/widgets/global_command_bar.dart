import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/command_service.dart';
import '../../core/theme/app_theme.dart';

import '../../core/services/voice_service.dart';

class GlobalCommandBar extends ConsumerStatefulWidget {
  const GlobalCommandBar({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<GlobalCommandBar> createState() => _GlobalCommandBarState();
}

class _GlobalCommandBarState extends ConsumerState<GlobalCommandBar> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isExpanded = false;
  bool _isListening = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _submitCommand() {
    if (_controller.text.trim().isNotEmpty) {
      ref.read(commandServiceProvider).processCommand(_controller.text);
      _controller.clear();
      setState(() {
        _isExpanded = false;
      });
      _focusNode.unfocus();
    }
  }

  Future<void> _toggleVoice() async {
    final voiceService = ref.read(voiceServiceProvider);
    if (_isListening) {
      await voiceService.stopListening();
      setState(() => _isListening = false);
      _pulseController.stop();
    } else {
      await voiceService.startListening(
        onResult: (text) {
          setState(() {
            _controller.text = text;
            _isListening = false;
          });
          _pulseController.stop();
          // The command is already processed by VoiceService.startListening
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) setState(() => _isExpanded = false);
          });
        },
        onListeningChanged: (listening) {
          setState(() => _isListening = listening);
          if (listening) {
            _pulseController.repeat(reverse: true);
          } else {
            _pulseController.stop();
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine bottom padding for different screen types
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    // Position it slightly above the bottom navbar (assuming navbar is ~60-80px)
    final yOffset = bottomPadding + 68;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          widget.child,
          Positioned(
            left: 0,
            right: 0,
            bottom: yOffset,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                width: _isExpanded ? MediaQuery.of(context).size.width - 32 : 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening ? Colors.redAccent : AppColors.primary).withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isExpanded 
                            ? Colors.white.withValues(alpha: 0.8)
                            : (_isListening ? Colors.redAccent : AppColors.primary).withValues(alpha: 0.9),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: _isExpanded
                          ? Row(
                              children: [
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    focusNode: _focusNode,
                                    autofocus: true,
                                    onSubmitted: (_) => _submitCommand(),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: _isListening ? 'Listening...' : 'Command...',
                                      hintStyle: TextStyle(
                                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                                if (_isExpanded)
                                  ScaleTransition(
                                    scale: Tween(begin: 1.0, end: 1.2).animate(_pulseController),
                                    child: IconButton(
                                      icon: Icon(
                                        _isListening ? Icons.mic : Icons.mic_none,
                                        size: 20,
                                        color: _isListening ? Colors.redAccent : AppColors.textSecondary,
                                      ),
                                      onPressed: _toggleVoice,
                                    ),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                                  onPressed: () {
                                    setState(() {
                                      _isExpanded = false;
                                      _isListening = false;
                                    });
                                    _pulseController.stop();
                                    _focusNode.unfocus();
                                  },
                                ),
                                GestureDetector(
                                  onTap: _submitCommand,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.send_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : InkWell(
                              onTap: () {
                                setState(() {
                                  _isExpanded = true;
                                });
                              },
                              onLongPress: _toggleVoice,
                              child: ScaleTransition(
                                scale: _isListening 
                                    ? Tween(begin: 1.0, end: 1.2).animate(_pulseController)
                                    : const AlwaysStoppedAnimation(1.0),
                                child: Center(
                                  child: Icon(
                                    _isListening ? Icons.mic : Icons.bolt_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
