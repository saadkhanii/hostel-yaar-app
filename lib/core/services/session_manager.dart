import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../routes/navigation_service.dart';
import 'auth_service.dart';

class SessionManager {
  SessionManager._();

  /// Shows a confirmation dialog, and if confirmed, clears the stored
  /// JWT + user info and routes back to login, clearing the whole stack.
  static Future<void> confirmAndLogout(BuildContext context) async {
    const maroon = Color(0xFF800020);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark
              ? const Color(0xFF1D2128)
              : const Color(0xFFF3E6D5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Log Out',
            style: TextStyle(color: maroon, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: TextStyle(color: maroon.withValues(alpha: 0.75)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: maroon.withValues(alpha: 0.6)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Log Out',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await AuthService().logout();

    // Clear the navigation stack so back button can't return to a
    // stale dashboard.
    NavigationService.navigateAndRemoveUntil(AppRoutes.roleSelection);
  }
}
