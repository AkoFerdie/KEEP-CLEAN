import 'package:flutter/material.dart';
import '../utils/theme_helper.dart';

class TermsOfServicePage extends StatefulWidget {
  const TermsOfServicePage({super.key});

  @override
  State<TermsOfServicePage> createState() => _TermsOfServicePageState();
}

class _TermsOfServicePageState extends State<TermsOfServicePage> {
  int? _expandedSection;

  final List<Map<String, String>> _sections = [
    {
      'title': 'Acceptance of Terms',
      'content': 'By creating an account and using Keep It Clean, you agree to be bound by these Terms of Service. If you do not agree to these terms, you may not access or use the service. These terms apply to all users, including organizers, participants, and visitors.',
    },
    {
      'title': 'Account Registration',
      'content': 'You must provide accurate, current, and complete information during registration. You are responsible for maintaining the confidentiality of your account credentials and for all activities under your account. You must immediately notify us of any unauthorized use of your account. You must be at least 13 years old to create an account.',
    },
    {
      'title': 'User Conduct',
      'content': 'You agree to use the service only for lawful purposes and in accordance with these Terms. You will not:\n\n• Violate any applicable laws or regulations\n• Harass, threaten, or harm other users\n• Post false, misleading, or fraudulent content\n• Attempt to gain unauthorized access to the service\n• Transmit viruses, malware, or harmful code\n• Impersonate others or misrepresent your affiliation\n• Spam or send unsolicited communications',
    },
    {
      'title': 'Content Ownership and License',
      'content': 'You retain ownership of all content you submit, including campaigns, reports, photos, and comments. By posting content, you grant Keep It Clean a worldwide, non-exclusive, royalty-free license to use, reproduce, modify, and display your content solely for operating and improving the service. You represent that you have all necessary rights to the content you post.',
    },
    {
      'title': 'Content Moderation',
      'content': 'We reserve the right to review, monitor, and remove any content that violates these Terms or is otherwise objectionable. We may, but are not obligated to, moderate user-generated content. Content removal does not imply liability for content posted by users.',
    },
    {
      'title': 'Privacy and Data Protection',
      'content': 'Your use of the service is also governed by our Privacy Policy, which describes how we collect, use, and protect your personal information. By using Keep It Clean, you consent to our data practices as outlined in the Privacy Policy.',
    },
    {
      'title': 'Two-Factor Authentication',
      'content': 'SMS and email verification codes are provided for account security. Standard message and data rates may apply from your carrier. We are not responsible for delays, failures, or costs associated with code delivery. You are responsible for maintaining access to your authentication methods and storing backup codes securely.',
    },
    {
      'title': 'Third-Party Services',
      'content': 'The service integrates with third-party providers including Google (authentication), Supabase (data storage), Twilio (SMS), and Resend (email). Your use of these integrated services is subject to their respective terms of service. We are not responsible for the practices or policies of third-party services.',
    },
    {
      'title': 'Intellectual Property',
      'content': 'The Keep It Clean service, including its software, design, text, graphics, logos, and trademarks, is owned by us and protected by copyright, trademark, and other intellectual property laws. You may not copy, modify, distribute, or create derivative works without our express written permission.',
    },
    {
      'title': 'Disclaimers',
      'content': 'THE SERVICE IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT. We do not guarantee that the service will be uninterrupted, secure, or error-free. Use of the service is at your own risk.',
    },
    {
      'title': 'Limitation of Liability',
      'content': 'TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, OR ANY LOSS OF PROFITS, REVENUE, DATA, OR USE, ARISING OUT OF OR RELATED TO YOUR USE OF THE SERVICE. Our total liability shall not exceed the amount you paid us in the past 12 months, if any.',
    },
    {
      'title': 'Account Termination',
      'content': 'We may suspend or terminate your account at any time for violations of these Terms or for any other reason at our sole discretion. You may delete your account at any time through the app settings. Upon termination, your right to use the service immediately ceases. Some information may be retained as required by law or for legitimate business purposes.',
    },
    {
      'title': 'Modifications to Terms',
      'content': 'We reserve the right to modify these Terms at any time. We will provide notice of significant changes via email or in-app notification at least 30 days before they take effect. Your continued use of the service after the effective date constitutes acceptance of the modified Terms.',
    },
    {
      'title': 'Dispute Resolution',
      'content': 'Any disputes arising from these Terms or your use of the service shall first be attempted to be resolved through good-faith negotiation. If negotiation fails, disputes shall be resolved through binding arbitration in accordance with applicable arbitration rules, except where prohibited by law.',
    },
    {
      'title': 'Governing Law',
      'content': 'These Terms shall be governed by and construed in accordance with applicable laws, without regard to conflict of law principles. You consent to the exclusive jurisdiction of the appropriate courts for any disputes not subject to arbitration.',
    },
    {
      'title': 'Indemnification',
      'content': 'You agree to indemnify, defend, and hold harmless Keep It Clean and its affiliates from any claims, damages, losses, liabilities, and expenses (including legal fees) arising from your use of the service, your content, or your violation of these Terms.',
    },
    {
      'title': 'Severability',
      'content': 'If any provision of these Terms is found to be unenforceable or invalid, that provision shall be limited or eliminated to the minimum extent necessary, and the remaining provisions shall remain in full force and effect.',
    },
    {
      'title': 'Contact Information',
      'content': 'For questions, concerns, or notices regarding these Terms of Service, please contact us at:\n\nEmail: legal@keepitclean.com\nAddress: Keep It Clean Legal Department\n\nWe will respond to inquiries within 5 business days.',
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
          "Terms of Service",
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
          // Header
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
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.description, color: Color(0xFF4CAF50), size: 28),
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
                            "Terms of Service Agreement",
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

          // Introduction
          Text(
            "Please read these Terms of Service carefully before using Keep It Clean. These terms constitute a legally binding agreement between you and Keep It Clean.",
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: ThemeHelper.getTextColor(context),
            ),
          ),
          const SizedBox(height: 24),

          // Sections
          ..._sections.asMap().entries.map((entry) {
            final index = entry.key;
            final section = entry.value;
            return _buildSection(context, index + 1, section['title']!, section['content']!);
          }),

          const SizedBox(height: 24),

          // Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50), size: 40),
                const SizedBox(height: 12),
                Text(
                  "Agreement Acknowledgment",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ThemeHelper.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "By creating an account and using Keep It Clean, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.",
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
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          number.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
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
