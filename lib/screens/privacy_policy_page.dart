import 'package:flutter/material.dart';
import '../utils/theme_helper.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  int? _expandedSection;

  final List<Map<String, String>> _sections = [
    {
      'title': 'Introduction',
      'content': 'Keep It Clean is committed to protecting your privacy and ensuring transparency in our data practices. This Privacy Policy explains how we collect, use, disclose, and safeguard your personal information when you use our mobile application and services.',
    },
    {
      'title': 'Information We Collect',
      'content': 'Personal Information: Name, email address, phone number (for SMS verification), profile picture, username, and encrypted password.\n\nAuthentication Data: Google OAuth credentials, two-factor authentication settings, login timestamps, and session information.\n\nUsage Data: App features accessed, campaign and report data, device information (model, OS version), location data (when enabled), and app ratings/reviews.',
    },
    {
      'title': 'How We Collect Information',
      'content': 'We collect information through multiple channels: account registration and profile setup, Google OAuth authentication, direct user input when using app features, automated collection through device sensors (with your permission), cookies and similar tracking technologies, and integration with third-party services such as Supabase, Twilio, and Resend.',
    },
    {
      'title': 'How We Use Your Information',
      'content': 'Your information is used to: provide and maintain the service, authenticate your identity and secure your account, send two-factor authentication codes via SMS and email, process and manage campaigns and reports, deliver notifications about app activities, improve functionality and user experience, respond to support requests, detect and prevent fraud or abuse, and comply with legal obligations.',
    },
    {
      'title': 'Information Sharing',
      'content': 'We do NOT sell your personal information. We share data only with: Service Providers (Supabase for database and authentication, Twilio for SMS delivery, Resend for email delivery, Google for OAuth authentication), when required by law or legal process, to protect our rights and safety, to prevent fraud or security issues, and in connection with business transfers such as mergers or acquisitions.',
    },
    {
      'title': 'Data Security',
      'content': 'We implement industry-standard security measures including: encryption of data in transit using HTTPS/TLS, encrypted password storage with secure hashing algorithms, optional two-factor authentication, secure cloud infrastructure provided by Supabase, and regular security audits and updates. However, no internet transmission method is 100% secure, and we cannot guarantee absolute security.',
    },
    {
      'title': 'Data Retention',
      'content': 'We retain your information as long as your account is active or as needed to provide services. When you delete your account, most personal data is deleted immediately. Some data may be retained for legal compliance or legitimate business purposes. Backup copies may exist for up to 90 days after deletion.',
    },
    {
      'title': 'Your Privacy Rights',
      'content': 'You have the right to: access your personal information, correct inaccurate or incomplete data, delete your account and associated data, export your data (data portability), opt-out of notifications and marketing communications, withdraw consent for optional features, and object to processing in certain circumstances. Exercise these rights through the app\'s privacy settings or by contacting us.',
    },
    {
      'title': 'Children\'s Privacy',
      'content': 'Keep It Clean is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If we discover that we have collected information from a child under 13, we will delete it immediately. Parents or guardians who believe we may have collected information from a child should contact us.',
    },
    {
      'title': 'Location Data',
      'content': 'When you enable location services, we collect your device\'s GPS coordinates for campaign and report location features. Location data is stored securely and is not shared publicly without your explicit consent. You can disable location services at any time through the app settings. Disabling location may limit certain features.',
    },
    {
      'title': 'Cookies and Tracking',
      'content': 'We use session cookies for authentication, local storage for app preferences and settings, and analytics tools to improve app performance. You can disable cookies through your device settings, but this may affect app functionality. We do not use cookies for advertising or tracking across other websites.',
    },
    {
      'title': 'Third-Party Links',
      'content': 'Our app may contain links to third-party websites, services, or resources. We are not responsible for the privacy practices or content of these third parties. We encourage you to review their privacy policies before providing any personal information.',
    },
    {
      'title': 'International Data Transfers',
      'content': 'Your information may be transferred to and stored on servers located in different countries. By using Keep It Clean, you consent to the transfer of your information to countries that may have different data protection laws. We ensure that adequate safeguards are in place to protect your information during international transfers.',
    },
    {
      'title': 'Changes to This Policy',
      'content': 'We may update this Privacy Policy periodically to reflect changes in our practices or legal requirements. Significant changes will be communicated via email notification, in-app notification, and an updated "Effective Date" at the top of this policy. Your continued use of the service after changes take effect constitutes acceptance of the updated policy.',
    },
    {
      'title': 'California Privacy Rights (CCPA)',
      'content': 'California residents have additional rights under the California Consumer Privacy Act: right to know what personal information is collected, right to know whether we sell or share information (we do not), right to opt-out of the sale of information, right to deletion of personal information, right to non-discrimination for exercising privacy rights, and right to designate an authorized agent to make requests.',
    },
    {
      'title': 'European Privacy Rights (GDPR)',
      'content': 'If you are in the European Economic Area, you have rights under the General Data Protection Regulation: right to access your data, right to rectification of inaccurate data, right to erasure ("right to be forgotten"), right to restrict processing, right to data portability, right to object to processing, right to withdraw consent at any time, and right to lodge a complaint with a supervisory authority.',
    },
    {
      'title': 'Data Breach Notification',
      'content': 'In the event of a data breach that affects your personal information, we will notify you within 72 hours of becoming aware of the breach. Notification will include the nature of the breach, affected data categories, potential consequences, and measures taken to address the breach.',
    },
    {
      'title': 'Contact Us',
      'content': 'For questions, concerns, or requests regarding this Privacy Policy or your personal information, contact us at:\n\nEmail: privacy@keepitclean.com\nData Protection Officer: dpo@keepitclean.com\nAddress: Keep It Clean Privacy Team\n\nWe will respond to inquiries within 30 days.',
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
          "Privacy Policy",
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ThemeHelper.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ThemeHelper.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.privacy_tip, color: Colors.indigo, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Keep It Clean",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ThemeHelper.getTextColor(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Privacy Policy",
                            style: TextStyle(
                              fontSize: 13,
                              color: ThemeHelper.getSecondaryTextColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: ThemeHelper.getBorderColor(context)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: ThemeHelper.getSecondaryTextColor(context)),
                    const SizedBox(width: 6),
                    Text(
                      "Effective Date: January 1, 2024",
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeHelper.getSecondaryTextColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.update, size: 14, color: ThemeHelper.getSecondaryTextColor(context)),
                    const SizedBox(width: 6),
                    Text(
                      "Last Updated: January 1, 2024",
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeHelper.getSecondaryTextColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Your privacy is important to us. This policy explains how we collect, use, protect, and share your personal information.",
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: ThemeHelper.getTextColor(context),
            ),
          ),
          const SizedBox(height: 24),
          ..._sections.asMap().entries.map((entry) {
            final index = entry.key;
            final section = entry.value;
            return _buildSection(context, index + 1, section['title']!, section['content']!);
          }).toList(),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                const Icon(Icons.shield, color: Colors.indigo, size: 40),
                const SizedBox(height: 12),
                Text(
                  "Your Privacy Matters",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ThemeHelper.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "We are committed to protecting your personal information and being transparent about our data practices. You have control over your data and can exercise your rights at any time.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: ThemeHelper.getTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, int number, String title, String content) {
    final isExpanded = _expandedSection == number;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: ThemeHelper.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        shadowColor: Colors.grey.withValues(alpha: 0.1),
        elevation: 1,
        child: InkWell(
          onTap: () => setState(() => _expandedSection = isExpanded ? null : number),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          number.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
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
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(left: 44),
                    child: Text(
                      content,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: ThemeHelper.getTextColor(context),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
