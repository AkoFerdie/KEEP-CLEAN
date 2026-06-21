import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'screens/splash_screen.dart';
import 'screens/home_page.dart';

const String _googleWebClientId =
    '988746847535-h3e8d7o9iusebo307mqvmo0nplthh6uc.apps.googleusercontent.com';

/// Global notifier used to switch between light and dark themes.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

/// Application entry point.
void main() async {
  // Ensures Flutter bindings are initialized before using async code.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Google Sign-In early - mobile only
  if (!kIsWeb) {
    await GoogleSignIn.instance.initialize(serverClientId: _googleWebClientId);
  }

  try {
    // Loads environment variables from the .env file.
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // Displays a warning if the .env file cannot be loaded.
    debugPrint('Warning: Could not load .env file: $e');
  }

  // Initializes Supabase configuration before the app starts.
  await SupabaseConfig.initialize();

  // Launches the Flutter application.
  runApp(const MyApp());
}

/// Custom scroll behavior that removes the default overscroll glow effect.
class _NoOverscrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child; // Returns the child without displaying overscroll effects.
}

/// Root widget of the application.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

/// Manages application-wide settings such as themes.
class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    // Primary green color used throughout the application.
    const primaryGreen = Color(0xFF4CAF50);

    return ValueListenableBuilder<ThemeMode>(
      // Listens for theme changes.
      valueListenable: themeNotifier,
      builder: (_, mode, _) {
        return MaterialApp(
          // Removes overscroll glow effect globally.
          scrollBehavior: _NoOverscrollBehavior(),

          // Application title.
          title: 'Keep It Clean',

          // Removes the debug banner in release and debug mode.
          debugShowCheckedModeBanner: false,

          // Controls whether light or dark theme is used.
          themeMode: mode,

          // ─────────────────────────────────────
          // LIGHT THEME CONFIGURATION
          // ─────────────────────────────────────
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'sans-serif',

            // Generates a color scheme based on the primary green color.
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryGreen,
              brightness: Brightness.light,
            ),

            // AppBar styling for light mode.
            appBarTheme: const AppBarTheme(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
            ),

            // Global styling for elevated buttons.
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

            // Default scaffold background color.
            scaffoldBackgroundColor: Colors.white,

            // Styling for text input fields.
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

          // ─────────────────────────────────────
          // DARK THEME CONFIGURATION
          // ─────────────────────────────────────
          darkTheme: ThemeData(
            useMaterial3: true,
            fontFamily: 'sans-serif',

            // Generates a dark color scheme based on the primary green color.
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryGreen,
              brightness: Brightness.dark,
            ),

            // AppBar styling for dark mode.
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              elevation: 0,
            ),

            // Global styling for elevated buttons in dark mode.
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

            // Background color for dark mode.
            scaffoldBackgroundColor: const Color(0xFF121212),

            // Default card color in dark mode.
            cardColor: const Color(0xFF1E1E1E),

            // Styling for input fields in dark mode.
            inputDecorationTheme: InputDecorationTheme(
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: primaryGreen),
                borderRadius: BorderRadius.circular(12),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),

              // Background color for input fields.
              fillColor: const Color(0xFF2C2C2C),
            ),
          ),

          // Determines which screen should be displayed first.
          home: const AuthGate(),
        );
      },
    );
  }
}

/// Authentication gate that controls access to the application.
///
/// If a valid user session exists, the HomePage is displayed.
/// Otherwise, the SplashScreen is shown.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      // Listens for authentication state changes from Supabase.
      stream: Supabase.instance.client.auth.onAuthStateChange,

      builder: (context, snapshot) {
        final currentSession = Supabase.instance.client.auth.currentSession;

        // Use the cached Supabase session first so OAuth returns land on HomePage
        // even if the stream has not emitted yet after a redirect or reload.
        if (currentSession != null) {
          return const HomePage();
        }

        if (snapshot.hasData) {
          final session = snapshot.data!.session;

          if (session != null) {
            return const HomePage();
          }
        }

        return const SplashScreen();
      },
    );
  }
}
