import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  // Resend API key (free tier: 100 emails/day)
  // Get your free API key from: https://resend.com/api-keys
  static const String _resendApiKey = 're_S3SDDXJF_Du6NsZQjSL6EmSHqZzAokFEr';
  static const String _fromEmail = 'onboarding@resend.dev'; // Resend test email

  /// Send 2FA verification code via email
  static Future<bool> send2FACode({
    required String toEmail,
    required String code,
  }) async {
    // TESTING MODE: Check if API key is set
    if (_resendApiKey == 're_123456789_YOUR_API_KEY_HERE' || _resendApiKey.isEmpty) {
      print('⚠️ TESTING MODE: No API key set. Code would be sent to $toEmail');
      print('🔐 TEST CODE: $code');
      print('💡 To send real emails, add your Resend API key in email_service.dart');
      return true;
    }

    try {
      // Try to send email (will work on mobile/desktop, not web due to CORS)
      final response = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer $_resendApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': _fromEmail,
          'to': [toEmail],
          'subject': '🔐 Your Keep It Clean Verification Code',
          'html': _buildEmailTemplate(code),
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Email sent successfully to $toEmail');
        return true;
      } else {
        print('❌ Failed to send email: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      // CORS error on web - show code for testing
      if (e.toString().contains('Failed to fetch') || e.toString().contains('CORS')) {
        print('⚠️ WEB CORS ERROR: Cannot send emails from browser');
        print('🔐 TEST CODE for $toEmail: $code');
        print('💡 Emails work on mobile/desktop apps!');
        print('💡 For web, you need a backend API or Edge Function');
        return true; // Return true so user can still test with code from console
      }
      print('❌ Error sending email: $e');
      return false;
    }
  }

  /// Build HTML email template
  static String _buildEmailTemplate(String code) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      line-height: 1.6;
      color: #333;
      max-width: 600px;
      margin: 0 auto;
      padding: 20px;
      background-color: #f5f5f5;
    }
    .container {
      background-color: white;
      border-radius: 16px;
      padding: 40px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    .logo {
      text-align: center;
      margin-bottom: 30px;
    }
    .logo-circle {
      width: 80px;
      height: 80px;
      background: linear-gradient(135deg, #4CAF50 0%, #66BB6A 100%);
      border-radius: 50%;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      font-size: 40px;
    }
    h1 {
      color: #4CAF50;
      text-align: center;
      margin: 0 0 10px 0;
      font-size: 24px;
    }
    .subtitle {
      text-align: center;
      color: #666;
      margin-bottom: 30px;
      font-size: 14px;
    }
    .code-container {
      background: linear-gradient(135deg, #4CAF50 0%, #66BB6A 100%);
      border-radius: 12px;
      padding: 30px;
      text-align: center;
      margin: 30px 0;
    }
    .code {
      font-size: 48px;
      font-weight: bold;
      letter-spacing: 10px;
      color: white;
      font-family: 'Courier New', monospace;
      text-shadow: 0 2px 4px rgba(0,0,0,0.2);
    }
    .code-label {
      color: rgba(255,255,255,0.9);
      font-size: 14px;
      margin-top: 10px;
    }
    .info {
      background-color: #f8f9fa;
      border-left: 4px solid #4CAF50;
      padding: 15px;
      margin: 20px 0;
      border-radius: 4px;
    }
    .info-title {
      font-weight: 600;
      color: #4CAF50;
      margin-bottom: 5px;
    }
    .footer {
      text-align: center;
      color: #999;
      font-size: 12px;
      margin-top: 30px;
      padding-top: 20px;
      border-top: 1px solid #eee;
    }
    .warning {
      background-color: #fff3cd;
      border-left: 4px solid #ffc107;
      padding: 12px;
      margin: 20px 0;
      border-radius: 4px;
      font-size: 13px;
      color: #856404;
    }
    .button {
      display: inline-block;
      background-color: #4CAF50;
      color: white;
      padding: 12px 30px;
      text-decoration: none;
      border-radius: 8px;
      font-weight: 600;
      margin: 10px 0;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">
      <div class="logo-circle">🌱</div>
    </div>
    
    <h1>Two-Factor Authentication</h1>
    <p class="subtitle">Your security code for Keep It Clean</p>
    
    <div class="code-container">
      <div class="code">$code</div>
      <div class="code-label">Enter this code in the app</div>
    </div>
    
    <div class="info">
      <div class="info-title">🔒 Security Information</div>
      <p style="margin: 5px 0; font-size: 14px;">
        • This code expires in 10 minutes<br>
        • Don't share this code with anyone<br>
        • We will never ask for this code via phone or email
      </p>
    </div>
    
    <div class="warning">
      ⚠️ <strong>Didn't request this code?</strong><br>
      If you didn't try to enable 2FA on your Keep It Clean account, please ignore this email and secure your account immediately.
    </div>
    
    <div class="footer">
      <p><strong>Keep It Clean</strong> - Waste Solutions at Your Fingertips</p>
      <p>This is an automated email. Please do not reply.</p>
      <p style="margin-top: 10px; color: #ccc;">
        © 2024 Keep It Clean. All rights reserved.
      </p>
    </div>
  </div>
</body>
</html>
    ''';
  }
}
