import 'package:flutter/material.dart';

import 'gnav/google_nav_bar.dart';
import 'notification_badge.dart';

/// Tabs available in the app's bottom navigation.
enum AppTab { home, search, saved, requests, hostels, alerts }

/// Shared gradient bottom nav used across the app. Seeker and warden
/// see different tab sets — pass [isSeeker] to switch.
///
/// The unread-notification badge is rendered as an overlay on top of
/// the GNav widget rather than embedded inside it — this avoids having
/// to modify the vendored google_nav_bar fork's rendering pipeline.
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

  /// Fraction of the width where the Alerts tab's icon sits, so the
  /// overlay badge can be positioned precisely. Assumes equal-width
  /// tabs (which GNav uses).
  double _alertsIconCenterFraction() {
    final index = _tabs.indexWhere((t) => t.tab == AppTab.alerts);
    if (index < 0) return -1;
    // Center of tab i (0-based, N total) is at (i + 0.5) / N.
    return (index + 0.5) / _tabs.length;
  }

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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: GNav(
                backgroundColor: Colors.transparent,
                color: Colors.white.withValues(alpha: 0.55),
                activeColor: Colors.white,
                tabBackgroundColor: Colors.white.withValues(alpha: 0.15),
                tabBorderRadius: 14,
                gap: 6,
                iconSize: 22,
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutExpo,
                haptic: true,
                rippleColor: Colors.white.withValues(alpha: 0.1),
                hoverColor: Colors.white.withValues(alpha: 0.05),
                selectedIndex: index < 0 ? 0 : index,
                onTabChange: (i) => onTap(tabs[i].tab),
                tabs: tabs
                    .map((t) => GButton(icon: t.icon, text: t.label))
                    .toList(),
              ),
            ),
            // Badge overlay positioned above the Alerts tab's icon.
            _AlertsBadgeOverlay(
              iconCenterFraction: _alertsIconCenterFraction(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Places an [UnreadBadge] at the top-right corner of the Alerts tab's
/// icon. Uses `LayoutBuilder` to compute the exact pixel position from
/// the tab's fractional center.
class _AlertsBadgeOverlay extends StatelessWidget {
  final double iconCenterFraction;

  const _AlertsBadgeOverlay({required this.iconCenterFraction});

  @override
  Widget build(BuildContext context) {
    if (iconCenterFraction < 0) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth;
            // The padding inside AppBottomNav's Padding is 12px horizontal,
            // and GNav applies another 14px horizontal padding per tab.
            // For simplicity we treat the whole bar as N equal cells and
            // use the center + a small offset for the badge.
            final centerX = tabWidth * iconCenterFraction;
            // The badge sits at the top-right of the icon. Icons are ~22px
            // wide, so the top-right corner is ~ +11px to the right, and
            // the icon's vertical center is ~ 24px from the bar's top
            // (padding 10 + tab padding 10 + half of 22).
            final badgeLeft = centerX + 6;
            const badgeTop = 4.0;

            return Stack(
              children: [
                Positioned(
                  left: badgeLeft,
                  top: badgeTop,
                  child: const UnreadBadge(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}