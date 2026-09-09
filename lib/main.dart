import 'package:flutter/material.dart';
import 'package:hostel_yaar/core/routes/app_router.dart';
import 'package:hostel_yaar/core/routes/app_routes.dart';
import 'package:hostel_yaar/core/routes/navigation_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hostel Yaar',
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,

      // 👇 FORCE LIGHT MODE - ALWAYS USE LIGHT THEME
      themeMode: ThemeMode.light,  // Changed from ThemeMode.system

      // Light Theme (Default)
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF800020),
          surface: Color(0xFFF3E6D5),
        ),
        scaffoldBackgroundColor: const Color(0xFFF3E6D5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF800020),
          foregroundColor: Color(0xFFF3E6D5),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF800020),
            foregroundColor: const Color(0xFFF3E6D5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Color(0xFF800020),
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: Color(0xFF800020),
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: Color(0xFF800020),
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF800020),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF3E6D5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF800020)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF800020), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF800020), width: 2.5),
          ),
        ),
      ),

      // Dark Theme (Optional - can keep for future use)
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF3E6D5),
          surface: Color(0xFF1D2128),
        ),
        scaffoldBackgroundColor: const Color(0xFF1D2128),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1D2128),
          foregroundColor: Color(0xFFF3E6D5),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF3E6D5),
            foregroundColor: const Color(0xFF1D2128),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Color(0xFFF3E6D5),
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: Color(0xFFF3E6D5),
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: Color(0xFFF3E6D5),
          ),
          bodyMedium: TextStyle(
            color: Color(0xFFF3E6D5),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1D2128),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF3E6D5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF3E6D5), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF3E6D5), width: 2.5),
          ),
        ),
      ),

      // 👇 REMOVED THE DARK THEME SELECTION - ONLY USING LIGHT
      // themeMode: ThemeMode.light,  // This forces light mode always

      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}