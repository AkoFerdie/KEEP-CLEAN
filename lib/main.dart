import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'supabase_config.dart';

import 'screens/splash_screen.dart';

// Global theme notifier — accessible from anywhere in the app
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize environment variables with error handling
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // If .env file doesn't exist or has issues, continue without it
    print('Warning: Could not load .env file: $e');
  }
  
  // Initialize Supabase
  await SupabaseConfig.initialize();
  
  runApp(const MyApp());
}

class _NoOverscrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();

  @override
  Widget buildOverscrollIndicator(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF4CAF50);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          scrollBehavior: _NoOverscrollBehavior(),
          title: 'Keep It Clean',
          debugShowCheckedModeBanner: false,
          themeMode: mode,

          // ── Light Theme ──
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'sans-serif',
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryGreen,
              brightness: Brightness.light,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            scaffoldBackgroundColor: Colors.white,
            inputDecorationTheme: InputDecorationTheme(
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: primaryGreen),
                borderRadius: BorderRadius.circular(12),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // ── Dark Theme ──
          darkTheme: ThemeData(
            useMaterial3: true,
            fontFamily: 'sans-serif',
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryGreen,
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            inputDecorationTheme: InputDecorationTheme(
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: primaryGreen),
                borderRadius: BorderRadius.circular(12),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              fillColor: const Color(0xFF2C2C2C),
            ),
          ),

          home: const SplashScreen(),
        );
      },
    );
  }
}
