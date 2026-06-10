import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/theme_helper.dart';
import '../services/supabase_service.dart';
import '../services/email_service.dart';
import '../services/sms_service.dart';
import 'trusted_devices_page.dart';

class TwoFactorAuthPage extends StatefulWidget {
  const TwoFactorAuthPage({super.key});

  @override
  State<TwoFactorAuthPage> createState() => _TwoFactorAuthPageState();
}

class _TwoFactorAuthPageState extends State<TwoFactorAuthPage> {
  bool _is2FAEnabled = false;
  bool _hasAuthenticatorApp = false;
  bool _hasEmailVerification = false;
  bool _hasSMSVerification = false;
  bool _hasBackupCodes = false;
  List<String> _backupCodes = [];
  final List<TextEditingController> _codeControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _load2FAStatus();
  }

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _load2FAStatus() async {
    // Load 2FA status from backend
    setState(() {
      _is2FAEnabled = false;
      _hasAuthenticatorApp = false;
      _hasEmailVerification = false;
      _hasSMSVerification = false;
      _hasBackupCodes = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        title: const Text(
          "Two-Factor Authentication",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Status Card
          _buildStatusCard(),
          const SizedBox(height: 20),

          // Authentication Methods
          _sectionLabel("Authentication Methods"),
          _buildCard([
            _buildMethodTile(
              Icons.phone_android,
              "Authenticator App",
              _hasAuthenticatorApp ? "Configured" : "Recommended",
              _hasAuthenticatorApp,
              () => _setupAuthenticatorApp(),
              iconColor: Colors.deepPurple,
            ),
            Divider(height: 1, indent: 56, color: ThemeHelper.getBorderColor(context)),
            _buildMethodTile(
              Icons.email_outlined,
              "Email Verification",
              _hasEmailVerification ? "Active" : "Setup required",
              _hasEmailVerification,
              () => _setupEmailVerification(),
              iconColor: Colors.blue,
            ),
            Divider(height: 1, indent: 56, color: ThemeHelper.getBorderColor(context)),
            _buildMethodTile(
              Icons.sms_outlined,
              "SMS Verification",
              _hasSMSVerification ? "Active" : "Setup required",
              _hasSMSVerification,
              () => _setupSMSVerification(),
              iconColor: Colors.teal,
            ),
          ]),

          const SizedBox(height: 20),

          // Backup & Recovery
          _sectionLabel("Backup & Recovery"),
          _buildCard([
            _buildArrowTile(
              Icons.lock_outline,
              "Backup Codes",
              _hasBackupCodes ? "Generated" : "Not generated",
              () => _showBackupCodesDialog(),
              iconColor: Colors.amber,
            ),
            Divider(height: 1, indent: 56, color: ThemeHelper.getBorderColor(context)),
            _buildArrowTile(
              Icons.devices_outlined,
              "Trusted Devices",
              "Manage devices",
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TrustedDevicesPage(),
                  ),
                );
              },
              iconColor: Colors.orange,
            ),
          ]),

          if (_is2FAEnabled) ...[
            const SizedBox(height: 30),
            OutlinedButton.icon(
              onPressed: () => _disable2FA(),
              icon: const Icon(Icons.shield_outlined, color: Colors.red),
              label: const Text("Disable Two-Factor Authentication"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _is2FAEnabled
              ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
              : [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_is2FAEnabled ? const Color(0xFF4CAF50) : Colors.orange).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _is2FAEnabled ? Icons.verified_user : Icons.security,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _is2FAEnabled ? "2FA Enabled" : "2FA Disabled",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _is2FAEnabled
                      ? "Your account is protected"
                      : "Enable for extra security",
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
          Switch(
            value: _is2FAEnabled,
            onChanged: (val) {
              if (val) {
                _enable2FA();
              } else {
                _disable2FA();
              }
            },
            activeColor: Colors.white,
            activeTrackColor: Colors.white.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodTile(IconData icon, String title, String subtitle, bool isConfigured, VoidCallback onTap, {Color? iconColor}) {
    final color = iconColor ?? const Color(0xFF4CAF50);
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: ThemeHelper.getTextColor(context),
        ),
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: ThemeHelper.getSecondaryTextColor(context),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isConfigured) ...[
            const SizedBox(width: 4),
            Icon(Icons.check_circle, color: color, size: 14),
          ],
        ],
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: ThemeHelper.getSecondaryTextColor(context).withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildArrowTile(IconData icon, String title, String subtitle, VoidCallback onTap, {Color? iconColor}) {
    final color = iconColor ?? const Color(0xFF4CAF50);
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: ThemeHelper.getTextColor(context),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: ThemeHelper.getSecondaryTextColor(context),
        ),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: ThemeHelper.getSecondaryTextColor(context).withValues(alpha: 0.7),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: ThemeHelper.getSecondaryTextColor(context),
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Material(
      color: ThemeHelper.getCardColor(context),
      borderRadius: BorderRadius.circular(16),
      shadowColor: Colors.grey.withValues(alpha: 0.15),
      elevation: 2,
      child: Column(children: children),
    );
  }

  void _enable2FA() {
    final configuredMethods = [
      _hasAuthenticatorApp,
      _hasEmailVerification,
      _hasSMSVerification,
    ].where((method) => method).length;

    if (configuredMethods < 2) {
      _showSnack("Please enable at least 2 authentication methods before activating 2FA");
      setState(() => _is2FAEnabled = false);
      return;
    }

    setState(() => _is2FAEnabled = true);
    _showSnack("Two-Factor Authentication enabled successfully!");
  }

  void _disable2FA() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeHelper.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Disable 2FA?", style: TextStyle(color: ThemeHelper.getTextColor(context))),
        content: Text(
          "Your account will be less secure. Are you sure?",
          style: TextStyle(color: ThemeHelper.getSecondaryTextColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _is2FAEnabled = false;
                _hasAuthenticatorApp = false;
                _hasEmailVerification = false;
                _hasSMSVerification = false;
                _hasBackupCodes = false;
              });
              _showSnack("Two-Factor Authentication disabled");
            },
            child: const Text("Disable", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _setupAuthenticatorApp() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: ThemeHelper.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_2, color: Color(0xFF4CAF50), size: 48),
              const SizedBox(height: 16),
              Text(
                "Setup Authenticator App",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ThemeHelper.getTextColor(context),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 180,
                      height: 180,
                      color: Colors.grey.shade200,
                      child: const Center(child: Text("QR CODE", style: TextStyle(color: Colors.grey))),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Scan with Google Authenticator or Authy",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Enter 6-digit code from your app:",
                style: TextStyle(fontSize: 13, color: ThemeHelper.getSecondaryTextColor(context)),
              ),
              const SizedBox(height: 12),
              _buildCodeInput(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _hasAuthenticatorApp = true;
                          final configuredMethods = [
                            _hasAuthenticatorApp,
                            _hasEmailVerification,
                            _hasSMSVerification,
                          ].where((method) => method).length;
                          if (configuredMethods >= 2) {
                            _is2FAEnabled = true;
                          }
                        });
                        _showSnack("Authenticator app configured!");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Verify"),
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

  Widget _buildCodeInput() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (index) {
          return Container(
            width: 40,
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: TextField(
              controller: _codeControllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ThemeHelper.getTextColor(context)),
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: ThemeHelper.getBackgroundColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                ),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                if (value.isNotEmpty && index < 5) {
                  _focusNodes[index + 1].requestFocus();
                } else if (value.isEmpty && index > 0) {
                  _focusNodes[index - 1].requestFocus();
                }
              },
            ),
          );
        }),
      ),
    );
  }

  void _setupEmailVerification() async {
    final user = SupabaseService.currentUser;
    if (user?.email == null) {
      _showSnack("No email found. Please update your profile.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: ThemeHelper.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.email_outlined, color: Color(0xFF4CAF50), size: 48),
              const SizedBox(height: 16),
              Text(
                "Email Verification",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ThemeHelper.getTextColor(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "We'll send a 6-digit code to:",
                style: TextStyle(fontSize: 13, color: ThemeHelper.getSecondaryTextColor(context)),
              ),
              const SizedBox(height: 8),
              Text(
                user!.email!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _sendEmailVerificationCode(user.email!);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Send Verification Code"),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendEmailVerificationCode(String email) async {
    _showSnack("Sending verification code to $email...");

    try {
      // Generate a 6-digit code
      final code = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
      
      // Send email via Resend API
      final success = await EmailService.send2FACode(
        toEmail: email,
        code: code,
      );

      if (mounted) {
        if (success) {
          _showSnack("✅ Verification code sent to your email!");
          _showEmailVerificationDialog(email, code);
        } else {
          _showSnack("❌ Failed to send email. Check API key in email_service.dart");
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnack("Failed to send code: ${e.toString()}");
      }
    }
  }

  void _showEmailVerificationDialog(String email, String correctCode) {
    final List<TextEditingController> emailCodeControllers = List.generate(6, (_) => TextEditingController());
    final List<FocusNode> emailFocusNodes = List.generate(6, (_) => FocusNode());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: ThemeHelper.getCardColor(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mark_email_read_outlined, color: Color(0xFF4CAF50), size: 48),
                  const SizedBox(height: 16),
                  Text(
                    "Enter Verification Code",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ThemeHelper.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Check your email for the 6-digit code",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: ThemeHelper.getSecondaryTextColor(context)),
                  ),
                  const SizedBox(height: 24),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        return Container(
                          width: 40,
                          height: 50,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: TextField(
                            controller: emailCodeControllers[index],
                            focusNode: emailFocusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ThemeHelper.getTextColor(context),
                            ),
                            decoration: InputDecoration(
                              counterText: "",
                              filled: true,
                              fillColor: ThemeHelper.getBackgroundColor(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                              ),
                            ),
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (value) {
                              if (value.isNotEmpty && index < 5) {
                                emailFocusNodes[index + 1].requestFocus();
                              } else if (value.isEmpty && index > 0) {
                                emailFocusNodes[index - 1].requestFocus();
                              }
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => _sendEmailVerificationCode(email),
                    child: const Text("Resend Code"),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            for (var controller in emailCodeControllers) {
                              controller.dispose();
                            }
                            for (var node in emailFocusNodes) {
                              node.dispose();
                            }
                            Navigator.pop(context);
                          },
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final enteredCode = emailCodeControllers.map((c) => c.text).join();
                            
                            if (enteredCode.length < 6) {
                              _showSnack("Please enter the complete code");
                              return;
                            }

                            // Verify the code
                            if (enteredCode == correctCode) {
                              for (var controller in emailCodeControllers) {
                                controller.dispose();
                              }
                              for (var node in emailFocusNodes) {
                                node.dispose();
                              }
                              Navigator.pop(context);
                              setState(() {
                                _hasEmailVerification = true;
                                final configuredMethods = [
                                  _hasAuthenticatorApp,
                                  _hasEmailVerification,
                                  _hasSMSVerification,
                                ].where((method) => method).length;
                                if (configuredMethods >= 2) {
                                  _is2FAEnabled = true;
                                }
                              });
                              _showSnack("Email verification enabled successfully!");
                            } else {
                              _showSnack("Invalid code. Please try again.");
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Verify"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _setupSMSVerification() {
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: ThemeHelper.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sms_outlined, color: Color(0xFF4CAF50), size: 48),
              const SizedBox(height: 16),
              Text(
                "SMS Verification",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ThemeHelper.getTextColor(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter your phone number",
                style: TextStyle(fontSize: 13, color: ThemeHelper.getSecondaryTextColor(context)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: ThemeHelper.getTextColor(context)),
                decoration: InputDecoration(
                  hintText: "+1 (555) 123-4567",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.phone, color: Color(0xFF4CAF50)),
                  filled: true,
                  fillColor: ThemeHelper.getBackgroundColor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        phoneController.dispose();
                        Navigator.pop(context);
                      },
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final phone = phoneController.text.trim();
                        if (phone.isEmpty) {
                          _showSnack("Please enter a phone number");
                          return;
                        }
                        phoneController.dispose();
                        Navigator.pop(context);
                        _sendSMSVerificationCode(phone);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Send Code"),
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

  void _sendSMSVerificationCode(String phoneNumber) async {
    _showSnack("Sending SMS code to $phoneNumber...");

    // Generate a random 6-digit code
    final code = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
    
    // Send SMS via Twilio
    final success = await SmsService.send2FACode(
      toPhoneNumber: phoneNumber,
      code: code,
    );

    if (mounted) {
      if (success) {
        _showSnack("✅ SMS sent to $phoneNumber!");
        _showSMSVerificationDialog(code, phoneNumber);
      } else {
        _showSnack("❌ Failed to send SMS. Check Twilio credentials in sms_service.dart");
      }
    }
  }

  void _showSMSVerificationDialog(String correctCode, String phoneNumber) {
    final List<TextEditingController> smsCodeControllers = List.generate(6, (_) => TextEditingController());
    final List<FocusNode> smsFocusNodes = List.generate(6, (_) => FocusNode());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: ThemeHelper.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sms, color: Color(0xFF4CAF50), size: 48),
              const SizedBox(height: 16),
              Text(
                "Enter SMS Code",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ThemeHelper.getTextColor(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Code sent to $phoneNumber",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: ThemeHelper.getSecondaryTextColor(context)),
              ),
              const SizedBox(height: 24),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    return Container(
                      width: 40,
                      height: 50,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: TextField(
                        controller: smsCodeControllers[index],
                        focusNode: smsFocusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ThemeHelper.getTextColor(context),
                        ),
                        decoration: InputDecoration(
                          counterText: "",
                          filled: true,
                          fillColor: ThemeHelper.getBackgroundColor(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                          ),
                        ),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            smsFocusNodes[index + 1].requestFocus();
                          } else if (value.isEmpty && index > 0) {
                            smsFocusNodes[index - 1].requestFocus();
                          }
                        },
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => _sendSMSVerificationCode(phoneNumber),
                child: const Text("Resend Code"),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        for (var controller in smsCodeControllers) {
                          controller.dispose();
                        }
                        for (var node in smsFocusNodes) {
                          node.dispose();
                        }
                        Navigator.pop(context);
                      },
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final enteredCode = smsCodeControllers.map((c) => c.text).join();
                        
                        if (enteredCode.length < 6) {
                          _showSnack("Please enter the complete code");
                          return;
                        }

                        // Verify the code
                        if (enteredCode == correctCode) {
                          for (var controller in smsCodeControllers) {
                            controller.dispose();
                          }
                          for (var node in smsFocusNodes) {
                            node.dispose();
                          }
                          Navigator.pop(context);
                          setState(() {
                            _hasSMSVerification = true;
                            final configuredMethods = [
                              _hasAuthenticatorApp,
                              _hasEmailVerification,
                              _hasSMSVerification,
                            ].where((method) => method).length;
                            if (configuredMethods >= 2) {
                              _is2FAEnabled = true;
                            }
                          });
                          _showSnack("SMS verification enabled successfully!");
                        } else {
                          _showSnack("Invalid code. Please try again.");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Verify"),
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

  void _showBackupCodesDialog() {
    if (!_hasBackupCodes) {
      _generateBackupCodes();
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: ThemeHelper.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.key, color: Color(0xFF4CAF50), size: 48),
              const SizedBox(height: 16),
              Text(
                "Backup Codes",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ThemeHelper.getTextColor(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Save these codes in a secure place",
                style: TextStyle(fontSize: 12, color: ThemeHelper.getSecondaryTextColor(context)),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ThemeHelper.getBackgroundColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ThemeHelper.getBorderColor(context)),
                ),
                child: Column(
                  children: _backupCodes.map((code) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Center(
                        child: Text(
                          code,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: ThemeHelper.getTextColor(context),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _backupCodes.join('\n')));
                        _showSnack("Codes copied to clipboard!");
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text("Copy"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Done"),
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

  void _generateBackupCodes() {
    _backupCodes = List.generate(8, (i) {
      final random = DateTime.now().millisecondsSinceEpoch + i;
      return '${random.toString().substring(0, 4)}-${random.toString().substring(4, 8)}';
    });
    setState(() => _hasBackupCodes = true);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
