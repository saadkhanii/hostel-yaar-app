import 'package:flutter/material.dart';
import 'package:hostel_yaar/features/splash/splash_screen.dart';
import 'package:hostel_yaar/features/splash/role_selection.dart';
import 'package:hostel_yaar/features/auth/login.dart';
import 'package:hostel_yaar/features/auth/signup.dart';
import 'package:hostel_yaar/features/auth/forgot_password.dart';
import 'package:hostel_yaar/features/auth/otp.dart';

import '../../features/seeker/seeker_dashboard.dart';
import '../../features/seeker/hostel_list.dart';
import '../../features/seeker/hostel_detail.dart';
import '../../features/warden/warden_dashboard.dart';
import '../../features/warden/add_hostel.dart';
import '../../features/warden/manage_hostels.dart';
import '../../features/warden/edit_hostel_screen.dart';
import '../../features/warden/warden_requests.dart';
import '../../features/seeker/saved_hostels_screen.dart';
import 'app_routes.dart';

// Import your screens here as you create them
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

      case AppRoutes.login:
        final role = settings.arguments as String?;
        return MaterialPageRoute(builder: (_) => LoginScreen(role: role));

      case AppRoutes.signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());

      case AppRoutes.forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      case AppRoutes.otp:
        final email = settings.arguments as String?;
        return MaterialPageRoute(builder: (_) => OtpScreen(email: email ?? ''));

      case AppRoutes.hostelList:
        final query = settings.arguments as String?;
        return MaterialPageRoute(builder: (_) => HostelListScreen(initialQuery: query));

      case AppRoutes.hostelDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => HostelDetailScreen(hostel: args ?? HostelDetailScreen.sampleHostel),
        );

      case AppRoutes.addHostel:
        return MaterialPageRoute(builder: (_) => const AddHostelScreen());

      case AppRoutes.manageHostel:
        return MaterialPageRoute(builder: (_) => const ManageHostelsScreen());

      case AppRoutes.editHostel:
        final hostel = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => EditHostelScreen(hostel: hostel ?? const <String, dynamic>{}),
        );

      case AppRoutes.wardenRequests:
        return MaterialPageRoute(builder: (_) => const WardenRequestsScreen());

      case AppRoutes.savedHostels:
        return MaterialPageRoute(builder: (_) => const SavedHostelsScreen());
    // Add your routes here as you create screens
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
