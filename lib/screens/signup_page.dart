import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/supabase_service.dart';
import 'signin_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedRole;
  final List<String> _roles = [
    "User",
    "Organization / Volunteer",
    "Government Company (Hysacam)",
  ];

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  bool _agree = false;

  final Color _bgColor = const Color(0xFFF5F5F5);

  Future<void> _signUp() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final role = _selectedRole;

    if (username.isEmpty || email.isEmpty || password.isEmpty || role == null) {
      _showSnackBar("All fields are required");
      return;
    }

    if (!_agree) {
      _showSnackBar("You must agree to the terms");
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar("Passwords do not match");
      return;
    }

    try {
      setState(() => _isLoading = true);

      await SupabaseService.signUp(
        email: email,
        password: password,
        username: username,
        role: role,
      );

      _showSnackBar("Verification email sent 📧 and user data saved!");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SignInPage()),
      );
    } catch (e) {
      print("🔥 SUPABASE ERROR: ${e.toString()}");
      print("🔥 ERROR TYPE: ${e.runtimeType}");
      
      String message = "Signup failed: ${e.toString()}";

      if (e.toString().contains('email_provider_disabled')) {
        message = "❌ Email signup is disabled in Supabase.\n\nFix: Go to Supabase Dashboard → Authentication → Providers → Enable Email";
      } else if (e.toString().contains('email_address_invalid')) {
        message = "❌ Email format rejected by Supabase.\n\nTry: Use a different email format (e.g., firstname.lastname@gmail.com)";
      } else if (e.toString().contains('User already registered')) {
        message = "Email already in use. Try signing in instead.";
      } else if (e.toString().contains('Password should be at least 6 characters')) {
        message = "Password must be at least 6 characters";
      } else if (e.toString().contains('Unable to validate email address')) {
        message = "Invalid email address format";
      } else if (e.toString().contains('Invalid email')) {
        message = "Invalid email address";
      }

      _showSnackBar(message);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool obscureText = false,
    VoidCallback? onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w500),
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF4CAF50), size: 18),
        ),
        suffixIcon: onToggle != null
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF4CAF50),
                ),
                onPressed: onToggle,
              )
            : null,
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

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      isExpanded: true,
      dropdownColor: Colors.white,
      items: _roles
          .map((role) => DropdownMenuItem(
                value: role,
                child: Text(role, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
              ))
          .toList(),
      onChanged: (value) => setState(() => _selectedRole = value),
      decoration: InputDecoration(
        labelText: "Select Role",
        labelStyle: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w500),
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.account_circle, color: Color(0xFF4CAF50), size: 18),
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

  Widget _buildTerms() {
    return Row(
      children: [
        Checkbox(
          value: _agree,
          activeColor: const Color(0xFF4CAF50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          onChanged: (value) => setState(() => _agree = value ?? false),
        ),
        const Expanded(
          child: Text.rich(
            TextSpan(
              text: "I agree to the ",
              style: TextStyle(fontSize: 12.5, color: Colors.black54),
              children: [
                TextSpan(
                  text: "Terms of Use",
                  style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w600),
                ),
                TextSpan(text: " and "),
                TextSpan(
                  text: "Privacy Policy",
                  style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: _bgColor,
        appBar: AppBar(
          backgroundColor: _bgColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF4CAF50)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            color: _bgColor,
            child: SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(24, 10, 24, bottomInset + 10),
                child: Column(
                  children: [
              Center(child: Image.asset('assets/front_logo.png', width: 65, height: 65)),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Keep It Clean',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Create Account',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
                ),
              ),
              const SizedBox(height: 4),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Fill in your details to get started',
                  style: TextStyle(fontSize: 13, color: Colors.black45),
                ),
              ),
              const SizedBox(height: 24),

              _buildTextField(
                label: "Username",
                icon: Icons.person,
                controller: _usernameController,
              ),
              const SizedBox(height: 8),

              _buildTextField(
                label: "Email",
                icon: Icons.email,
                controller: _emailController,
              ),
              const SizedBox(height: 8),

              _buildDropdown(),
              const SizedBox(height: 8),

              _buildTextField(
                label: "Password",
                icon: Icons.lock,
                controller: _passwordController,
                obscureText: !_showPassword,
                onToggle: () =>
                    setState(() => _showPassword = !_showPassword),
              ),
              const SizedBox(height: 8),

              _buildTextField(
                label: "Confirm Password",
                icon: Icons.lock_outline,
                controller: _confirmPasswordController,
                obscureText: !_showConfirmPassword,
                onToggle: () =>
                    setState(() => _showConfirmPassword =
                        !_showConfirmPassword),
              ),
              const SizedBox(height: 10),

              _buildTerms(),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22, width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          "Create Account",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? ",
                      style: TextStyle(fontSize: 13)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignInPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Sign In",
                      style: TextStyle(
                        fontSize: 13,
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
    ));
  }
}