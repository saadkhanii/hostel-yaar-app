import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/routes/navigation_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/notification_service.dart';
import '../../shared/widgets/app_bottom_nav.dart';

/// Notifications list. Reached from the drawer and the Alerts tab on
/// both dashboards. Tap an item to mark it read and (where relevant)
/// jump to the related screen.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const maroon = Color(0xFF800020);

  final _service = NotificationService();
  final _authService = AuthService();

  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String? _errorText;
  bool _isSeeker = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
    _load();
  }

  Future<void> _loadRole() async {
    final role = await _authService.getRole();
    if (!mounted) return;
    setState(() => _isSeeker = role != 'warden');
  }

  void _onTabTap(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        if (_isSeeker) {
          NavigationService.navigateAndRemoveUntil(AppRoutes.seekerHome);
        } else {
          NavigationService.navigateAndRemoveUntil(AppRoutes.wardenHome);
        }
        break;
      case AppTab.alerts:
      // Already here.
        break;
      case AppTab.saved:
        if (_isSeeker) {
          NavigationService.navigateTo(AppRoutes.savedHostels);
        }
        break;
      case AppTab.requests:
        if (_isSeeker) {
          NavigationService.navigateTo(AppRoutes.myRequests);
        } else {
          NavigationService.navigateTo(AppRoutes.wardenRequests);
        }
        break;
      case AppTab.hostels:
        if (!_isSeeker) {
          NavigationService.navigateTo(AppRoutes.manageHostel);
        }
        break;
      default:
        break;
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final list = await _service.listNotifications();
      if (!mounted) return;
      setState(() {
        _items = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _service.markAllRead();
      if (!mounted) return;
      setState(() {
        for (final item in _items) {
          item['isRead'] = true;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All marked as read')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> _onTapItem(Map<String, dynamic> item) async {
    // Mark read (optimistic).
    if (item['isRead'] != true) {
      setState(() => item['isRead'] = true);
      try {
        await _service.markRead(item['id'] as String);
      } catch (_) {
        // Silent revert — non-critical.
        if (mounted) setState(() => item['isRead'] = false);
      }
    }

    if (!mounted) return;

    // Route to the related screen based on type.
    final type = item['type'] as String?;
    final relatedId = item['relatedId'] as String?;

    switch (type) {
      case 'booking_created':
      // Warden viewing their request inbox.
        NavigationService.navigateTo(AppRoutes.wardenRequests);
        break;
      case 'booking_accepted':
      case 'booking_rejected':
      // Seeker viewing their own requests.
        NavigationService.navigateTo(AppRoutes.myRequests);
        break;
      default:
        if (relatedId != null) {
          // Unknown type — just stay put.
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5);
    final fg = isDark ? const Color(0xFFF3E6D5) : const Color(0xFF800020);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: fg, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
              color: fg, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (!_isLoading && _items.any((i) => i['isRead'] != true))
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: maroon.withValues(alpha: 0.85),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(child: _buildBody(fg)),
      bottomNavigationBar: AppBottomNav(
        isSeeker: _isSeeker,
        currentTab: AppTab.alerts,
        onTap: _onTabTap,
      ),
    );
  }

  Widget _buildBody(Color fg) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(maroon),
        ),
      );
    }

    if (_errorText != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: fg.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text(
                'Could not load notifications',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: fg.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _errorText!,
                textAlign: TextAlign.center,
                style:
                TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: maroon,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                label: const Text('Retry',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_none_outlined,
                  size: 52, color: fg.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(
                'No notifications yet',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: fg.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 6),
              Text(
                'Booking updates and messages will appear here.',
                textAlign: TextAlign.center,
                style:
                TextStyle(fontSize: 13, color: fg.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: maroon,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final item = _items[i];
          return _NotificationTile(
            item: item,
            onTap: () => _onTapItem(item),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.item,
    required this.onTap,
  });

  static const maroon = Color(0xFF800020);

  IconData _iconFor(String? type) {
    switch (type) {
      case 'booking_created':
        return Icons.inbox_outlined;
      case 'booking_accepted':
        return Icons.check_circle_outline;
      case 'booking_rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  Color _iconColor(String? type) {
    switch (type) {
      case 'booking_accepted':
        return const Color(0xFF2E7D32);
      case 'booking_rejected':
        return Colors.red.shade700;
      default:
        return maroon;
    }
  }

  String _timeAgo(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final then = DateTime.parse(iso);
      final diff = DateTime.now().difference(then);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRead = item['isRead'] == true;
    final type = item['type'] as String?;
    final iconColor = _iconColor(type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isRead
            ? maroon.withValues(alpha: 0.04)
            : maroon.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(_iconFor(type), color: iconColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['title'] as String? ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                isRead ? FontWeight.w500 : FontWeight.w700,
                                color: maroon,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: maroon,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      if ((item['body'] as String?)?.isNotEmpty == true) ...[
                        const SizedBox(height: 3),
                        Text(
                          item['body'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: maroon.withValues(alpha: 0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        _timeAgo(item['createdAt'] as String?),
                        style: TextStyle(
                          fontSize: 11,
                          color: maroon.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}