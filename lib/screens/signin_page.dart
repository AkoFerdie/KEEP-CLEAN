import 'dart:async';
import '../google_auth.dart'; // ✅ covers both Google and Facebook now
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


import '../services/supabase_service.dart';
import 'forgot_password_page.dart';
import 'home_page.dart';
import 'signup_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showPassword = false;
  bool _isSigningIn = false;
  bool _isSigningInWithGoogle = false;
  bool _isSigningInWithFacebook = false;
  bool _hasNavigatedHome = false;

  StreamSubscription<AuthState>? _authSubscription;

  final Color _bgColor = const Color(0xFFF2F2F2);

  // 👇 Email format validator
  final _emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');

  @override
  void initState() {
    super.initState();
    // Remove auth state listener to prevent navigation conflicts
  }

  Future<bool> _handleBackPressed() async {
    final focusedNode = FocusManager.instance.primaryFocus;

    if (focusedNode != null && focusedNode.context?.widget is EditableText) {
      focusedNode.unfocus();
      return false;
    }

    Navigator.pop(context);
    return false;
  }

  Future<void> _goHomeAfterSignIn() async {
    if (_hasNavigatedHome) return;
    _hasNavigatedHome = true;

    try {
      await SupabaseService.ensureCurrentUserProfile();
    } catch (e) {
      if (mounted) {
        _showSnackBar('Signed in, but profile setup failed', isError: true);
      }
      _hasNavigatedHome = false;
      return;
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  Future<void> _signInWithEmailPassword() async {
    final input = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      _showSnackBar(
        'Please enter your email/username and password.',
        isError: true,
      );
      return;
    }

    // 👇 If input looks like an email, validate the format
    if (input.contains('@') && !_emailRegex.hasMatch(input)) {
      _showSnackBar(
        'Please enter a valid email address (e.g. name@gmail.com).',
        isError: true,
      );
      return;
    }

    setState(() => _isSigningIn = true);

    try {
      if (input.contains('@')) {
        await SupabaseService.signIn(email: input, password: password);
      } else {
        await SupabaseService.signInWithUsername(
          username: input,
          password: password,
        );
      }

      _showSnackBar('Signed in successfully!', isError: false);
      await _goHomeAfterSignIn();
    } catch (e) {
      String message = 'Sign in failed.';

      if (e.toString().contains('Invalid login credentials')) {
        message = 'Invalid email/username or password.';
      } else if (e.toString().contains('Email not confirmed')) {
        message = 'Please check your email and confirm your account.';
      } else if (e.toString().contains('Too many requests')) {
        message = 'Too many attempts. Please try again later.';
      }

      _showSnackBar(message, isError: true);
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isSigningInWithGoogle = true);
    await Future<void>.delayed(Duration.zero);

    try {
      await signInWithGoogleViaSupabase();

      if (!kIsWeb && mounted && SupabaseService.currentUser != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted && !e.toString().contains('popup_closed_by_user')) {
        _showSnackBar('Google sign in failed', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSigningInWithGoogle = false);
    }
  }

  Future<void> _signInWithFacebook() async {
  setState(() => _isSigningInWithFacebook = true);

  try {
    await signInWithFacebookViaSupabase();

    if (!kIsWeb && mounted) {
      _showSnackBar(
        'Complete Facebook sign in in your browser',
        isError: false,
      );
    }
  } catch (e) {
    if (mounted && !e.toString().contains('popup_closed_by_user')) {
      _showSnackBar('Facebook sign in failed', isError: true);
    }
  } finally {
    if (mounted) setState(() => _isSigningInWithFacebook = false);
  }
}

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor:
            isError ? const Color(0xFFD32F2F) : const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackPressed,
      child: Scaffold(
        backgroundColor: _bgColor,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: _bgColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: Color(0xFFF2F2F2),
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF4CAF50),
            ),
            onPressed: _handleBackPressed,
          ),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            color: _bgColor,
            child: SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  24,
                  10,
                  24,
                  MediaQuery.of(context).viewInsets.bottom + 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    Image.asset('assets/front_logo.png', width: 70),
                    const SizedBox(height: 6),
                    const Text(
                      'Keep It Clean',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Welcome back, sign in to continue',
                        style: TextStyle(fontSize: 13, color: Colors.black45),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildOutlinedField(
                      _emailController,
                      'Email or Username',
                      Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
                    _buildPasswordField(
                      _passwordController,
                      'Password',
                      Icons.lock_outline,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _isSigningIn ? null : _signInWithEmailPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF43A047),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSigningIn
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Sign in',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('OR'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSocialButton(
                      'Continue with Google',
                      'Opening Google...',
                      'assets/google.png',
                      _isSigningInWithGoogle,
                      _signInWithGoogle,
                    ),
                    const SizedBox(height: 12),
                    _buildSocialButton(
                      'Continue with Facebook',
                      'Opening Facebook...',
                      'assets/facebook.png',
                      _isSigningInWithFacebook,
                      _signInWithFacebook,
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account ? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignUpPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(
    String text,
    String loadingText,
    String imagePath,
    bool isLoading,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF43A047),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    loadingText,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(imagePath, width: imagePath.contains('google') ? 38 : 32, height: imagePath.contains('google') ? 38 : 32),
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOutlinedField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF4CAF50), size: 18),
        ),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDEEDD), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 12,
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      obscureText: !_showPassword,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF4CAF50), size: 18),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _showPassword ? Icons.visibility : Icons.visibility_off,
            color: const Color(0xFF4CAF50),
          ),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDEEDD), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 12,
        ),
      ),
    );
  }
}