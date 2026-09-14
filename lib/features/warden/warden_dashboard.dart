import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/routes/navigation_service.dart';
import '../../core/services/session_manager.dart';

class WardenDashboard extends StatelessWidget {
  const WardenDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5);
    final fg = isDark ? const Color(0xFFF3E6D5) : const Color(0xFF800020);
    const maroon = Color(0xFF800020);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(
                          fontSize: 14,
                          color: fg.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        'Warden Ahmed',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: fg,
                        ),
                      ),
                    ],
                  ),

                  GestureDetector(
                    onTap: () => SessionManager.confirmAndLogout(context),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: maroon.withValues(alpha: 0.15),
                      child: const Icon(Icons.person, color: maroon, size: 26),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // â”€â”€ Stats Row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Row(
                children: [
                  _StatCard(
                    label: 'Listed Hostels',
                    value: '3',
                    icon: Icons.home_work_outlined,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Total Rooms',
                    value: '48',
                    icon: Icons.bed_outlined,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Requests',
                    value: '7',
                    icon: Icons.inbox_outlined,
                    isDark: isDark,
                    onTap: () {
                      NavigationService.navigateTo(AppRoutes.wardenRequests);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // â”€â”€ Main Actions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Text(
                'Manage',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: fg.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 14),

              _ActionCard(
                title: 'Add New Hostel',
                subtitle: 'List a new hostel with details, rooms & photos',
                icon: Icons.add_home_work_outlined,
                isDark: isDark,
                onTap: () {
                  NavigationService.navigateTo(AppRoutes.addHostel);
                },
              ),
              const SizedBox(height: 16),
              _ActionCard(
                title: 'My Listed Hostels',
                subtitle: 'View, edit or remove your current listings',
                icon: Icons.format_list_bulleted_rounded,
                isDark: isDark,
                onTap: () {
                  NavigationService.navigateTo(AppRoutes.manageHostel);
                },
              ),

              const SizedBox(height: 32),

              // â”€â”€ Recent Activity â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: fg.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 14),

              _ActivityTile(
                title: 'New booking request',
                subtitle: 'Ali Hassan â€” Boys Hostel Block A',
                time: '2h ago',
                isDark: isDark,
              ),
              _ActivityTile(
                title: 'Room marked vacant',
                subtitle: 'Room 204 â€” Green View Hostel',
                time: 'Yesterday',
                isDark: isDark,
              ),
              _ActivityTile(
                title: 'New review received',
                subtitle: '4â˜… on Sunrise Boys Hostel',
                time: '2 days ago',
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),

      // â”€â”€ Bottom Nav â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5),
        selectedItemColor: maroon,
        unselectedItemColor: maroon.withValues(alpha: 0.4),
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
            // Already on the dashboard â€” nothing to do.
              break;
            case 1:
              NavigationService.navigateTo(AppRoutes.manageHostel);
              break;
            case 2:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Alerts — coming soon')),
              );
              break;
            case 3:
            // Settings is a stub — until it exists, treat this tab as
            // the logout entry point.
              SessionManager.confirmAndLogout(context);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.home_work_outlined), label: 'Hostels'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}

// â”€â”€ Stat Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const maroon = Color(0xFF800020);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: maroon.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: maroon.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: maroon, size: 22),
              const SizedBox(height: 8),
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
                  color: maroon.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Action Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const maroon = Color(0xFF800020);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: maroon.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: maroon.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: maroon.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: maroon, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: maroon,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: maroon.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: maroon.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Activity Tile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ActivityTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final bool isDark;

  const _ActivityTile({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const maroon = Color(0xFF800020);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: maroon.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: maroon.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: maroon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: maroon,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: maroon.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: maroon.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
