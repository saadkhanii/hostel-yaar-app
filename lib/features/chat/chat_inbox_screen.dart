import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/routes/navigation_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/chat_service.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../../shared/widgets/avatar.dart';
import 'chat_screen.dart';

/// Inbox screen listing all conversations for the current user (seeker
/// or warden). Tapping a conversation opens [ChatScreen].
///
/// Reads the current user's role internally so the router can construct
/// it with no arguments, and so the correct bottom nav is rendered.
class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  static const maroon = Color(0xFF800020);
  static const maroonDark = Color(0xFF5C0017);

  final _searchCtrl = TextEditingController();
  final _chatService = ChatService();

  String _query = '';
  bool _isSeeker = true;
  bool _loading = true;
  String? _errorText;

  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadRole();
    _loadConversations();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRole() async {
    final role = await AuthService().getRole();
    if (!mounted) return;
    setState(() => _isSeeker = role != 'warden');
  }

  Future<void> _loadConversations() async {
    setState(() {
      _loading = true;
      _errorText = null;
    });
    try {
      final list = await _chatService.listConversations();
      if (!mounted) return;
      setState(() {
        _conversations = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.trim().isEmpty) return _conversations;
    final q = _query.toLowerCase();
    return _conversations.where((c) {
      final name = (c['displayName'] as String? ?? '').toLowerCase();
      return name.contains(q);
    }).toList();
  }

  int get _totalUnread => _conversations.fold<int>(
    0,
    (sum, c) => sum + ((c['unreadCount'] as int?) ?? 0),
  );
  String _relativeTime(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inHours < 24 &&
        dt.day == now.day &&
        dt.month == now.month &&
        dt.year == now.year) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
    }
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (dt.year == now.year) return '${dt.day} ${months[dt.month - 1]}';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _openChat(Map<String, dynamic> convo) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: convo['id'] as String,
          name: convo['displayName'] as String? ?? '',
          subtitle: convo['subtitle'] as String? ?? '',
          online: false, // presence not implemented yet
          avatarUrl: convo['avatarUrl'] as String?,
        ),
      ),
    );

    if (mounted) _loadConversations();
  }

  void _onTabTap(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        NavigationService.navigateAndRemoveUntil(
          _isSeeker ? AppRoutes.seekerHome : AppRoutes.wardenHome,
        );
        break;
      case AppTab.chat:
        break;
      case AppTab.saved:
        if (_isSeeker) {
          NavigationService.navigateTo(AppRoutes.savedHostels);
        }
        break;
      case AppTab.requests:
        NavigationService.navigateTo(
          _isSeeker ? AppRoutes.myRequests : AppRoutes.wardenRequests,
        );
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5);
    final fg = isDark ? const Color(0xFFF3E6D5) : maroon;
    final cardColor = isDark ? const Color(0xFF262B33) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [maroon, maroonDark],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: maroon.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Messages',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _totalUnread == 0
                                  ? 'All caught up'
                                  : '$_totalUnread unread conversation${_totalUnread == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.2 : 0.05,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: maroon.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _query = v),
                            decoration: InputDecoration(
                              hintText: 'Search conversations...',
                              hintStyle: TextStyle(
                                color: maroon.withValues(alpha: 0.4),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(maroon),
                      ),
                    )
                  : _errorText != null
                  ? _ErrorState(
                      message: _errorText!,
                      onRetry: _loadConversations,
                      fg: fg,
                    )
                  : _filtered.isEmpty
                  ? _EmptyState(isDark: isDark, cardColor: cardColor, fg: fg)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      itemCount: _filtered.length,
                      itemBuilder: (context, i) {
                        final c = _filtered[i];
                        return _ConversationTile(
                          name: (c['displayName'] as String?) ?? '',
                          subtitle: (c['subtitle'] as String?) ?? '',
                          avatarUrl: c['avatarUrl'] as String?,
                          lastMessage:
                              ((c['lastMessageText'] as String?)?.isNotEmpty ??
                                  false)
                              ? c['lastMessageText'] as String
                              : 'No messages yet',
                          time: _relativeTime(c['lastMessageAt'] as String?),
                          unread: (c['unreadCount'] as int?) ?? 0,
                          online: false,
                          isDark: isDark,
                          cardColor: cardColor,
                          onTap: () => _openChat(c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        isSeeker: _isSeeker,
        currentTab: AppTab.chat,
        onTap: _onTabTap,
      ),
    );
  }
}

// ── Conversation Tile ───────────────────────────────────────────────────
class _ConversationTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final String? avatarUrl;
  final String lastMessage;
  final String time;
  final int unread;
  final bool online;
  final bool isDark;
  final Color cardColor;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.name,
    required this.subtitle,
    required this.avatarUrl,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.online,
    required this.isDark,
    required this.cardColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const maroon = Color(0xFF800020);
    final hasUnread = unread > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Avatar(
                      name: name,
                      imageUrl: avatarUrl,
                      size: 48,
                      backgroundColor: maroon.withValues(alpha: 0.12),
                      textColor: maroon,
                    ),
                    if (online)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            shape: BoxShape.circle,
                            border: Border.all(color: cardColor, width: 2),
                          ),
                        ),
                      ),
                  ],
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
                              name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: hasUnread
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                color: maroon,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: hasUnread
                                  ? maroon
                                  : maroon.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: maroon.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: maroon.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMessage,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: hasUnread
                                    ? maroon.withValues(alpha: 0.85)
                                    : maroon.withValues(alpha: 0.5),
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [maroon, Color(0xFF5C0017)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                unread > 9 ? '9+' : '$unread',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
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


// ── Empty State ─────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isDark;
  final Color cardColor;
  final Color fg;

  const _EmptyState({
    required this.isDark,
    required this.cardColor,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    const maroon = Color(0xFF800020);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: maroon.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.forum_outlined,
                size: 36,
                color: maroon.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Messages with hostels and wardens will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.55)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error State ─────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final Color fg;

  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    const maroon = Color(0xFF800020);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: maroon.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 36,
                color: maroon.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load conversations',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.55)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(color: maroon, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
