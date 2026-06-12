import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentService {
  static final _supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>> initiatePayment({
    required String phoneNumber,
    required String amount,
    required String provider,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'mesomb-payment',
        body: {
          'amount': int.parse(amount),
          'service': provider == 'mtn' ? 'MTN' : 'ORANGE',
          'payer': phoneNumber,
        },
      ).timeout(const Duration(seconds: 60));

      final data = response.data as Map<String, dynamic>;
      print('Payment Response: $data');
      // Handle 502/HTML error responses
      if (data['message'] != null && data['message'].toString().contains('<html>')) {
        return {'success': false, 'message': 'Payment server temporarily unavailable. Please try again.'};
      }
      return data;
    } catch (e) {
      print('Payment error: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> checkPaymentStatus(String transactionId) async {
    try {
      final response = await _supabase.functions.invoke(
        'mesomb-payment',
        body: {
          'action': 'status',
          'transactionId': transactionId,
        },
      );

      final data = response.data as Map<String, dynamic>;
      return data;
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}