import 'package:flutter/material.dart';

import '../../core/services/notification_service.dart';

/// Wraps [child] and overlays a small count badge (top-right) whenever
/// the user has unread notifications. Listens to NotificationService.version
/// so it refreshes without manual invalidation.
///
/// Pass `color` to override the badge background (defaults to red).
class NotificationBadge extends StatefulWidget {
  final Widget child;
  final Color? color;

  const NotificationBadge({
    super.key,
    required this.child,
    this.color,
  });

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  final _service = NotificationService();

  int _count = 0;

  @override
  void initState() {
    super.initState();
    NotificationService.version.addListener(_refresh);
    _refresh();
  }

  @override
  void dispose() {
    NotificationService.version.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final count = await _service.unreadCount();
      if (!mounted) return;
      setState(() => _count = count);
    } catch (_) {
      // Silent — the badge is not critical.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_count == 0) return widget.child;

    final badgeColor = widget.color ?? const Color(0xFFD32F2F);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned(
          top: -4,
          right: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _count > 99 ? '99+' : '$_count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}/// A compact numeric pill showing the unread count. Renders nothing
/// when count is 0. Listens to NotificationService.version so it stays
/// in sync without manual invalidation. Use this when you just want a
/// badge to sit inline in a row (e.g. next to a drawer label).
class UnreadBadge extends StatefulWidget {
  const UnreadBadge({super.key});

  @override
  State<UnreadBadge> createState() => _UnreadBadgeState();
}

class _UnreadBadgeState extends State<UnreadBadge> {
  final _service = NotificationService();

  int _count = 0;

  @override
  void initState() {
    super.initState();
    NotificationService.version.addListener(_refresh);
    _refresh();
  }

  @override
  void dispose() {
    NotificationService.version.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final count = await _service.unreadCount();
      if (!mounted) return;
      setState(() => _count = count);
    } catch (_) {
      // Silent — badges are decorative.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E6D5), // amber — pops against maroon
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFF5C0017),
          width: 1.2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _count > 99 ? '99+' : '$_count',
        style: const TextStyle(
          color: Color(0xFF5C0017),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}