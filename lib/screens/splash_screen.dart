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
<<<<<<< HEAD
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 1000),
=======
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 1200),
>>>>>>> fc87ae7548b0858df8bc785774cf4ce207103555
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );
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

    // Start animations immediately — don't wait for anything
    _startAnimations();

    // Listen for OAuth sign-in redirect
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      if (data.event == AuthChangeEvent.signedIn && !_hasNavigated) {
        _navigateToHomePage();
      }
    });

<<<<<<< HEAD
    // Run init + asset caching with a 1 second hard timeout
=======
    // Run init + asset caching with a 2 second hard timeout
>>>>>>> fc87ae7548b0858df8bc785774cf4ce207103555
    await Future.wait([
      _initializeApp(),
      precacheImage(_logoImage, context).catchError((_) {}),
      precacheImage(_gettingStartedImage, context).catchError((_) {}),
    ]).timeout(
<<<<<<< HEAD
      const Duration(milliseconds: 600),
      onTimeout: () => [], // 👈 move on after 0.6s no matter what
=======
      const Duration(seconds: 2),
      onTimeout: () => [], // 👈 move on after 2s no matter what
>>>>>>> fc87ae7548b0858df8bc785774cf4ce207103555
    );

    if (!mounted || _disposed || _hasNavigated) return;

    setState(() => _assetsReady = true);

    // Check if already signed in
    final session = Supabase.instance.client.auth.currentSession;
    final user = SupabaseService.currentUser;

    if (session != null || user != null) {
<<<<<<< HEAD
      await _navigateToHomePage();
=======
      _navigateToHomePage();
>>>>>>> fc87ae7548b0858df8bc785774cf4ce207103555
      return;
    }

    // Check for OAuth redirect in URL
    final uri = Uri.base;
    final isOAuthRedirect = uri.fragment.contains('access_token') ||
<<<<<<< HEAD
        uri.queryParameters.containsKey('code') ||
        uri.fragment.contains('error');

    if (isOAuthRedirect) {
      // Check if there's an error in the URL
      if (uri.fragment.contains('error')) {
        debugPrint('OAuth error detected, navigating to getting started');
        _navigateToGettingStarted();
        return;
      }

      // Wait briefly for session to be established
      await Future.delayed(const Duration(milliseconds: 300));
=======
        uri.queryParameters.containsKey('code');

    if (isOAuthRedirect) {
      await Future.delayed(const Duration(milliseconds: 1500));
>>>>>>> fc87ae7548b0858df8bc785774cf4ce207103555
      if (!mounted || _disposed || _hasNavigated) return;

      final sessionAfterWait = Supabase.instance.client.auth.currentSession;
      if (sessionAfterWait != null) {
<<<<<<< HEAD
        await _navigateToHomePage();
=======
        _navigateToHomePage();
>>>>>>> fc87ae7548b0858df8bc785774cf4ce207103555
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

<<<<<<< HEAD
  Future<void> _navigateToHomePage() async {
    if (!mounted || _disposed || _hasNavigated) return;
    _hasNavigated = true;

    // Ensure user profile exists before navigating
    try {
      await SupabaseService.ensureCurrentUserProfile();
    } catch (e) {
      debugPrint('Profile creation failed: $e');
    }

    if (!mounted) return;
=======
  void _navigateToHomePage() {
    if (!mounted || _disposed || _hasNavigated) return;
    _hasNavigated = true;
>>>>>>> fc87ae7548b0858df8bc785774cf4ce207103555

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomePage(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
<<<<<<< HEAD
          return FadeTransition(
            opacity: animation,
=======
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            ),
>>>>>>> fc87ae7548b0858df8bc785774cf4ce207103555
            child: child,
          );
        },
      ),
    );
  }

  Future<void> _startAnimations() async {
<<<<<<< HEAD
    await Future.delayed(const Duration(milliseconds: 50));
    if (_disposed) return;
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    if (_disposed) return;
    _scaleController.forward();
    await Future.delayed(const Duration(milliseconds: 80));
=======
    await Future.delayed(const Duration(milliseconds: 100));
    if (_disposed) return;
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    if (_disposed) return;
    _scaleController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
>>>>>>> fc87ae7548b0858df8bc785774cf4ce207103555
    if (_disposed) return;
    _slideController.forward();
    if (_disposed) return;
    _rotateController.repeat();
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
                          color: Colors.white.withValues(alpha: 0.1),
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
                          color: Colors.white.withValues(alpha: 0.08),
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
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: AnimatedOpacity(
                              opacity: _assetsReady ? 1 : 0,
                              duration: const Duration(milliseconds: 150),
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      spreadRadius: 3,
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Image(
                                    image: _logoImage,
                                    fit: BoxFit.contain,
                                    gaplessPlayback: true,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(
                                          Icons.eco,
                                          size: 80,
                                          color: Color(0xFF4CAF50),
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 50),
                          SlideTransition(
                            position: _slideAnimation,
                            child: const Text(
                              'Keep It Clean',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 2.0,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 3),
                                    blurRadius: 8,
                                    color: Colors.black26,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          SlideTransition(
                            position: _slideAnimation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'Waste Solutions at Your Fingertips',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 80),
                          SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Loading...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 1.0,
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