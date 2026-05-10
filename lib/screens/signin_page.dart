import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'signup_page.dart';
import 'forgot_password_page.dart';
import 'home_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showPassword = false;
  bool _isSigningIn = false;
  bool _isSigningInWithGoogle = false;
  bool _isSigningInWithFacebook = false;

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
      String emailToUse = input;

      // If input is not an email, look up the username in Firestore
      if (!input.contains('@')) {
        final query = await _firestore
            .collection('users')
            .where('username', isEqualTo: input)
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          _showSnackBar("No account found with that username.");
          return;
        }

        emailToUse = query.docs.first.data()['email'] ?? '';

        if (emailToUse.isEmpty) {
          _showSnackBar("Could not retrieve email for this username.");
          return;
        }
      }

      await _auth.signInWithEmailAndPassword(
        email: emailToUse,
        password: password,
      );

      _showSnackBar("Signed in successfully!");

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "Sign in failed.";
      if (e.code == 'user-not-found') {
        message = "No user found for that email.";
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = "Incorrect password. Please try again.";
      } else if (e.code == 'invalid-email') {
        message = "The email address is not valid.";
      } else if (e.code == 'network-request-failed') {
        message = "No internet connection.";
      }
      _showSnackBar(message);
    } catch (e) {
      _showSnackBar("An unexpected error occurred: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  // ---------------- GOOGLE SIGN IN ----------------
  Future<void> _signInWithGoogle() async {
    setState(() => _isSigningInWithGoogle = true);

    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();

      final userCredential = await _auth.signInWithPopup(googleProvider);

      final user = userCredential.user;

      if (user != null) {
        final userDoc = _firestore.collection('users').doc(user.uid);
        final docSnapshot = await userDoc.get();

        if (!docSnapshot.exists) {
          await userDoc.set({
            'username': user.displayName ?? 'Google User',
            'email': user.email,
            'role': 'User',
            'createdAt': FieldValue.serverTimestamp(),
          });

          _showSnackBar("Signed in with Google and new user data saved!");
        } else {
          _showSnackBar("Signed in with Google!");
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = "Google Sign-In failed.";

      if (e.code == 'account-exists-with-different-credential') {
        message =
            "An account already exists with the same email but different credentials.";
      } else if (e.code == 'network-request-failed') {
        message = "No internet connection.";
      }

      _showSnackBar(message);
    } catch (e) {
      _showSnackBar("Error during Google Sign-In: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isSigningInWithGoogle = false);
      }
    }
  }

  // ---------------- FACEBOOK SIGN IN (FIXED) ----------------
  Future<void> _signInWithFacebook() async {
    setState(() => _isSigningInWithFacebook = true);

    try {
      final facebookProvider = FacebookAuthProvider();

      final userCredential = await _auth.signInWithPopup(facebookProvider);

      final user = userCredential.user;

      if (user != null) {
        final userDoc = _firestore.collection('users').doc(user.uid);
        final docSnapshot = await userDoc.get();

        if (!docSnapshot.exists) {
          await userDoc.set({
            'username': user.displayName ?? 'Facebook User',
            'email': user.email,
            'role': 'User',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        _showSnackBar("Signed in with Facebook!");

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        final pendingCredential = e.credential;

        if (pendingCredential != null) {
          try {
            _showSnackBar(
                "Account exists with another provider. Signing you in with Google...");

            final googleProvider = GoogleAuthProvider();
            final googleUser = await _auth.signInWithPopup(googleProvider);

            await googleUser.user!.linkWithCredential(pendingCredential);

            _showSnackBar("Facebook linked to your Google account successfully!");

            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            }
          } on FirebaseAuthException catch (linkError) {
            _showSnackBar("Linking failed: ${linkError.message}");
          }
        } else {
          _showSnackBar(
              "An account already exists with this email. Please sign in with your original provider.");
        }
      } else {
        _showSnackBar("Facebook Sign-In failed: ${e.message}");
      }
    } catch (e) {
      _showSnackBar("Facebook Error: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isSigningInWithFacebook = false);
      }
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
                "Email",
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
              const SizedBox(height: 20),
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text("OR"),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              _buildSocialButton(
                "Continue with Google",
                "assets/google.png",
                iconSize: 26,
                onPressed: _isSigningInWithGoogle ? null : _signInWithGoogle,
                isLoading: _isSigningInWithGoogle,
              ),
              const SizedBox(height: 12),
              _buildSocialButton(
                "Continue with Facebook",
                "assets/facebook.png",
                iconSize: 26,
                onPressed: _isSigningInWithFacebook ? null : _signInWithFacebook,
                isLoading: _isSigningInWithFacebook,
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
  }
Widget _buildSocialButton(
  String text,
  String imagePath, {
  double iconSize = 20,
  VoidCallback? onPressed,
  bool isLoading = false,
  Color borderColor = const Color(0xFFDDDDDD),
}) {
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
          ? const SizedBox(
              height: 22, width: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(imagePath, width: iconSize, height: iconSize),
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
            color: const Color(0xFF4CAF50).withOpacity(0.1),
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
            color: const Color(0xFF4CAF50).withOpacity(0.1),
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
