import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/routes/navigation_service.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/app_bottom_nav.dart';
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
  String _query = '';
  bool _isSeeker = true;

  // TODO: replace with ChatService().listConversations()
  final List<Map<String, dynamic>> _conversations = [
    {
      'id': '1',
      'name': 'Green Valley Hostel',
      'subtitle': 'Warden',
      'lastMessage': 'Your booking request has been approved!',
      'time': '10:42 AM',
      'unread': 2,
      'online': true,
    },
    {
      'id': '2',
      'name': 'Ahmed Raza',
      'subtitle': 'Seeker',
      'lastMessage': 'Is the room still available for June?',
      'time': '9:15 AM',
      'unread': 0,
      'online': false,
    },
    {
      'id': '3',
      'name': 'City Comfort Hostel',
      'subtitle': 'Warden',
      'lastMessage': 'You: Sure, I can visit on Friday.',
      'time': 'Yesterday',
      'unread': 0,
      'online': true,
    },
    {
      'id': '4',
      'name': 'Bilal Khan',
      'subtitle': 'Seeker',
      'lastMessage': 'Thanks for the quick response!',
      'time': 'Yesterday',
      'unread': 1,
      'online': false,
    },
    {
      'id': '5',
      'name': 'Sunrise Boys Hostel',
      'subtitle': 'Warden',
      'lastMessage': 'We have a vacancy opening up next week.',
      'time': 'Mon',
      'unread': 0,
      'online': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await AuthService().getRole();
    if (!mounted) return;
    setState(() => _isSeeker = role != 'warden');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.trim().isEmpty) return _conversations;
    final q = _query.toLowerCase();
    return _conversations
        .where((c) => (c['name'] as String).toLowerCase().contains(q))
        .toList();
  }

  int get _totalUnread =>
      _conversations.fold(0, (sum, c) => sum + (c['unread'] as int));

  void _openChat(Map<String, dynamic> convo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: convo['id'] as String,
          name: convo['name'] as String,
          subtitle: convo['subtitle'] as String,
          online: convo['online'] as bool,
        ),
      ),
    );
  }

  void _onTabTap(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        NavigationService.navigateAndRemoveUntil(
          _isSeeker ? AppRoutes.seekerHome : AppRoutes.wardenHome,
        );
        break;
      case AppTab.chat:
      // Already here.
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
                        Icon(Icons.search, color: maroon.withValues(alpha: 0.5)),
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
                              contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
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
              child: _filtered.isEmpty
                  ? _EmptyState(isDark: isDark, cardColor: cardColor, fg: fg)
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                itemCount: _filtered.length,
                itemBuilder: (context, i) {
                  final c = _filtered[i];
                  return _ConversationTile(
                    name: c['name'] as String,
                    subtitle: c['subtitle'] as String,
                    lastMessage: c['lastMessage'] as String,
                    time: c['time'] as String,
                    unread: c['unread'] as int,
                    online: c['online'] as bool,
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
                    _InitialsAvatar(name: name, size: 48),
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

// ── Initials Avatar ──────────────────────────────────────────────────────
class _InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;

  const _InitialsAvatar({required this.name, required this.size});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    const maroon = Color(0xFF800020);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: maroon.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: maroon,
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