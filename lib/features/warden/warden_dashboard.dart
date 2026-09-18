import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/routes/navigation_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/booking_service.dart';
import '../../core/services/hostel_service.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/widgets/user_avatar.dart';

class WardenDashboard extends StatefulWidget {
  const WardenDashboard({super.key});

  @override
  State<WardenDashboard> createState() => _WardenDashboardState();
}

class _WardenDashboardState extends State<WardenDashboard> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _authService = AuthService();
  final _hostelService = HostelService();
  final _bookingService = BookingService();

  String _userName = '';
  int _hostelCount = 0;
  int _roomCount = 0;
  int _pendingRequests = 0;
  List<Map<String, dynamic>> _recentActivity = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadDashboardData();
  }

  Future<void> _loadUserName() async {
    final name = await _authService.getFullName();
    if (!mounted) return;
    setState(() => _userName = name ?? 'there');
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _hostelService.listMyHostels(),
        _bookingService.listWardenRequests(),
      ]);

      final hostels = results[0];
      final requests = results[1];

      // Rooms = sum of room lists across every hostel.
      int rooms = 0;
      for (final h in hostels) {
        final list = (h['rooms'] as List?) ?? const [];
        rooms += list.length;
      }

      final pending = requests.where((r) => r['status'] == 'pending').length;
      final recent = requests.take(3).toList();

      if (!mounted) return;
      setState(() {
        _hostelCount = hostels.length;
        _roomCount = rooms;
        _pendingRequests = pending;
        _recentActivity = recent;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openDrawer() => _scaffoldKey.currentState?.openEndDrawer();

  void _onWardenTabTap(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        break;
      case AppTab.hostels:
        NavigationService.navigateTo(AppRoutes.manageHostel);
        break;
      case AppTab.requests:
        NavigationService.navigateTo(AppRoutes.wardenRequests);
        break;
      case AppTab.alerts:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Alerts — coming soon')));
        break;
      default:
        break;
    }
  }

  // ── Activity tile helpers ──────────────────────────────────────────

  String _activityTitle(Map<String, dynamic> req) {
    final status = req['status'] as String? ?? 'pending';
    switch (status) {
      case 'accepted':
        return 'Request accepted';
      case 'rejected':
        return 'Request rejected';
      default:
        return 'New booking request';
    }
  }

  String _activitySubtitle(Map<String, dynamic> req) {
    final seeker = req['seekerName'] as String? ?? 'Someone';
    final room = req['roomNumber'] as String? ?? '';
    final hostel = req['hostelName'] as String? ?? '';
    return '$seeker — Room $room at $hostel';
  }

  String _relativeTime(String? iso) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5);
    final fg = isDark ? const Color(0xFFF3E6D5) : const Color(0xFF800020);
    final cardColor = isDark ? const Color(0xFF262B33) : Colors.white;
    const maroon = Color(0xFF800020);
    const maroonDark = Color(0xFF5C0017);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bg,
      endDrawer: const AppDrawer(),
      endDrawerEnableOpenDragGesture: false,
      body: SafeArea(
        child: RefreshIndicator(
          color: maroon,
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
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
                          Text(
                            'Welcome back,',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _userName.isEmpty ? '...' : _userName,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      UserAvatar(
                        size: 46,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        foregroundColor: Colors.white,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                        onTap: _openDrawer,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Stats Row ────────────────────────────────────────
                Row(
                  children: [
                    _StatCard(
                      label: 'Listed Hostels',
                      value: _isLoading ? '—' : '$_hostelCount',
                      icon: Icons.home_work_outlined,
                      isDark: isDark,
                      cardColor: cardColor,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Total Rooms',
                      value: _isLoading ? '—' : '$_roomCount',
                      icon: Icons.bed_outlined,
                      isDark: isDark,
                      cardColor: cardColor,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Pending',
                      value: _isLoading ? '—' : '$_pendingRequests',
                      icon: Icons.inbox_outlined,
                      isDark: isDark,
                      cardColor: cardColor,
                      onTap: () {
                        NavigationService.navigateTo(AppRoutes.wardenRequests);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // ── Main Actions ─────────────────────────────────────
                Text(
                  'Manage',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: fg.withValues(alpha: 0.75),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 14),

                _ActionCard(
                  title: 'Add New Hostel',
                  subtitle: 'List a new hostel with details, rooms & photos',
                  icon: Icons.add_home_work_outlined,
                  isDark: isDark,
                  cardColor: cardColor,
                  onTap: () async {
                    await NavigationService.navigateTo(AppRoutes.addHostel);
                    await _loadDashboardData();
                  },
                ),
                const SizedBox(height: 14),
                _ActionCard(
                  title: 'My Listed Hostels',
                  subtitle: 'View, edit or remove your current listings',
                  icon: Icons.format_list_bulleted_rounded,
                  isDark: isDark,
                  cardColor: cardColor,
                  onTap: () async {
                    await NavigationService.navigateTo(AppRoutes.manageHostel);
                    await _loadDashboardData();
                  },
                ),

                const SizedBox(height: 30),

                // ── Recent Activity ──────────────────────────────────
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: fg.withValues(alpha: 0.75),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 14),

                if (_isLoading)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.18 : 0.04,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(maroon),
                        ),
                      ),
                    ),
                  )
                else if (_recentActivity.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.18 : 0.04,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.inbox_outlined,
                          color: maroon,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'No activity yet. Booking requests will appear here.',
                            style: TextStyle(
                              fontSize: 12,
                              color: maroon.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ..._recentActivity.map((req) {
                    return _ActivityTile(
                      title: _activityTitle(req),
                      subtitle: _activitySubtitle(req),
                      time: _relativeTime(req['createdAt'] as String?),
                      isDark: isDark,
                      cardColor: cardColor,
                    );
                  }),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),

      // ── Bottom Nav ─────────────────────────────────────────────
      bottomNavigationBar: AppBottomNav(
        isSeeker: false,
        currentTab: AppTab.home,
        onTap: _onWardenTabTap,
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;
  final Color cardColor;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
    required this.cardColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const maroon = Color(0xFF800020);
    return Expanded(
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: maroon.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: maroon, size: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: maroon,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: maroon.withValues(alpha: 0.6),
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

// ── Action Card ───────────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDark;
  final Color cardColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDark,
    required this.cardColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const maroon = Color(0xFF800020);
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: maroon.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: maroon, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: maroon,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: maroon.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: maroon.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Activity Tile ─────────────────────────────────────────────────────
class _ActivityTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final bool isDark;
  final Color cardColor;

  const _ActivityTile({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isDark,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    const maroon = Color(0xFF800020);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: maroon.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.circle, size: 8, color: maroon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: maroon,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: maroon.withValues(alpha: 0.55),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: maroon.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}
