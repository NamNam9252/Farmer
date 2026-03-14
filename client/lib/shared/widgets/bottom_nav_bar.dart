import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/language_provider.dart';
import '../../router/route_names.dart';
import '../../core/services/voice_service.dart';
import '../../features/chatbot/presentation/providers/chatbot_provider.dart';

class AppBottomNavBar extends ConsumerWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  final int currentIndex;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';
    final isListening = ref.watch(listeningStateProvider);

    void startListening() {
      ref.read(voiceServiceProvider).startListening(
        onResult: (text) {
          context.go(RouteNames.chatbot);
          ref.read(chatbotProvider.notifier).sendMessage(text, context: context, isVoice: true);
        },
        onListeningChanged: (val) {
          ref.read(listeningStateProvider.notifier).state = val;
        },
      );
    }

    void stopListening() {
      ref.read(voiceServiceProvider).stopListening();
    }

    final tabs = [
      _NavTab(
        path: RouteNames.home,
        labelEn: 'Home',
        labelHi: 'होम',
        activeSvg: AppIcons.navHome(active: true),
        inactiveSvg: AppIcons.navHome(active: false),
      ),
      _NavTab(
        path: RouteNames.disease,
        labelEn: 'Disease Det.',
        labelHi: 'रोग पहचान',
        activeSvg: AppIcons.navDisease(active: true),
        inactiveSvg: AppIcons.navDisease(active: false),
      ),
      _NavTab(
        path: RouteNames.chatbot,
        labelEn: 'Bot',
        labelHi: 'बॉट',
        activeSvg: AppIcons.navChatbot(active: true),
        inactiveSvg: AppIcons.navChatbot(active: false),
        isCenter: true,
      ),
      _NavTab(
        path: RouteNames.schemes,
        labelEn: 'Schemes',
        labelHi: 'योजनाएं',
        activeSvg: AppIcons.navSchemes(active: true),
        inactiveSvg: AppIcons.navSchemes(active: false),
      ),
      _NavTab(
        path: RouteNames.profile,
        labelEn: 'Profile',
        labelHi: 'प्रोफ़ाइल',
        activeSvg: AppIcons.navProfile(active: true),
        inactiveSvg: AppIcons.navProfile(active: false),
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Frosted glass background
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _BNBCustomPainter(),
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: tabs.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final tab = entry.value;
                        final isSelected = idx == currentIndex;
                        final label = isHindi ? tab.labelHi : tab.labelEn;

                        if (tab.isCenter) {
                          return const SizedBox(width: 80);
                        }

                        return Expanded(
                          child: InkWell(
                            onTap: () => context.go(tab.path),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withValues(alpha: 0.08)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: SvgPicture.string(
                                    isSelected ? tab.activeSvg : tab.inactiveSvg,
                                    width: 24,
                                    height: 24,
                                    // Removed grey colorFilter to keep original icon colors
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textSecondary.withValues(alpha: 0.7),
                                  ),
                                ),
                                // Active indicator dot
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(top: 3),
                                  width: isSelected ? 5 : 0,
                                  height: isSelected ? 5 : 0,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Floating center button with bounce
          Positioned(
            top: -30,
            child: _BouncingCenterButton(
              isListening: isListening,
              onTap: () => context.go(RouteNames.chatbot),
              onLongPressStart: (_) => startListening(),
              onLongPressEnd: (_) => stopListening(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Center floating button with spring bounce animation on tap
class _BouncingCenterButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onTap;
  final GestureLongPressStartCallback onLongPressStart;
  final GestureLongPressEndCallback onLongPressEnd;

  const _BouncingCenterButton({
    required this.isListening,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  @override
  State<_BouncingCenterButton> createState() => _BouncingCenterButtonState();
}

class _BouncingCenterButtonState extends State<_BouncingCenterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: widget.onLongPressStart,
      onLongPressEnd: widget.onLongPressEnd,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnim.value, child: child);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.isListening
                  ? [Colors.red[700]!, Colors.red[400]!]
                  : [const Color(0xFF1B5E20), const Color(0xFF2E7D32), const Color(0xFF43A047)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (widget.isListening ? Colors.red : AppColors.primary)
                    .withValues(alpha: 0.45),
                blurRadius: widget.isListening ? 22 : 16,
                spreadRadius: widget.isListening ? 4 : 1,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: widget.isListening ? Colors.white70 : Colors.white,
              width: 4,
            ),
          ),
          child: Center(
            child: SvgPicture.string(
              AppIcons.navChatbot(active: true),
              width: 40,
              height: 40,
              colorFilter: widget.isListening
                  ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _BNBCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = const Color(0xFF2E7D32).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    Path path = Path();
    path.moveTo(0, 0);

    double dipWidth = 110;
    double dipHeight = 45;
    double centerX = size.width / 2;

    path.lineTo(centerX - dipWidth / 2, 0);

    path.cubicTo(
      centerX - dipWidth / 3,
      0,
      centerX - dipWidth / 4,
      dipHeight,
      centerX,
      dipHeight,
    );

    path.cubicTo(
      centerX + dipWidth / 4,
      dipHeight,
      centerX + dipWidth / 3,
      0,
      centerX + dipWidth / 2,
      0,
    );

    path.lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _NavTab {
  const _NavTab({
    required this.path,
    required this.labelEn,
    required this.labelHi,
    required this.activeSvg,
    required this.inactiveSvg,
    this.isCenter = false,
  });

  final String path;
  final String labelEn;
  final String labelHi;
  final String activeSvg;
  final String inactiveSvg;
  final bool isCenter;
}
