import 'dart:convert';
import 'package:http/http.dart' as http;

class SmsService {
  // Twilio credentials - Set these via environment variables
  // Get free trial from: https://www.twilio.com/try-twilio
  static const String _twilioAccountSid = String.fromEnvironment('TWILIO_ACCOUNT_SID', defaultValue: '');
  static const String _twilioAuthToken = String.fromEnvironment('TWILIO_AUTH_TOKEN', defaultValue: '');
  static const String _twilioPhoneNumber = String.fromEnvironment('TWILIO_PHONE_NUMBER', defaultValue: '');

  /// Send 2FA verification code via SMS
  static Future<bool> send2FACode({
    required String toPhoneNumber,
    required String code,
  }) async {
    // TESTING MODE: Check if credentials are set
    if (_twilioAccountSid == 'YOUR_TWILIO_ACCOUNT_SID' || 
        _twilioAccountSid.isEmpty ||
        _twilioAuthToken == 'YOUR_TWILIO_AUTH_TOKEN' ||
        _twilioAuthToken.isEmpty) {
      print('⚠️ TESTING MODE: No Twilio credentials set');
      print('🔐 TEST CODE for $toPhoneNumber: $code');
      print('💡 To send real SMS, add your Twilio credentials in sms_service.dart');
      print('💡 Get free trial: https://www.twilio.com/try-twilio');
      return true;
    }

    try {
      // Format phone number (must include country code)
      final formattedPhone = _formatPhoneNumber(toPhoneNumber);
      
      // Build message
      final message = '''Keep It Clean - Verification Code

Your 2FA code is: $code

This code expires in 10 minutes.
Don't share this code with anyone.

- Keep It Clean Team''';

      // Send SMS via Twilio
      final credentials = base64Encode(utf8.encode('$_twilioAccountSid:$_twilioAuthToken'));
      
      final response = await http.post(
        Uri.parse('https://api.twilio.com/2010-04-01/Accounts/$_twilioAccountSid/Messages.json'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': _twilioPhoneNumber,
          'To': formattedPhone,
          'Body': message,
        },
      );

      if (response.statusCode == 201) {
        print('✅ SMS sent successfully to $formattedPhone');
        return true;
      } else {
        print('❌ Failed to send SMS: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      // Handle web CORS or other errors
      if (e.toString().contains('Failed to fetch') || e.toString().contains('CORS')) {
        print('⚠️ WEB CORS ERROR: Cannot send SMS from browser');
        print('🔐 TEST CODE for $toPhoneNumber: $code');
        print('💡 SMS works on mobile/desktop apps!');
        print('💡 For web, you need a backend API');
        return true;
      }
      print('❌ Error sending SMS: $e');
      return false;
    }
  }

  /// Format phone number to E.164 format (+1234567890)
  static String _formatPhoneNumber(String phone) {
    // Remove all non-digit characters
    String digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // If doesn't start with +, add country code
    if (!digits.startsWith('+')) {
      // Assume US/Canada if no country code (+1)
      digits = '+1$digits';
    }
    
    return digits;
  }
}
