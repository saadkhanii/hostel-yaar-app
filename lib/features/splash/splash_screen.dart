import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/routes/navigation_service.dart';
import '../../core/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // Keep the splash visible briefly so the branding isn't a jarring flash.
    // Meanwhile, we check auth state in parallel so the total wait is
    // max(2s, storage_read_time) rather than 2s + storage_read_time.
    final results = await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      _authService.isLoggedIn(),
    ]);

    if (!mounted) return;

    final isLoggedIn = results[1] as bool;

    if (isLoggedIn) {
      // Restore the user's session — skip role selection + login entirely.
      final role = await _authService.getRole();
      if (!mounted) return;

      final destination =
      role == 'warden' ? AppRoutes.wardenHome : AppRoutes.seekerHome;
      NavigationService.navigateReplacementTo(destination);
    } else {
      // No active session — show role selection as before.
      NavigationService.navigateReplacementTo(AppRoutes.roleSelection);
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF3E6D5);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Image.asset(
            'assets/logos/logo-no-bg.png',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}