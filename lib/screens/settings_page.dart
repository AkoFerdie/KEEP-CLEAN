import 'package:flutter/material.dart';
import 'forgot_password_page.dart';
import '../utils/theme_helper.dart';
import '../main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;

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
              (val) => setState(() => _notificationsEnabled = val),
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
            ),
            Divider(height: 1, indent: 56, color: ThemeHelper.getBorderColor(context)),
            _buildToggleTile(
              Icons.location_on_outlined,
              "Location Services",
              "Allow app to access your location",
              _locationEnabled,
              (val) => setState(() => _locationEnabled = val),
            ),
            Divider(height: 1, indent: 56, color: ThemeHelper.getBorderColor(context)),
            _buildArrowTile(Icons.language_outlined, "Language", "English", () {
              _showSnack("Language settings coming soon!");
            }),
          ]),

          const SizedBox(height: 20),

          // ── Privacy & Security ──
          _sectionLabel("Privacy & Security"),
          _buildCard([
            _buildArrowTile(Icons.lock_outline, "Change Password", "Update your password", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage()));
            }),
            Divider(height: 1, indent: 56, color: ThemeHelper.getBorderColor(context)),
            _buildArrowTile(Icons.privacy_tip_outlined, "Privacy", "Manage your data & visibility", () {
              _showSnack("Privacy settings coming soon!");
            }),
            Divider(height: 1, indent: 56, color: ThemeHelper.getBorderColor(context)),
            _buildArrowTile(Icons.security_outlined, "Two-Factor Authentication", "Add extra security", () {
              _showSnack("2FA coming soon!");
            }),
          ]),

          const SizedBox(height: 20),

          // ── About ──
          _sectionLabel("About"),
          _buildCard([
            _buildArrowTile(Icons.description_outlined, "Terms of Service", "Read our terms", () {
              _showSnack("Terms of Service coming soon!");
            }),
            Divider(height: 1, indent: 56, color: ThemeHelper.getBorderColor(context)),
            _buildArrowTile(Icons.policy_outlined, "Privacy Policy", "How we use your data", () {
              _showSnack("Privacy Policy coming soon!");
            }),
            Divider(height: 1, indent: 56, color: ThemeHelper.getBorderColor(context)),
            _buildArrowTile(Icons.help_outline_rounded, "Help & Support", "Get assistance", () {
              _showSnack("Help & Support coming soon!");
            }),
            Divider(height: 1, indent: 56, color: ThemeHelper.getBorderColor(context)),
            _buildArrowTile(Icons.star_outline_rounded, "Rate the App", "Share your feedback", () {
              _showSnack("Rate app coming soon!");
            }),
            Divider(height: 1, indent: 56, color: ThemeHelper.getBorderColor(context)),
            _buildArrowTile(Icons.info_outline_rounded, "App Version", "v1.0.0", null),
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
    return Container(
      decoration: BoxDecoration(
        color: ThemeHelper.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          ThemeHelper.getCardShadow(context),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildToggleTile(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
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
        activeColor: const Color(0xFF4CAF50),
      ),
    );
  }

  Widget _buildArrowTile(IconData icon, String title, String subtitle, VoidCallback? onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
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
              color: ThemeHelper.getSecondaryTextColor(context).withOpacity(0.7),
            )
          : null,
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
