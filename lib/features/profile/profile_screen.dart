import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/session_manager.dart';

/// Account screen reached from the drawer. Shows the current user's
/// basic info and provides logout. Editing profile / changing password
/// will be added later — the buttons are stubs for now.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const maroon = Color(0xFF800020);

  final _authService = AuthService();

  String _fullName = '';
  String _email = '';
  String _role = '';
  bool _isLoading = true;

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
      _fullName = name ?? 'Unknown';
      _email = email ?? '';
      _role = role ?? 'seeker';
      _isLoading = false;
    });
  }

  void _comingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — coming soon')),
    );
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
          'Profile',
          style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(maroon),
          ),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              CircleAvatar(
                radius: 48,
                backgroundColor: maroon.withValues(alpha: 0.15),
                child: const Icon(Icons.person, color: maroon, size: 52),
              ),
              const SizedBox(height: 16),
              Text(
                _fullName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: fg,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _email,
                style: TextStyle(
                  fontSize: 13,
                  color: fg.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: maroon.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _role == 'warden' ? 'Warden' : 'Hostel Seeker',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: maroon.withValues(alpha: 0.85),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _Tile(
                icon: Icons.edit_outlined,
                label: 'Edit Profile',
                onTap: () => _comingSoon('Edit Profile'),
              ),
              _Tile(
                icon: Icons.lock_outline,
                label: 'Change Password',
                onTap: () => _comingSoon('Change Password'),
              ),
              _Tile(
                icon: Icons.help_outline,
                label: 'Help & Support',
                onTap: () => _comingSoon('Help & Support'),
              ),
              const SizedBox(height: 12),
              _Tile(
                icon: Icons.logout,
                label: 'Log Out',
                danger: true,
                onTap: () => SessionManager.confirmAndLogout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    const maroon = Color(0xFF800020);
    final color = danger ? Colors.red : maroon;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: maroon.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: maroon.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 12, color: color.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}