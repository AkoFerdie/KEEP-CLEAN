import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'forgot_password_page.dart';
import 'privacy_page.dart';
import 'two_factor_auth_page.dart';
import 'terms_of_service_page.dart';
import 'privacy_policy_page.dart';
import 'help_support_page.dart';
import '../utils/theme_helper.dart';
import '../main.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';


class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;

  static const _notifKey = 'notifications_enabled';

  @override
  void initState() {
    super.initState();
    _loadNotificationPref();
  }

  Future<void> _loadNotificationPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notificationsEnabled = prefs.getBool(_notifKey) ?? true;
      });
    }
  }

  Future<void> _toggleNotifications(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifKey, val);
    if (val) {
      await NotificationService.init();
    }
    if (mounted) setState(() => _notificationsEnabled = val);
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool get _darkModeEnabled => themeNotifier.value == ThemeMode.dark;

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
          "Settings",
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
          // ── Preferences ──
          _sectionLabel("Preferences"),
          _buildCard([
            _buildToggleTile(
              Icons.notifications_outlined,
              "Notifications",
              "Receive campaign & report alerts",
              _notificationsEnabled,
              _toggleNotifications,
              iconColor: Colors.orange,
            ),
            Divider(height: 1, indent: 56, color: ThemeHelper.getBorderColor(context)),
            _buildToggleTile(
              Icons.dark_mode_outlined,
              "Theme",
              _darkModeEnabled ? "Switch to light theme" : "Switch to dark theme",
              _darkModeEnabled,
              (val) {
                themeNotifier.value =
                    val ? ThemeMode.dark : ThemeMode.light;
                setState(() {});
              },
              iconColor: Colors.deepPurple,
            ),
            Divider(height: 1, indent: 56, color: ThemeHelper.getBorderColor(context)),
            _buildToggleTile(
              Icons.location_on_outlined,
              "Location Services",
              "Allow app to access your location",
              _locationEnabled,
              (val) => setState(() => _locationEnabled = val),
              iconColor: Colors.blue,
            ),
            Divider(height: 1, indent: 56, color: ThemeHelper.getBorderColor(context)),
            _buildArrowTile(Icons.language_outlined, "Language", "English", () {
              _showSnack("Language settings coming soon!");
            }, iconColor: const Color(0xFF4CAF50)),
          ]),

          const SizedBox(height: 20),

          // ── Privacy & Security ──
          _sectionLabel("Privacy & Security"),
          _buildCard([
            _buildArrowTile(Icons.lock_outline, "Change Password", "Update your password", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage()));
            }, iconColor: Colors.red),
            Divider(height: 1, indent: 56, color: ThemeHelper.getBorderColor(context)),
            _buildArrowTile(Icons.privacy_tip_outlined, "Privacy", "Manage your data & visibility", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPage()));
            }, iconColor: Colors.blue),
            Divider(height: 1, indent: 56, color: ThemeHelper.getBorderColor(context)),
            _buildArrowTile(Icons.security_outlined, "Two-Factor Authentication", "Add extra security", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TwoFactorAuthPage()));
            }, iconColor: Colors.orange),
          ]),

          const SizedBox(height: 20),

          // ── About ──
          _sectionLabel("About"),
          _buildCard([
            _buildArrowTile(Icons.description_outlined, "Terms of Service", "Read our terms", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfServicePage()));
            }, iconColor: Colors.blueGrey),
            Divider(height: 1, indent: 56, color: ThemeHelper.getBorderColor(context)),
            _buildArrowTile(Icons.policy_outlined, "Privacy Policy", "How we use your data", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()));
            }, iconColor: Colors.indigo),
            Divider(height: 1, indent: 56, color: ThemeHelper.getBorderColor(context)),
            _buildArrowTile(Icons.help_outline_rounded, "Help & Support", "Get assistance", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportPage()));
            }, iconColor: Colors.teal),
            Divider(height: 1, indent: 56, color: ThemeHelper.getBorderColor(context)),
            _buildArrowTile(Icons.star_outline_rounded, "Rate the App", "Share your feedback", () {
              _showRatingDialog();
            }, iconColor: Colors.amber),
            Divider(height: 1, indent: 56, color: ThemeHelper.getBorderColor(context)),
            _buildArrowTile(Icons.info_outline_rounded, "App Version", "v1.0.0", null, iconColor: Colors.grey),
          ]),

          const SizedBox(height: 30),
        ],
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

  Widget _buildToggleTile(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged, {Color? iconColor}) {
    final color = iconColor ?? const Color(0xFF4CAF50);
    return ListTile(
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
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: color,
      ),
    );
  }

  Widget _buildArrowTile(IconData icon, String title, String subtitle, VoidCallback? onTap, {Color? iconColor}) {
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
      ),
      trailing: onTap != null
          ? Icon(
              Icons.arrow_forward_ios_rounded, 
              size: 14, 
              color: ThemeHelper.getSecondaryTextColor(context).withValues(alpha: 0.7),
            )
          : null,
    );
  }

  void _showRatingDialog() {
    int selectedStars = 0;
    final reviewController = TextEditingController();
    final labels = ['Terrible', 'Bad', 'Okay', 'Good', 'Excellent'];
    final emojis = ['😞', '😕', '😐', '😊', '🤩'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              backgroundColor: ThemeHelper.getCardColor(context),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star_rounded, color: Color(0xFF4CAF50), size: 36),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Rate Keep It Clean',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ThemeHelper.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'How would you rate your experience?',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),

                    // Stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) {
                        final filled = i < selectedStars;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedStars = i + 1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Icon(
                              filled ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 36,
                              color: filled ? const Color(0xFFFFC107) : Colors.grey[400],
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 10),

                    // Label & emoji
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: selectedStars > 0
                          ? Row(
                              key: ValueKey(selectedStars),
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(emojis[selectedStars - 1],
                                    style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 6),
                                Text(
                                  labels[selectedStars - 1],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4CAF50),
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Tap a star to rate',
                              key: const ValueKey(0),
                              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                            ),
                    ),

                    const SizedBox(height: 20),

                    // Review text field
                    TextField(
                      controller: reviewController,
                      maxLines: 3,
                      maxLength: 200,
                      style: TextStyle(fontSize: 13, color: ThemeHelper.getTextColor(context)),
                      decoration: InputDecoration(
                        hintText: 'Write a review (optional)...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                        filled: true,
                        fillColor: ThemeHelper.getBackgroundColor(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(12),
                        counterStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              reviewController.dispose();
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Cancel', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selectedStars == 0
                                ? null
                                : () async {
                                    final review = reviewController.text.trim();
                                    reviewController.dispose();
                                    Navigator.pop(context);
                                    await _submitRating(selectedStars, review);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              disabledBackgroundColor: Colors.grey[300],
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text('Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitRating(int stars, String review) async {
    try {
      final user = SupabaseService.currentUser;
      await SupabaseService.client.from('app_ratings').insert({
        'stars': stars,
        'review': review,
        'user_id': user?.id ?? 'anonymous',
        'user_email': user?.email ?? '',
        'created_at': DateTime.now().toIso8601String(),
      });
      if (mounted) _showThankYouDialog(stars);
    } catch (e) {
      if (mounted) _showSnack('Failed to submit rating. Please try again.');
    }
  }

  void _showThankYouDialog(int stars) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: ThemeHelper.getCardColor(context),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                'Thank You!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ThemeHelper.getTextColor(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your feedback helps us improve\nKeep It Clean for everyone.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.5),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  stars,
                  (_) => const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 24),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
