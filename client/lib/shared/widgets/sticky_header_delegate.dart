import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A collapsible sticky header that transitions from an expanded
/// illustrated gradient to a compact frosted-glass bar.
class StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBackButton;
  final Widget? bottom;
  final VoidCallback? onBack;
  final double expandedHeight;
  final double collapsedHeight;
  final String? backgroundImage;

  StickyHeaderDelegate({
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.showBackButton = true,
    this.bottom,
    this.onBack,
    this.expandedHeight = 200,
    this.collapsedHeight = 100,
    this.backgroundImage,
  });

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => collapsedHeight;

  @override
  bool shouldRebuild(covariant StickyHeaderDelegate old) =>
      title != old.title ||
      subtitle != old.subtitle ||
      expandedHeight != old.expandedHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double expandRatio =
        1.0 - (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final bool isCollapsed = expandRatio < 0.3;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Background gradient + illustration ──
        _AnimatedBackground(
          expandRatio: expandRatio,
          backgroundImage: backgroundImage,
        ),

        // ── Frosted overlay when collapsed ──
        if (isCollapsed)
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.85),
              ),
            ),
          ),

        // ── Content ──
        SafeArea(
          bottom: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Top row: back + actions
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Row(
                  children: [
                    if (leading != null)
                      leading!
                    else if (showBackButton)
                      _BackButton(onBack: onBack),
                    const Spacer(),
                    if (actions != null) ...actions!,
                  ],
                ),
              ),

              // Title + subtitle (fade out on collapse)
              Positioned(
                top: 60, // Below top row
                left: 20,
                right: 20,
                bottom: bottom != null ? 50 : 10,
                child: IgnorePointer(
                  ignoring: expandRatio < 0.2, // Avoid grabbing taps when hidden
                  child: Opacity(
                    opacity: expandRatio.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, (1 - expandRatio) * -20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: lerpDouble(18, 26, expandRatio),
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                height: 1.1,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 5),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Collapsed compact title
              if (isCollapsed)
                Positioned(
                  top: 20,
                  left: (leading != null || showBackButton) ? 60 : 20,
                  right: (actions != null && actions!.isNotEmpty) ? 80 : 20,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),

              // Bottom widget
              if (bottom != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: bottom!,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback? onBack;
  const _BackButton({this.onBack});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: const Icon(Icons.arrow_back_rounded,
            color: Colors.white, size: 18),
      ),
      onPressed: onBack ??
          () {
            try {
              context.pop();
            } catch (e) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            }
          },
    );
  }
}

/// Animated gradient background with illustrated farm hills.
class _AnimatedBackground extends StatelessWidget {
  final double expandRatio;
  final String? backgroundImage;
  const _AnimatedBackground({required this.expandRatio, this.backgroundImage});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: backgroundImage != null
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1B5E20),
                  Color.lerp(
                    const Color(0xFF2E7D32),
                    const Color(0xFF43A047),
                    expandRatio,
                  )!,
                  Color.lerp(
                    const Color(0xFF43A047),
                    const Color(0xFF66BB6A),
                    expandRatio,
                  )!,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
        image: backgroundImage != null
            ? DecorationImage(
                image: backgroundImage!.startsWith('assets/')
                    ? AssetImage(backgroundImage!) as ImageProvider
                    : NetworkImage(backgroundImage!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.3 * expandRatio),
                  BlendMode.darken,
                ),
              )
            : null,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(lerpDouble(0, 32, expandRatio)!),
          bottomRight: Radius.circular(lerpDouble(0, 32, expandRatio)!),
        ),
      ),
      child: backgroundImage != null
          ? null
          : CustomPaint(
              painter: _FarmHillsPainter(expandRatio: expandRatio),
            ),
    );
  }
}

/// Paints soft rolling hills and a sun circle.
class _FarmHillsPainter extends CustomPainter {
  final double expandRatio;
  _FarmHillsPainter({required this.expandRatio});

  @override
  void paint(Canvas canvas, Size size) {
    if (expandRatio < 0.15) return; // skip when fully collapsed

    final paint = Paint()..style = PaintingStyle.fill;

    // Sun circle
    paint.color = Colors.white.withValues(alpha: 0.07 * expandRatio);
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.2),
      40 * expandRatio,
      paint,
    );

    // Hill 1 — far
    paint.color = Colors.white.withValues(alpha: 0.04 * expandRatio);
    final hill1 = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * (0.45 + 0.2 * (1 - expandRatio)),
        size.width,
        size.height * 0.7,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(hill1, paint);

    // Hill 2 — near
    paint.color = Colors.white.withValues(alpha: 0.06 * expandRatio);
    final hill2 = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * (0.55 + 0.15 * (1 - expandRatio)),
        size.width,
        size.height,
      )
      ..close();
    canvas.drawPath(hill2, paint);

    // Small field lines
    paint.color = Colors.white.withValues(alpha: 0.03 * expandRatio);
    paint.strokeWidth = 1.2;
    paint.style = PaintingStyle.stroke;
    for (int i = 0; i < 4; i++) {
      final y = size.height * (0.75 + i * 0.06);
      canvas.drawLine(
        Offset(size.width * 0.1, y),
        Offset(size.width * 0.9, y - 10 * expandRatio),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FarmHillsPainter old) =>
      expandRatio != old.expandRatio;
}
