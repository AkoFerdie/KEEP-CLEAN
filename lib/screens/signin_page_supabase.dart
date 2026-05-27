import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../services/supabase_service.dart';
import 'signup_page.dart';
import 'forgot_password_page.dart';
import 'home_page.dart';

class SignInPageSupabase extends StatefulWidget {
  const SignInPageSupabase({super.key});

  @override
  State<SignInPageSupabase> createState() => _SignInPageSupabaseState();
}

class _SignInPageSupabaseState extends State<SignInPageSupabase> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showPassword = false;
  bool _isSigningIn = false;

  final Color _bgColor = const Color(0xFFF2F2F2);

  // ---------------- EMAIL / USERNAME SIGN IN ----------------
  Future<void> _signInWithEmailPassword() async {
    final input = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      _showSnackBar("Please enter your email/username and password.");
      return;
    }

    setState(() => _isSigningIn = true);

    try {
      // Check if input is email or username
      if (input.contains('@')) {
        // Sign in with email
        await SupabaseService.signIn(email: input, password: password);
      } else {
        // Sign in with username
        await SupabaseService.signInWithUsername(username: input, password: password);
      }

      _showSnackBar("Signed in successfully!");

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      String message = "Sign in failed.";
      
      if (e.toString().contains('Invalid login credentials')) {
        message = "Invalid email/username or password.";
      } else if (e.toString().contains('Email not confirmed')) {
        message = "Please check your email and confirm your account.";
      } else if (e.toString().contains('Too many requests')) {
        message = "Too many attempts. Please try again later.";
      }
      
      _showSnackBar(message);
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF4CAF50)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 10,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 20,
                ),
                child: IntrinsicHeight(
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
                        "Email or Username",
                        Icons.person_outline,
                      ),
                      const SizedBox(height: 12),
                      _buildPasswordField(
                        _passwordController,
                        "Password",
                        Icons.lock_outline,
                        showPassword: _showPassword,
                        onToggle: () =>
                            setState(() => _showPassword = !_showPassword),
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
                            "Forgot Password?",
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
                          onPressed: _isSigningIn ? null : _signInWithEmailPassword,
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
                                  height: 22, width: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  "Sign in",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
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
                              "Sign Up",
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
            );
          },
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
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String label,
    IconData icon, {
    required bool showPassword,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !showPassword,
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
            showPassword ? Icons.visibility : Icons.visibility_off,
            color: const Color(0xFF4CAF50),
          ),
          onPressed: onToggle,
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
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
    );
  }
}
