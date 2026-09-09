import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/routes/navigation_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    NavigationService.navigateReplacementTo(AppRoutes.roleSelection);
  }

  @override
  Widget build(BuildContext context) {
    // Using light background color as requested
    const backgroundColor = Color(0xFFF3E6D5);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Image.asset(
            'assets/logos/logo-no-bg.png',
            width: 200, // Adjust size as needed
            height: 200,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}