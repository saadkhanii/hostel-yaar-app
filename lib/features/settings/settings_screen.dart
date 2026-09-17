import 'package:flutter/material.dart';

/// Settings screen reached from the drawer. Currently only exposes a
/// dark-mode toggle placeholder — real preferences will come later.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const maroon = Color(0xFF800020);

  bool _pushNotifications = true;
  bool _emailUpdates = false;

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
          'Settings',
          style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Notifications', fg),
              const SizedBox(height: 10),
              _switchTile(
                'Push Notifications',
                'Get notified about booking requests and messages',
                _pushNotifications,
                    (v) => setState(() => _pushNotifications = v),
              ),
              _switchTile(
                'Email Updates',
                'Receive booking updates by email',
                _emailUpdates,
                    (v) => setState(() => _emailUpdates = v),
              ),
              const SizedBox(height: 24),

              _sectionTitle('Appearance', fg),
              const SizedBox(height: 10),
              _staticTile(
                Icons.dark_mode_outlined,
                'Theme',
                'Coming soon',
                    () => _comingSoon('Theme selection'),
              ),
              _staticTile(
                Icons.language_outlined,
                'Language',
                'English',
                    () => _comingSoon('Language selection'),
              ),
              const SizedBox(height: 24),

              _sectionTitle('About', fg),
              const SizedBox(height: 10),
              _staticTile(
                Icons.info_outline,
                'Version',
                '1.0.0',
                null,
              ),
              _staticTile(
                Icons.privacy_tip_outlined,
                'Privacy Policy',
                '',
                    () => _comingSoon('Privacy Policy'),
              ),
              _staticTile(
                Icons.description_outlined,
                'Terms of Service',
                '',
                    () => _comingSoon('Terms of Service'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, Color fg) => Text(
    title,
    style: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: fg.withValues(alpha: 0.7),
    ),
  );

  Widget _switchTile(
      String title,
      String subtitle,
      bool value,
      ValueChanged<bool> onChanged,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: maroon.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: maroon.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
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
                    fontSize: 11,
                    color: maroon.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: maroon,
          ),
        ],
      ),
    );
  }

  Widget _staticTile(
      IconData icon,
      String title,
      String trailing,
      VoidCallback? onTap,
      ) {
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
              Icon(icon, color: maroon, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: maroon,
                  ),
                ),
              ),
              if (trailing.isNotEmpty)
                Text(
                  trailing,
                  style: TextStyle(
                    fontSize: 12,
                    color: maroon.withValues(alpha: 0.6),
                  ),
                ),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios,
                    size: 12, color: maroon.withValues(alpha: 0.4)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}