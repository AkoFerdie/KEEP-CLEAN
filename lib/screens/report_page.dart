import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'payment_page.dart';
import '../utils/theme_helper.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          // Tab bar
          Container(
            color: ThemeHelper.getCardColor(context),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF4CAF50),
              unselectedLabelColor: ThemeHelper.getSecondaryTextColor(context),
              indicatorColor: const Color(0xFF4CAF50),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: const [
                Tab(text: 'Browse Pickups'),
                Tab(text: 'Schedule Pickup'),
              ],
            ),
          ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _WasteRequestFeed(),
              _PostWasteRequest(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// FEED — Browse all waste pickup requests
// ─────────────────────────────────────────────
class _WasteRequestFeed extends StatelessWidget {
  const _WasteRequestFeed();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('waste_requests')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined,
                    size: w * 0.18, color: ThemeHelper.getSecondaryTextColor(context).withOpacity(0.3)),
                const SizedBox(height: 12),
                Text('No waste requests yet.',
                    style: TextStyle(
                        fontSize: w * 0.04, color: Colors.grey[700])),
                const SizedBox(height: 6),
                Text('Be the first to post one!',
                    style: TextStyle(
                        fontSize: w * 0.035, color: Colors.grey[600])),
              ],
            ),
          );
        }

        final docs = [...snapshot.data!.docs];
        docs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt'];
          final bTime = (b.data() as Map<String, dynamic>)['createdAt'];
          final aMillis = (aTime is Timestamp) ? aTime.millisecondsSinceEpoch : 0;
          final bMillis = (bTime is Timestamp) ? bTime.millisecondsSinceEpoch : 0;
          return bMillis.compareTo(aMillis);
        });

        return ListView.builder(
          padding: EdgeInsets.all(w * 0.04),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _WasteRequestCard(data: data, docId: doc.id);
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// CARD — Single waste request post
// ─────────────────────────────────────────────
class _WasteRequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const _WasteRequestCard({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final List imageUrls = data['imageUrls'] ?? [];
    final String status = data['status'] ?? 'open';
    final currentUser = FirebaseAuth.instance.currentUser;

    final statusColor = status == 'taken'
        ? Colors.orange
        : status == 'done'
            ? const Color(0xFF4CAF50)
            : const Color(0xFF1E88E5);
    final statusLabel =
        status == 'taken' ? 'Taken' : status == 'done' ? 'Done' : 'Open';

    return Container(
      margin: EdgeInsets.only(bottom: w * 0.04),
      decoration: BoxDecoration(
        color: ThemeHelper.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          ThemeHelper.getCardShadow(context),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: EdgeInsets.all(w * 0.04),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      const Color(0xFF4CAF50).withOpacity(0.15),
                  child: const Icon(Icons.person,
                      color: Color(0xFF4CAF50), size: 20),
                ),
                SizedBox(width: w * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['postedBy'] ?? 'Anonymous',
                        style: TextStyle(
                            fontSize: w * 0.038,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800]),
                      ),
                      Text(
                        data['location'] ?? '',
                        style: TextStyle(
                            fontSize: w * 0.032, color: Colors.grey[700]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: status == 'open' && data['createdBy'] != currentUser?.uid
                      ? GestureDetector(
                          onTap: () => _showAcceptDialog(context, docId, data),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                                fontSize: w * 0.03,
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline),
                          ),
                        )
                      : Text(
                          statusLabel,
                          style: TextStyle(
                              fontSize: w * 0.03,
                              color: statusColor,
                              fontWeight: FontWeight.w700),
                        ),
                ),
              ],
            ),
          ),

          // ── Waste Image ──
          if (imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.zero),
              child: Image.network(
                imageUrls[0],
                height: w * 0.55,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: w * 0.4,
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.broken_image_outlined,
                      color: Colors.black26, size: 40),
                ),
              ),
            ),

          // ── Details ──
          Padding(
            padding: EdgeInsets.all(w * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((data['description'] ?? '').isNotEmpty)
                  Text(
                    data['description'],
                    style: TextStyle(
                        fontSize: w * 0.036, color: Colors.grey[800], height: 1.4),
                  ),
                SizedBox(height: w * 0.03),

                // Info chips row
                Wrap(
                  spacing: w * 0.02,
                  runSpacing: w * 0.02,
                  children: [
                    _infoChip(Icons.access_time_outlined,
                        _formatPickupTime(data['pickupTime']), w),
                    _infoChip(Icons.phone_outlined,
                        data['phone'] ?? 'N/A', w),
                    _infoChip(Icons.attach_money_rounded,
                        '${data['amount'] ?? '0'} FCFA', w,
                        color: const Color(0xFF2E7D32)),
                  ],
                ),

                SizedBox(height: w * 0.04),

                // ── Action button ──
                if (status == 'open' &&
                    data['createdBy'] != currentUser?.uid)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToPayment(context, docId, data),
                      icon: const Icon(Icons.handshake_outlined,
                          color: Colors.white, size: 18),
                      label: const Text(
                        'Unlock Pickup',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ),

                if (status == 'open' &&
                    data['createdBy'] == currentUser?.uid)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: const Center(
                      child: Text(
                        '⏳ Waiting for someone to accept...',
                        style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ),
                  ),

                if (status == 'taken')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFF4CAF50).withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text(
                        '🚛 ${data['acceptedByName'] ?? 'Someone'} is coming to pick this up!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPickupTime(dynamic value) {
    if (value == null) return 'Flexible';
    if (value is Timestamp) {
      final dt = value.toDate();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    }
    return value.toString();
  }

  Widget _infoChip(IconData icon, String label, double w,
      {Color color = const Color(0xFF4CAF50)}) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: w * 0.025, vertical: w * 0.015),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: w * 0.035, color: color),
          SizedBox(width: w * 0.015),
          Text(label,
              style: TextStyle(
                  fontSize: w * 0.03,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _navigateToPayment(
      BuildContext context, String docId, Map<String, dynamic> data) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          docId: docId,
          requestData: data,
        ),
      ),
    );
  }

  Future<void> _showAcceptDialog(
      BuildContext context, String docId, Map<String, dynamic> data) async {
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
            Text('📍 ${data['location'] ?? ''}',
                style: TextStyle(fontSize: w * 0.035, color: Colors.black87)),
            const SizedBox(height: 6),
            Text('⏰ Pickup time: ${_formatPickupTime(data['pickupTime'])}',
                style: TextStyle(fontSize: w * 0.033, color: Colors.black54)),
            const SizedBox(height: 6),
            Text('💰 Amount: ${data['amount'] ?? '0'} FCFA',
                style: TextStyle(
                    fontSize: w * 0.033,
                    color: const Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('📞 Contact: ${data['phone'] ?? 'N/A'}',
                style: TextStyle(fontSize: w * 0.033, color: Colors.black54)),
            const SizedBox(height: 12),
            const Text(
              'Do you want to accept this pickup request?',
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
              await _acceptRequest(context, docId, data);
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

  Future<void> _acceptRequest(
      BuildContext context, String docId, Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final username =
        userDoc.data()?['username'] ?? user.email ?? 'Someone';

    await FirebaseFirestore.instance
        .collection('waste_requests')
        .doc(docId)
        .update({
      'status': 'taken',
      'acceptedBy': user.uid,
      'acceptedByName': username,
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Accepted! Contact the poster: ${data['phone'] ?? 'N/A'}'),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────
// FORM — Post a new waste pickup request
// ─────────────────────────────────────────────
class _PostWasteRequest extends StatefulWidget {
  const _PostWasteRequest();

  @override
  State<_PostWasteRequest> createState() => _PostWasteRequestState();
}

class _PostWasteRequestState extends State<_PostWasteRequest> {
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeController = TextEditingController();

  String? _selectedWasteType;
  final List<String> _wasteTypes = [
    'Plastic Waste',
    'Organic Waste',
    'Electronic Waste (E-Waste)',
    'Paper & Cardboard',
    'Glass',
    'Metal',
    'Hazardous Waste',
    'Mixed Waste',
    'Other',
  ];

  final ImagePicker _picker = ImagePicker();
  File? _selectedFile;
  Uint8List? _webImage;
  String? _fileName;
  bool _isLoading = false;

  @override
  void dispose() {
    _locationController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? file =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file == null) return;

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      setState(() {
        _webImage = bytes;
        _selectedFile = null;
        _fileName = file.name;
      });
    } else {
      setState(() {
        _selectedFile = File(file.path);
        _webImage = null;
        _fileName = file.name;
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null && mounted) {
      _timeController.text = picked.format(context);
    }
  }

  Future<void> _submitRequest() async {
    if (_locationController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('⚠️ Please fill location, phone, amount and time.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not signed in');

      // Get username
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final username =
          userDoc.data()?['username'] ?? user.email ?? 'Anonymous';

      // Save to Firestore (no image upload)
      await FirebaseFirestore.instance.collection('waste_requests').add({
        'location': _locationController.text.trim(),
        'wasteType': _selectedWasteType, // Optional field
        'phone': _phoneController.text.trim(),
        'amount': _amountController.text.trim(),
        'pickupTime': _timeController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrls': [],
        'createdBy': user.uid,
        'postedBy': username,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Clear form
      _locationController.clear();
      _phoneController.clear();
      _amountController.clear();
      _descriptionController.clear();
      _timeController.clear();
      setState(() {
        _selectedFile = null;
        _webImage = null;
        _fileName = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Request posted! Others can now see it.'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _dec(String label, String hint, IconData icon,
      {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
      labelStyle: const TextStyle(
          color: Color(0xFF4CAF50), fontWeight: FontWeight.w500),
      prefixIcon: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF4CAF50), size: 18),
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: ThemeHelper.getCardColor(context),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: ThemeHelper.getBorderColor(context), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Color(0xFF4CAF50), width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: EdgeInsets.all(w * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Schedule Your Waste Pickup',
              style: TextStyle(
                  fontSize: w * 0.05,
                  fontWeight: FontWeight.bold,
                  color: ThemeHelper.getTextColor(context))),
          SizedBox(height: w * 0.01),
          Text(
            'Schedule a convenient time for waste collection. Set your preferred pickup time and other users will come collect your waste for the amount you offer.',
            style: TextStyle(fontSize: w * 0.033, color: Colors.grey[700], height: 1.4),
          ),
          SizedBox(height: w * 0.05),

          // ── Details card ──
          _card([
            const Text('Pickup Details',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4CAF50))),
            const SizedBox(height: 14),

            // Location
            TextField(
              controller: _locationController,
              decoration: _dec('Your Location',
                  'e.g. Bastos, Yaoundé — Street name', Icons.location_on),
            ),
            const SizedBox(height: 12),

            // Phone
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: _dec('Your Phone Number',
                  'e.g. 6XXXXXXXX', Icons.phone_outlined),
            ),
            const SizedBox(height: 12),

            // Type of Waste Dropdown (Optional)
            DropdownButtonFormField<String>(
              value: _selectedWasteType,
              isExpanded: true,
              dropdownColor: ThemeHelper.getCardColor(context),
              // No validator since this field is optional
              items: _wasteTypes
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedWasteType = value),
              decoration: _dec('Type of Waste (Optional)',
                  'Select waste type', Icons.delete_outline),
            ),
            const SizedBox(height: 12),

            // Pickup time
            GestureDetector(
              onTap: _pickTime,
              child: AbsorbPointer(
                child: TextField(
                  controller: _timeController,
                  decoration: _dec(
                    'Preferred Pickup Time',
                    'Select time',
                    Icons.access_time_outlined,
                    suffix: const Icon(Icons.arrow_drop_down,
                        color: Color(0xFF4CAF50)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Amount
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: _dec('Amount to Pay (FCFA)',
                  'e.g. 500', Icons.account_balance_wallet_outlined),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: _dec(
                'Description (optional)',
                'Describe the waste type, quantity, bags...',
                Icons.description_outlined,
              ).copyWith(alignLabelWithHint: true),
            ),
          ]),

          SizedBox(height: w * 0.04),

          // ── Photo card ──
          _card([
            const Text('Waste Photo',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4CAF50))),
            const SizedBox(height: 12),

            // Preview or upload tap
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: w * 0.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4FAF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF4CAF50).withOpacity(0.35),
                      width: 1.5),
                ),
                child: _buildImagePreview(w),
              ),
            ),
          ]),

          SizedBox(height: w * 0.06),

          // ── Submit ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitRequest,
              icon: _isLoading
                  ? const SizedBox.shrink()
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
              label: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Text('Schedule Pickup',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
          ),

          SizedBox(height: w * 0.05),
        ],
      ),
    );
  }

  Widget _buildImagePreview(double w) {
    if (kIsWeb && _webImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(_webImage!, fit: BoxFit.cover,
            width: double.infinity, height: w * 0.5),
      );
    } else if (_selectedFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(_selectedFile!, fit: BoxFit.cover,
            width: double.infinity, height: w * 0.5),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add_a_photo_outlined,
              color: Color(0xFF4CAF50), size: 32),
        ),
        const SizedBox(height: 10),
        Text('Tap to add a photo of the waste',
            style: TextStyle(
                fontSize: w * 0.035,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800])),
        const SizedBox(height: 4),
        Text('Clear photo helps collectors identify the waste',
            style:
                TextStyle(fontSize: w * 0.03, color: Colors.grey[600])),
      ],
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeHelper.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          ThemeHelper.getCardShadow(context),
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}
