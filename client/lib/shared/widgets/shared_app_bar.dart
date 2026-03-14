import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'sticky_header_delegate.dart';

/// A standard non-scrolling header with green gradient and rounded bottom.
/// Use this inside a Column-based screen (NOT slivers).
class SharedHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool centerTitle;
  final double paddingBottom;
  final Widget? bottom;
  final VoidCallback? onLeadingPressed;
  final String? backgroundImage;
  final Widget? trailing;

  const SharedHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.showBackButton = true,
    this.centerTitle = false,
    this.paddingBottom = 24,
    this.bottom,
    this.onLeadingPressed,
    this.backgroundImage,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: backgroundImage != null
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
              ),
        image: backgroundImage != null
            ? DecorationImage(
                image: backgroundImage!.startsWith('assets/')
                    ? AssetImage(backgroundImage!) as ImageProvider
                    : NetworkImage(backgroundImage!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.3),
                  BlendMode.darken,
                ),
              )
            : null,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _HeaderHillsPainter(),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    if (leading != null)
                      GestureDetector(
                        onTap: onLeadingPressed,
                        child: leading!,
                      )
                    else if (showBackButton)
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 18),
                        ),
                        onPressed: onLeadingPressed ?? () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            context.go('/');
                          }
                        },
                      ),
                    if (trailing != null) trailing! else const Spacer(),
                    if (actions != null) ...actions!,
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, bottom != null ? 10 : paddingBottom),
                child: Column(
                  crossAxisAlignment: centerTitle
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (bottom != null) bottom!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Subtle hill lines painted on top of the standard header.
class _HeaderHillsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Circle accent
    paint.color = Colors.white.withValues(alpha: 0.05);
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.25),
      40,
      paint,
    );

    // Hill
    paint.color = Colors.white.withValues(alpha: 0.04);
    final path = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(
        size.width * 0.35, size.height * 0.5,
        size.width, size.height * 0.75,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Sliver wrapper around SharedHeader — use inside CustomScrollView.
class SharedSliverAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool centerTitle;
  final Widget? bottom;
  final VoidCallback? onLeadingPressed;
  final String? backgroundImage;
  final Widget? trailing;

  const SharedSliverAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.showBackButton = true,
    this.centerTitle = false,
    this.bottom,
    this.onLeadingPressed,
    this.backgroundImage,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SharedHeader(
        title: title,
        subtitle: subtitle,
        leading: leading,
        actions: actions,
        showBackButton: showBackButton,
        centerTitle: centerTitle,
        bottom: bottom,
        onLeadingPressed: onLeadingPressed,
        backgroundImage: backgroundImage,
        trailing: trailing,
      ),
    );
  }
}

/// Sticky sliver header — use inside CustomScrollView for collapsing effect.
class SharedStickyHeader extends StatelessWidget {
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

  const SharedStickyHeader({
    super.key,
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
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: StickyHeaderDelegate(
        title: title,
        subtitle: subtitle,
        leading: leading,
        actions: actions,
        showBackButton: showBackButton,
        bottom: bottom,
        onBack: onBack,
        expandedHeight: expandedHeight,
        collapsedHeight: collapsedHeight,
        backgroundImage: backgroundImage,
      ),
    );
  }
}
