import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import '../services/supabase_service.dart';
import 'getting_started_page.dart';
import 'home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _logoImage = AssetImage('assets/front_logo.png');
  static const _gettingStartedImage = AssetImage('assets/Picture2.png');

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _rotateController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotateAnimation;

  bool _disposed = false;
  bool _isPreparingAssets = false;
  bool _assetsReady = false;
  bool _hasNavigated = false;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
        );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );

    // Start animations immediately with slight delay for smoother feel
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!_disposed) {
        _fadeController.forward();
        _scaleController.forward();
        _slideController.forward();
        _rotateController.repeat();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_assetsReady && !_isPreparingAssets) {
      _prepareSplash();
    }
  }

  Future<void> _prepareSplash() async {
    _isPreparingAssets = true;

    // Listen for OAuth sign-in redirect
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      if (data.event == AuthChangeEvent.signedIn && !_hasNavigated) {
        _navigateToHomePage();
      }
    });

    // Run init + asset caching with a 2 second hard timeout
    await Future.wait([
      _initializeApp(),
      precacheImage(_logoImage, context).catchError((_) {}),
      precacheImage(_gettingStartedImage, context).catchError((_) {}),
    ]).timeout(
      const Duration(seconds: 2),
      onTimeout: () => [], // 👈 move on after 2s no matter what
    );

    if (!mounted || _disposed || _hasNavigated) return;

    setState(() => _assetsReady = true);

    // Check if already signed in
    final session = Supabase.instance.client.auth.currentSession;
    final user = SupabaseService.currentUser;

    if (session != null || user != null) {
      _navigateToHomePage();
      return;
    }

    // Check for OAuth redirect in URL
    final uri = Uri.base;
    final isOAuthRedirect = uri.fragment.contains('access_token') ||
        uri.queryParameters.containsKey('code');

    if (isOAuthRedirect) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted || _disposed || _hasNavigated) return;

      final sessionAfterWait = Supabase.instance.client.auth.currentSession;
      if (sessionAfterWait != null) {
        _navigateToHomePage();
        return;
      }
    }

    // No session — go to getting started
    _navigateToGettingStarted();
  }

  Future<void> _initializeApp() async {
    try {
      await SupabaseConfig.initialize();
    } catch (e) {
      debugPrint('Warning: Supabase initialization failed: $e');
    }
  }

  void _navigateToHomePage() {
    if (!mounted || _disposed || _hasNavigated) return;
    _hasNavigated = true;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomePage(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            ),
            child: child,
          );
        },
      ),
    );
  }



  Future<void> _navigateToGettingStarted() async {
    if (!mounted || _hasNavigated) return;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const GettingStartedPage(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _authSubscription?.cancel();
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32), Color(0xFF1B5E20)],
              stops: [0.0, 0.6, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // More decorative circles for depth
              Positioned(
                top: -20,
                left: -40,
                child: AnimatedBuilder(
                  animation: _rotateAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: -_rotateAnimation.value * 2 * 3.14159,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 100,
                right: -50,
                child: AnimatedBuilder(
                  animation: _rotateAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotateAnimation.value * 2 * 3.14159,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                bottom: 100,
                right: 20,
                child: AnimatedBuilder(
                  animation: _rotateAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotateAnimation.value * 2 * 3.14159,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                bottom: 150,
                left: -30,
                child: AnimatedBuilder(
                  animation: _rotateAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: -_rotateAnimation.value * 2 * 3.14159,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                    );
                  },
                ),
              ),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.15,
                          ),
                          FutureBuilder(
                            future: precacheImage(
                              const AssetImage('assets/front_logo.png'),
                              context,
                            ),
                            builder: (context, snapshot) {
                              return ScaleTransition(
                                scale: _scaleAnimation,
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(35),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        spreadRadius: 0,
                                        blurRadius: 30,
                                        offset: const Offset(0, 10),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        spreadRadius: 0,
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Image.asset(
                                      'assets/front_logo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(
                                            Icons.eco,
                                            size: 80,
                                            color: Color(0xFF4CAF50),
                                          ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 60),
                          SlideTransition(
                            position: _slideAnimation,
                            child: const Text(
                              'Keep It Clean',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.5,
                                height: 1.2,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 4),
                                    blurRadius: 12,
                                    color: Colors.black26,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SlideTransition(
                            position: _slideAnimation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  width: 1.5,
                                ),
                              ),
                              child: const Text(
                                'Waste Solutions at Your Fingertips',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 90),
                          SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.15),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Loading...',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}