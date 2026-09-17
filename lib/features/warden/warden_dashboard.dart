import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/routes/navigation_service.dart';
import '../../shared/widgets/app_drawer.dart';

class WardenDashboard extends StatefulWidget {
  const WardenDashboard({super.key});

  @override
  State<WardenDashboard> createState() => _WardenDashboardState();
}

class _WardenDashboardState extends State<WardenDashboard> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() => _scaffoldKey.currentState?.openEndDrawer();

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
        child: SingleChildScrollView(
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
                        const Text(
                          'Warden Ahmed',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _openDrawer,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
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
                    value: '3',
                    icon: Icons.home_work_outlined,
                    isDark: isDark,
                    cardColor: cardColor,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Total Rooms',
                    value: '48',
                    icon: Icons.bed_outlined,
                    isDark: isDark,
                    cardColor: cardColor,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Requests',
                    value: '7',
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
                onTap: () {
                  NavigationService.navigateTo(AppRoutes.addHostel);
                },
              ),
              const SizedBox(height: 14),
              _ActionCard(
                title: 'My Listed Hostels',
                subtitle: 'View, edit or remove your current listings',
                icon: Icons.format_list_bulleted_rounded,
                isDark: isDark,
                cardColor: cardColor,
                onTap: () {
                  NavigationService.navigateTo(AppRoutes.manageHostel);
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

              _ActivityTile(
                title: 'New booking request',
                subtitle: 'Ali Hassan — Boys Hostel Block A',
                time: '2h ago',
                isDark: isDark,
                cardColor: cardColor,
              ),
              _ActivityTile(
                title: 'Room marked vacant',
                subtitle: 'Room 204 — Green View Hostel',
                time: 'Yesterday',
                isDark: isDark,
                cardColor: cardColor,
              ),
              _ActivityTile(
                title: 'New review received',
                subtitle: '4⭐ on Sunrise Boys Hostel',
                time: '2 days ago',
                isDark: isDark,
                cardColor: cardColor,
              ),
            ],
          ),
        ),
      ),

      // ── Bottom Nav ─────────────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1D2128) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            backgroundColor: isDark ? const Color(0xFF1D2128) : Colors.white,
            elevation: 0,
            selectedItemColor: maroon,
            unselectedItemColor: maroon.withValues(alpha: 0.35),
            type: BottomNavigationBarType.fixed,
            currentIndex: 0,
            onTap: (index) {
              switch (index) {
                case 0:
                  break;
                case 1:
                  NavigationService.navigateTo(AppRoutes.manageHostel);
                  break;
                case 2:
                  NavigationService.navigateTo(AppRoutes.wardenRequests);
                  break;
                case 3:
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alerts — coming soon')),
                  );
                  break;
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.home_work_outlined),
                label: 'Hostels',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inbox_outlined),
                label: 'Requests',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications_outlined),
                label: 'Alerts',
              ),
            ],
          ),
        ),
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
