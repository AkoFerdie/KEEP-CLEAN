import 'package:flutter/material.dart';
import 'package:keep_it_clean/services/payment_service_mesomb.dart';
import 'package:keep_it_clean/services/supabase_service.dart';

class PaymentPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> requestData;

  const PaymentPage({
    super.key,
    required this.docId,
    required this.requestData,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? _selectedProvider;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isProcessing = false;
  String _statusMessage = '';

  final List<Map<String, dynamic>> _paymentProviders = [
    {
      'name': 'MTN Mobile Money',
      'value': 'mtn',
      'color': Color(0xFFFFD700),
      'icon': Icons.phone_android,
    },
    {
      'name': 'Orange Money',
      'value': 'orange',
      'color': Color(0xFFFF6600),
      'icon': Icons.phone_android,
    },
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_selectedProvider == null) {
      _showSnackBar('Please select a payment method', isError: true);
      return;
    }
    if (_amountController.text.isEmpty) {
      _showSnackBar('Please enter payment amount', isError: true);
      return;
    }
    if (int.tryParse(_amountController.text.trim()) == null || int.parse(_amountController.text.trim()) < 10) {
      _showSnackBar('Minimum payment amount is 10 FCFA', isError: true);
      return;
    }
    if (_phoneController.text.isEmpty) {
      _showSnackBar('Please enter your phone number', isError: true);
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Sending payment request...';
    });

    try {
      final result = await PaymentService.initiatePayment(
        phoneNumber: _phoneController.text.trim(),
        amount: _amountController.text.trim(),
        provider: _selectedProvider!,
      );

      print('Payment Result: $result');

      if (result['success'] != true) {
        final errorMsg = result['message'] ?? result['error'] ?? 'Payment failed';
        throw Exception(errorMsg);
      }

      // Payment request sent — wait for user to respond to USSD PIN prompt
      if (mounted) {
        setState(() => _statusMessage = '📱 Check your phone and enter your PIN...');
      }

      await Future.delayed(const Duration(seconds: 5));

      if (mounted) {
        setState(() => _statusMessage = '✅ Confirming payment...');
      }

      await Future.delayed(const Duration(seconds: 1));

      // Finalize — accept the waste request
      if (mounted) {
        final user = SupabaseService.currentUser;
        if (user != null) {
          final userProfile = await SupabaseService.getUserProfile(user.id);
          final username = userProfile?['username'] ?? user.email ?? 'Someone';

          await SupabaseService.acceptWasteRequest(widget.docId, username);

          Navigator.pop(context);
          _showSnackBar(
            '✅ Payment successful! Pickup accepted. Contact: ${widget.requestData['phone']}',
          );
        }
      }
    } catch (e) {
      _showSnackBar('❌ Payment failed: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = '';
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF4CAF50),
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF4),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          'Payment Required',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(w * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF4CAF50)),
                      SizedBox(width: 8),
                      Text(
                        'Unlock Pickup Access',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pay a small token to unlock access to this pickup opportunity. This helps maintain our platform and support the community.',
                    style: TextStyle(
                      fontSize: w * 0.035,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: w * 0.06),

            // Payment method selection
            const Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            ..._paymentProviders.map((provider) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: RadioListTile<String>(
                    value: provider['value'],
                    groupValue: _selectedProvider,
                    onChanged: _isProcessing
                        ? null
                        : (value) => setState(() => _selectedProvider = value),
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (provider['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            provider['icon'],
                            color: provider['color'],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          provider['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    activeColor: const Color(0xFF4CAF50),
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _selectedProvider == provider['value']
                            ? const Color(0xFF4CAF50)
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                )),

            SizedBox(height: w * 0.06),

            // Phone number input
            const Text(
              'Your Phone Number',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              enabled: !_isProcessing,
              decoration: InputDecoration(
                hintText: 'Enter your phone number',
                prefixIcon: const Icon(Icons.phone, color: Color(0xFF4CAF50)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF4CAF50), width: 2),
                ),
              ),
            ),

            SizedBox(height: w * 0.04),

            // Amount input
            const Text(
              'Payment Amount (FCFA)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              enabled: !_isProcessing,
              decoration: InputDecoration(
                hintText: 'Enter amount (e.g. 100)',
                prefixIcon: const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFF4CAF50),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF4CAF50), width: 2),
                ),
              ),
            ),

            SizedBox(height: w * 0.06),

            // Status banner while processing
            if (_isProcessing && _statusMessage.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4CAF50)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Color(0xFF4CAF50),
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: w * 0.04),
            ],

            // Pay button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Processing Payment...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Pay & Unlock Pickup',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            SizedBox(height: w * 0.04),
          ],
        ),
      ),
    );
  }
}