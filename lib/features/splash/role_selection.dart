import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/routes/navigation_service.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5);
    final fg = isDark ? const Color(0xFFF3E6D5) : const Color(0xFF800020);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logos/logo-inline.png',
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 04),
              Text(
                'Choose Your Role',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: fg,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find your hostel, or list your own',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: fg.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 40),
              _RoleCard(
                title: 'Hostel Seeker',
                subtitle: 'Looking for a hostel to stay in',
                icon: Icons.person_search,
                onTap: () {
                  NavigationService.navigateTo(AppRoutes.seekerHome);
                },
              ),
              const SizedBox(height: 20),
              _RoleCard(
                title: 'Warden',
                subtitle: 'I manage a hostel',
                icon: Icons.home_work,
                onTap: () {
                  NavigationService.navigateTo(AppRoutes.wardenHome);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
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
          color: maroon.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: maroon.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 36, color: maroon),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: maroon,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: maroon.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: maroon.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}