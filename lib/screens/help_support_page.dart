import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/theme_helper.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  int? _expandedIndex;

  final List<Map<String, dynamic>> _faqs = [
    {
      'category': 'Getting Started',
      'icon': Icons.rocket_launch_outlined,
      'questions': [
        {
          'q': 'How do I create my first campaign?',
          'a': 'Tap the + button on the home screen, select "New Campaign", fill in the details including title, description, location, and images. Then tap "Create Campaign" to publish it.',
        },
        {
          'q': 'How do I edit my profile?',
          'a': 'Go to Settings → tap your profile card at the top, then tap "Edit Profile". You can update your name, email, phone number, and profile picture.',
        },
        {
          'q': 'What is Keep It Clean about?',
          'a': 'Keep It Clean is a community-driven app for reporting environmental issues, organizing cleanup campaigns, and making your neighborhood cleaner and safer.',
        },
      ],
    },
    {
      'category': 'Account & Security',
      'icon': Icons.security_outlined,
      'questions': [
        {
          'q': 'How do I reset my password?',
          'a': 'On the login screen, tap "Forgot Password", enter your email, and you\'ll receive a password reset link. You can also reset it from Settings → Change Password.',
        },
        {
          'q': 'What is Two-Factor Authentication (2FA)?',
          'a': '2FA adds an extra layer of security by requiring a code from your phone or email in addition to your password. Enable it in Settings → Privacy & Security → Two-Factor Authentication.',
        },
        {
          'q': 'How do I enable 2FA?',
          'a': 'Go to Settings → Two-Factor Authentication. Set up at least 2 methods (Authenticator App, Email, or SMS). Once 2 methods are configured, toggle 2FA on.',
        },
        {
          'q': 'I didn\'t receive my 2FA code. What should I do?',
          'a': 'For SMS: Check your signal and ensure the number is correct. For Email: Check spam/junk folders. Wait 1-2 minutes and try "Resend Code". If issues persist, use backup codes or contact support.',
        },
      ],
    },
    {
      'category': 'Campaigns & Reports',
      'icon': Icons.campaign_outlined,
      'questions': [
        {
          'q': 'How do I join a campaign?',
          'a': 'Browse campaigns on the home screen, tap on one to view details, then tap the "Join Campaign" button. You\'ll be added as a participant.',
        },
        {
          'q': 'How do I report an environmental issue?',
          'a': 'Tap the + button, select "Report Issue", add photos, description, and location, then submit. The report will be visible to the community and authorities.',
        },
        {
          'q': 'Can I edit or delete my campaign?',
          'a': 'Yes! Tap on your campaign, then tap the menu icon (⋮) and select "Edit" or "Delete". Note: Deleting is permanent.',
        },
      ],
    },
    {
      'category': 'Privacy & Data',
      'icon': Icons.privacy_tip_outlined,
      'questions': [
        {
          'q': 'What data do you collect?',
          'a': 'We collect your name, email, phone number (optional), profile picture, campaign/report data, and location (if enabled). See our Privacy Policy for full details.',
        },
        {
          'q': 'How do I delete my account?',
          'a': 'Go to Settings → Privacy → Delete Account. This action is permanent and will remove all your data including campaigns and reports.',
        },
        {
          'q': 'Can I download my data?',
          'a': 'Yes, go to Settings → Privacy → Download My Data. You\'ll receive a file with all your personal information, campaigns, and activity.',
        },
        {
          'q': 'Who can see my location?',
          'a': 'Your exact location is never shared publicly. Only campaign/report locations you manually add are visible. You can disable location services anytime in Settings.',
        },
      ],
    },
    {
      'category': 'Troubleshooting',
      'icon': Icons.build_outlined,
      'questions': [
        {
          'q': 'The app won\'t let me log in. What should I do?',
          'a': 'Check your internet connection, ensure your email and password are correct, and try resetting your password. If using Google Sign-In, ensure you have a stable connection.',
        },
        {
          'q': 'Notifications aren\'t working. How do I fix this?',
          'a': 'Go to Settings → Preferences → ensure Notifications are enabled. Also check your device settings to allow notifications for this app.',
        },
        {
          'q': 'Location features aren\'t working. What should I do?',
          'a': 'Ensure location permissions are granted in your device settings. Go to Settings → Preferences → enable Location Services. Make sure GPS is turned on.',
        },
        {
          'q': 'The app keeps crashing. What should I do?',
          'a': 'Try closing and reopening the app. If it persists, clear the app cache in your device settings, or uninstall and reinstall the app. Contact support if the issue continues.',
        },
      ],
    },
  ];

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
          "Help & Support",
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
          // Contact Support Cards
          _buildContactCard(
            context,
            Icons.email_outlined,
            "Email Support",
            "Get help via email",
            "keepitcleanfixed@gmail.com",
            () async {
              final uri = Uri(
                scheme: 'mailto',
                path: 'keepitcleanfixed@gmail.com',
                queryParameters: {
                  'subject': 'Help & Support - Keep It Clean App',
                },
              );
              await launchUrl(uri);
            },
          ),
          const SizedBox(height: 12),
          _buildContactCard(
            context,
            Icons.chat_bubble_outline,
            "Live Chat",
            "Chat with our support team",
            "Available 9 AM - 5 PM",
            () => _showSnack("Live chat coming soon!"),
          ),
          const SizedBox(height: 30),

          // FAQs
          Text(
            "Frequently Asked Questions",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ThemeHelper.getTextColor(context),
            ),
          ),
          const SizedBox(height: 16),

          ..._faqs.asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value;
            return _buildFAQCategory(
              context,
              index,
              category['icon'],
              category['category'],
              category['questions'],
            );
          }).toList(),

          const SizedBox(height: 30),

          // Report a Problem
          _buildActionCard(
            context,
            Icons.bug_report_outlined,
            "Report a Problem",
            "Found a bug or issue?",
            Colors.orange,
            () => _showReportDialog(),
          ),
          const SizedBox(height: 12),

          // Request a Feature
          _buildActionCard(
            context,
            Icons.lightbulb_outline,
            "Request a Feature",
            "Share your ideas with us",
            Colors.blue,
            () => _showFeatureRequestDialog(),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, IconData icon, String title, String subtitle, String detail, VoidCallback onTap) {
    return Material(
      color: ThemeHelper.getCardColor(context),
      borderRadius: BorderRadius.circular(16),
      shadowColor: Colors.grey.withValues(alpha: 0.15),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF4CAF50), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ThemeHelper.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeHelper.getSecondaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: ThemeHelper.getSecondaryTextColor(context).withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQCategory(BuildContext context, int categoryIndex, IconData icon, String category, List<Map<String, String>> questions) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: ThemeHelper.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        shadowColor: Colors.grey.withValues(alpha: 0.15),
        elevation: 2,
        child: Column(
          children: [
            // Category Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: ThemeHelper.getTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            // Questions
            ...questions.asMap().entries.map((entry) {
              final qIndex = entry.key;
              final item = entry.value;
              final globalIndex = categoryIndex * 100 + qIndex;
              final isExpanded = _expandedIndex == globalIndex;

              return Column(
                children: [
                  if (qIndex > 0) Divider(height: 1, indent: 16, endIndent: 16, color: ThemeHelper.getBorderColor(context)),
                  InkWell(
                    onTap: () => setState(() => _expandedIndex = isExpanded ? null : globalIndex),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['q']!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: ThemeHelper.getTextColor(context),
                                  ),
                                ),
                              ),
                              Icon(
                                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: ThemeHelper.getSecondaryTextColor(context),
                              ),
                            ],
                          ),
                          if (isExpanded) ...[
                            const SizedBox(height: 8),
                            Text(
                              item['a']!,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: ThemeHelper.getSecondaryTextColor(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return Material(
      color: ThemeHelper.getCardColor(context),
      borderRadius: BorderRadius.circular(16),
      shadowColor: Colors.grey.withValues(alpha: 0.15),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ThemeHelper.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeHelper.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: ThemeHelper.getSecondaryTextColor(context).withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();

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
              const Icon(Icons.bug_report, color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              Text(
                "Report a Problem",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ThemeHelper.getTextColor(context),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                style: TextStyle(color: ThemeHelper.getTextColor(context)),
                decoration: InputDecoration(
                  labelText: "Problem Title",
                  hintText: "Brief description",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 4,
                style: TextStyle(color: ThemeHelper.getTextColor(context)),
                decoration: InputDecoration(
                  labelText: "Details",
                  hintText: "Describe the issue...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        titleController.dispose();
                        descController.dispose();
                        Navigator.pop(context);
                      },
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        titleController.dispose();
                        descController.dispose();
                        Navigator.pop(context);
                        _showSnack("Problem report submitted!");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Submit"),
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

  void _showFeatureRequestDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();

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
              const Icon(Icons.lightbulb, color: Colors.blue, size: 48),
              const SizedBox(height: 16),
              Text(
                "Request a Feature",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ThemeHelper.getTextColor(context),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                style: TextStyle(color: ThemeHelper.getTextColor(context)),
                decoration: InputDecoration(
                  labelText: "Feature Name",
                  hintText: "What feature do you want?",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 4,
                style: TextStyle(color: ThemeHelper.getTextColor(context)),
                decoration: InputDecoration(
                  labelText: "Description",
                  hintText: "Explain how it would work...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        titleController.dispose();
                        descController.dispose();
                        Navigator.pop(context);
                      },
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        titleController.dispose();
                        descController.dispose();
                        Navigator.pop(context);
                        _showSnack("Feature request submitted!");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Submit"),
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

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
