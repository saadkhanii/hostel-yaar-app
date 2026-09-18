import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

/// Tabs available in the app's bottom navigation.
enum AppTab { home, search, saved, requests, hostels, alerts }

/// Shared gradient bottom nav used across the app. Seeker and warden
/// see different tab sets — pass [isSeeker] to switch.
class AppBottomNav extends StatelessWidget {
  final bool isSeeker;
  final AppTab currentTab;
  final ValueChanged<AppTab> onTap;

  const AppBottomNav({
    super.key,
    required this.isSeeker,
    required this.currentTab,
    required this.onTap,
  });

  static const maroon = Color(0xFF800020);
  static const maroonDark = Color(0xFF5C0017);

  List<({AppTab tab, IconData icon, String label})> get _tabs {
    if (isSeeker) {
      return const [
        (tab: AppTab.home, icon: Icons.home_outlined, label: 'Home'),
        (tab: AppTab.alerts, icon: Icons.notifications_outlined, label: 'Alerts'),
        (tab: AppTab.saved, icon: Icons.favorite_outline, label: 'Saved'),
        (tab: AppTab.requests, icon: Icons.inbox_outlined, label: 'Requests'),
      ];
    }
    return const [
      (tab: AppTab.home, icon: Icons.dashboard_outlined, label: 'Dashboard'),
      (tab: AppTab.hostels, icon: Icons.home_work_outlined, label: 'Hostels'),
      (tab: AppTab.requests, icon: Icons.inbox_outlined, label: 'Requests'),
      (tab: AppTab.alerts, icon: Icons.notifications_outlined, label: 'Alerts'),
    ];
  }

  int get _currentIndex => _tabs.indexWhere((t) => t.tab == currentTab);

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    final index = _currentIndex;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [maroon, maroonDark],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: GNav(
            // Visual
            backgroundColor: Colors.transparent,
            color: Colors.white.withValues(alpha: 0.55),
            activeColor: Colors.white,
            tabBackgroundColor: Colors.white.withValues(alpha: 0.15),
            tabBorderRadius: 14,
            gap: 6,
            iconSize: 22,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            // Motion
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutExpo,
            // Feedback
            haptic: true,
            rippleColor: Colors.white.withValues(alpha: 0.1),
            hoverColor: Colors.white.withValues(alpha: 0.05),
            // Selection
            selectedIndex: index < 0 ? 0 : index,
            onTabChange: (i) => onTap(tabs[i].tab),
            tabs: tabs
                .map((t) => GButton(icon: t.icon, text: t.label))
                .toList(),
          ),
        ),
      ),
    );
  }
}