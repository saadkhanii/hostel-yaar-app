import 'package:flutter/material.dart';
import 'package:hostel_yaar/features/splash/splash_screen.dart';
import 'package:hostel_yaar/features/splash/role_selection.dart';

import '../../features/seeker/seeker_dashboard.dart';
import '../../features/seeker/hostel_detail.dart';
import '../../features/warden/warden_dashboard.dart';
import '../../features/warden/add_hostel.dart';
import '../../features/warden/manage_hostels.dart';
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
      case AppRoutes.wardenHome:
        return MaterialPageRoute(builder: (_) => const WardenDashboard());
      case AppRoutes.seekerHome:
        return MaterialPageRoute(builder: (_) => const SeekerDashboard());

      case AppRoutes.addHostel:
        return MaterialPageRoute(builder: (_) => const AddHostelScreen());

      case AppRoutes.manageHostel:
        return MaterialPageRoute(builder: (_) => const ManageHostelsScreen());

      case AppRoutes.hostelList:
      // TODO: replace with the real hostel browse/search results screen once built
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Hostels')),
            body: const Center(child: Text('Coming soon')),
          ),
        );

      case AppRoutes.hostelDetail:
      // Takes the full hostel data as a Map<String, dynamic> for now (see
      // HostelDetailScreen's doc comment for the expected shape). Switch
      // this to fetching by `hostelId` once a shared Hostel model / backend
      // exists — the original TODO example below assumed that shape.
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => HostelDetailScreen(hostel: args),
        );

    // Add your routes here as you create screens
    // case AppRoutes.login:
    //   return MaterialPageRoute(builder: (_) => const LoginScreen());

    // case AppRoutes.seekerSignup:
    //   return MaterialPageRoute(builder: (_) => const SeekerSignupScreen());

    // case AppRoutes.wardenSignup:
    //   return MaterialPageRoute(builder: (_) => const WardenSignupScreen());

    // case AppRoutes.home:
    //   return MaterialPageRoute(builder: (_) => const HomeScreen());

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