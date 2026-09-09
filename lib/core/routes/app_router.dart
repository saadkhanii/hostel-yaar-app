import 'package:flutter/material.dart';
import 'package:hostel_yaar/features/splash/splash_screen.dart';
import 'package:hostel_yaar/features/splash/role_selection.dart';

import 'app_routes.dart';

// Import your screens here as you create them
// import 'package:hostel_yaar/features/auth/login_screen.dart';
// import 'package:hostel_yaar/features/auth/seeker_signup_screen.dart';
// import 'package:hostel_yaar/features/auth/warden_signup_screen.dart';
// import 'package:hostel_yaar/features/home/home_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case AppRoutes.roleSelection:
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());

    // Add your routes here as you create screens
    // case AppRoutes.login:
    //   return MaterialPageRoute(builder: (_) => const LoginScreen());

    // case AppRoutes.seekerSignup:
    //   return MaterialPageRoute(builder: (_) => const SeekerSignupScreen());

    // case AppRoutes.wardenSignup:
    //   return MaterialPageRoute(builder: (_) => const WardenSignupScreen());

    // case AppRoutes.home:
    //   return MaterialPageRoute(builder: (_) => const HomeScreen());

    // For routes with parameters
    // case AppRoutes.hostelDetail:
    //   final args = settings.arguments as Map<String, dynamic>;
    //   return MaterialPageRoute(
    //     builder: (_) => HostelDetailScreen(hostelId: args['hostelId']),
    //   );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}