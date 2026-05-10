import 'package:flutter/material.dart';

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
      _showSnackBar('Please select a payment method');
      return;
    }

    if (_amountController.text.isEmpty) {
      _showSnackBar('Please enter payment amount');
      return;
    }

    if (_phoneController.text.isEmpty) {
      _showSnackBar('Please enter your phone number');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 3));

      // After successful payment, show accept dialog
      if (mounted) {
        Navigator.pop(context); // Close payment page
        _showAcceptDialog();
      }
    } catch (e) {
      _showSnackBar('Payment failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showAcceptDialog() {
    final w = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.handshake_outlined, color: Color(0xFF4CAF50)),
            SizedBox(width: 8),
            Text('Pickup Request',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📍 ${widget.requestData['location'] ?? ''}',
                style: TextStyle(fontSize: w * 0.035, color: Colors.black87)),
            const SizedBox(height: 6),
            Text('⏰ Pickup time: ${_formatPickupTime(widget.requestData['pickupTime'])}',
                style: TextStyle(fontSize: w * 0.033, color: Colors.black54)),
            const SizedBox(height: 6),
            Text('💰 Amount: ${widget.requestData['amount'] ?? '0'} FCFA',
                style: TextStyle(
                    fontSize: w * 0.033,
                    color: const Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('📞 Contact: ${widget.requestData['phone'] ?? 'N/A'}',
                style: TextStyle(fontSize: w * 0.033, color: Colors.black54)),
            const SizedBox(height: 12),
            const Text(
              'Payment successful! Do you want to accept this pickup request?',
              style: TextStyle(fontSize: 13, color: Colors.black45),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Decline',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Here you would call the accept request function
              _showSnackBar('Pickup request accepted successfully!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Accept',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  String _formatPickupTime(dynamic value) {
    if (value == null) return 'Flexible';
    return value.toString();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF4CAF50),
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
                    color: Colors.green.withOpacity(0.1),
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
                onChanged: (value) => setState(() => _selectedProvider = value),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: provider['color'].withOpacity(0.1),
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
                  borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
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
              decoration: InputDecoration(
                hintText: 'Enter amount (e.g. 100)',
                prefixIcon: const Icon(Icons.account_balance_wallet, color: Color(0xFF4CAF50)),
                filled: true,
                fillColor: Colors.white,
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

            SizedBox(height: w * 0.08),

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
          ],
        ),
      ),
    );
  }
}