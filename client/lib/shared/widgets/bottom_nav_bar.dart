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
          // Navigate to chatbot if not already there and send message
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
      extendBody: false,
      body: child,
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            height: 90,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
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
                            SvgPicture.string(
                              isSelected ? tab.activeSvg : tab.inactiveSvg,
                              width: 26,
                              height: 26,
                              colorFilter: isSelected
                                  ? null
                                  : ColorFilter.mode(
                                      Colors.blueGrey[300]!,
                                      BlendMode.srcIn,
                                    ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.blueGrey[400],
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
          Positioned(
            top: -30,
            child: GestureDetector(
              onLongPressStart: (_) => startListening(),
              onLongPressEnd: (_) => stopListening(),
              onTap: () => context.go(RouteNames.chatbot),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isListening
                        ? [Colors.red[700]!, Colors.red[400]!]
                        : [const Color(0xFF2E7D32), const Color(0xFF43A047)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isListening ? Colors.red : AppColors.primary)
                          .withValues(alpha: 0.4),
                      blurRadius: isListening ? 20 : 15,
                      spreadRadius: isListening ? 4 : 0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: isListening ? Colors.white70 : Colors.white,
                    width: 4,
                  ),
                ),
                child: Center(
                  child: SvgPicture.string(
                    AppIcons.navChatbot(active: true),
                    width: 40,
                    height: 40,
                    colorFilter: isListening
                        ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                        : null,
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

class _BNBCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

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

