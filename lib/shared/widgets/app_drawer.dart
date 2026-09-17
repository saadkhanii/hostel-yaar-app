import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/routes/navigation_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/session_manager.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';

/// Shared right-side drawer for both dashboards. Shows the current
/// user's identity at the top, then a list of destinations. Uses
/// Flutter's built-in `endDrawer` slot so it slides in from the right.
class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  static const maroon = Color(0xFF800020);

  final _authService = AuthService();

  String _fullName = '';
  String _email = '';
  String _role = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final name = await _authService.getFullName();
    final email = await _authService.getEmail();
    final role = await _authService.getRole();
    if (!mounted) return;
    setState(() {
      _fullName = name ?? 'User';
      _email = email ?? '';
      _role = role ?? 'seeker';
    });
  }

  /// Close the drawer, then push the destination on the root navigator
  /// so it appears above everything (including any nested navigators).
  void _openScreen(Widget screen) {
    Navigator.of(context).pop();
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _openRoute(String route) {
    Navigator.of(context).pop();
    NavigationService.navigateTo(route);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5);
    final fg = isDark ? const Color(0xFFF3E6D5) : const Color(0xFF800020);

    return Drawer(
      backgroundColor: bg,
      width: MediaQuery.of(context).size.width * 0.78,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: maroon.withValues(alpha: 0.15),
                    child: const Icon(Icons.person, color: maroon, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fullName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: fg,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _email,
                          style: TextStyle(
                            fontSize: 12,
                            color: fg.withValues(alpha: 0.6),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: maroon.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _role == 'warden' ? 'Warden' : 'Hostel Seeker',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: maroon.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: maroon.withValues(alpha: 0.15)),

            // ── Items ────────────────────────────────────────────
            const SizedBox(height: 8),
            _DrawerItem(
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: () => _openScreen(const ProfileScreen()),
            ),
            _DrawerItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () => _openScreen(const SettingsScreen()),
            ),
            _DrawerItem(
              icon: Icons.notifications_none_outlined,
              label: 'Notifications',
              onTap: () => _openScreen(const NotificationsScreen()),
            ),
            _DrawerItem(
              icon: Icons.help_outline,
              label: 'Help & Support',
              onTap: () => _openRoute(AppRoutes.settings),
            ),
            const Spacer(),
            Divider(height: 1, color: maroon.withValues(alpha: 0.15)),
            _DrawerItem(
              icon: Icons.logout,
              label: 'Log Out',
              danger: true,
              onTap: () {
                Navigator.of(context).pop();
                SessionManager.confirmAndLogout(context);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    const maroon = Color(0xFF800020);
    final color = danger ? Colors.red : maroon;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}