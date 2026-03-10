import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class NotificationAlert extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  const NotificationAlert({
    super.key,
    required this.title,
    required this.body,
    required this.onOpen,
    required this.onDismiss,
  });

  @override
  State<NotificationAlert> createState() => _NotificationAlertState();
}

class _NotificationAlertState extends State<NotificationAlert>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1.5, -0.5), // Appear from top-right
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _controller.forward();

    // Auto dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 10, right: 16),
          child: Align(
            alignment: Alignment.topRight,
            child: SlideTransition(
              position: _offsetAnimation,
              child: Dismissible(
                key: UniqueKey(),
                direction: DismissDirection.horizontal, // Swipe right
                onDismissed: (_) => widget.onDismiss(),
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if (details.primaryDelta != null && details.primaryDelta! < -2) {
                      _dismiss(); // Swipe up
                    }
                  },
                  child: Container(
                    width: 280,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.notifications_active,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _dismiss,
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(Icons.close,
                                    color: Colors.white70, size: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.body,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () {
                              _dismiss();
                              widget.onOpen();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'OPEN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
