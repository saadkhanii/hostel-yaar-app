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
  static const maroonDark = Color(0xFF5C0017);

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
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _openRoute(String route) {
    Navigator.of(context).pop();
    NavigationService.navigateTo(route);
  }

  String get _initials {
    final trimmed = _fullName.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5);
    final cardColor = isDark ? const Color(0xFF262B33) : Colors.white;

    return Drawer(
      backgroundColor: bg,
      width: MediaQuery.of(context).size.width * 0.8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [maroon, maroonDark],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: maroon.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.7),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _role == 'warden'
                                    ? Icons.shield_outlined
                                    : Icons.travel_explore_outlined,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _role == 'warden' ? 'Warden' : 'Hostel Seeker',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Items ────────────────────────────────────────────
            const SizedBox(height: 6),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                children: [
                  _DrawerItem(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    cardColor: cardColor,
                    onTap: () => _openScreen(const ProfileScreen()),
                  ),
                  const SizedBox(height: 10),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    cardColor: cardColor,
                    onTap: () => _openScreen(const SettingsScreen()),
                  ),
                  const SizedBox(height: 10),
                  _DrawerItem(
                    icon: Icons.notifications_none_outlined,
                    label: 'Notifications',
                    cardColor: cardColor,
                    onTap: () => _openScreen(const NotificationsScreen()),
                  ),
                  const SizedBox(height: 10),
                  _DrawerItem(
                    icon: Icons.help_outline,
                    label: 'Help & Support',
                    cardColor: cardColor,
                    onTap: () => _openRoute(AppRoutes.settings),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: _DrawerItem(
                icon: Icons.logout,
                label: 'Log Out',
                cardColor: cardColor,
                danger: true,
                onTap: () {
                  Navigator.of(context).pop();
                  SessionManager.confirmAndLogout(context);
                },
              ),
            ),
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
  final Color cardColor;
  final bool danger;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.cardColor,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    const maroon = Color(0xFF800020);
    final color = danger ? const Color(0xFFC62828) : maroon;

    return Material(
      color: danger ? color.withValues(alpha: 0.06) : cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              if (!danger)
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: color.withValues(alpha: 0.4),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
