import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';
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
      ),
    );
  }
  }


// ─────────────────────────────────────────────
// FEED — Browse all waste pickup requests
// ─────────────────────────────────────────────
class _WasteRequestFeed extends StatefulWidget {
  const _WasteRequestFeed();

  @override
  State<_WasteRequestFeed> createState() => _WasteRequestFeedState();
}

class _WasteRequestFeedState extends State<_WasteRequestFeed> {
  List<Map<String, dynamic>> _docs = [];
  List<Map<String, dynamic>> _filteredDocs = [];
  bool _loading = true;
  final _searchController = TextEditingController();
  String _statusFilter = 'all';
  String _sortBy = 'recent';

  @override
  void initState() {
    super.initState();
    SupabaseService.getWasteRequestsStream().listen((data) {
      if (mounted) {
        setState(() {
          _docs = List<Map<String, dynamic>>.from(data);
          _loading = false;
          _applyFilters();
        });
      }
    });
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    var filtered = List<Map<String, dynamic>>.from(_docs);

    // Date filter - hide past pickups
    filtered = filtered.where((doc) {
      final pickupTime = doc['pickup_time'] ?? doc['pickupTime'];
      if (pickupTime == null) return true;
      try {
        DateTime? pickupDate;
        if (pickupTime is String) {
          if (pickupTime.contains('AM') || pickupTime.contains('PM')) {
            final now = DateTime.now();
            final parts = pickupTime.split(' ');
            if (parts.length >= 2) {
              final timePart = parts[0];
              final isPM = parts[1].toUpperCase() == 'PM';
              final timeComponents = timePart.split(':');
              if (timeComponents.length == 2) {
                var hour = int.parse(timeComponents[0]);
                final minute = int.parse(timeComponents[1]);
                if (isPM && hour != 12) hour += 12;
                if (!isPM && hour == 12) hour = 0;
                pickupDate = DateTime(now.year, now.month, now.day, hour, minute);
              }
            }
          } else {
            pickupDate = DateTime.tryParse(pickupTime);
          }
        }
        return pickupDate == null || pickupDate.isAfter(DateTime.now());
      } catch (_) {
        return true;
      }
    }).toList();

    // Status filter
    if (_statusFilter != 'all') {
      filtered = filtered.where((d) => (d['status'] ?? 'open') == _statusFilter).toList();
    }

    // Search filter
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((d) {
        final location = (d['location'] ?? '').toString().toLowerCase();
        final description = (d['description'] ?? '').toString().toLowerCase();
        final postedBy = (d['posted_by'] ?? '').toString().toLowerCase();
        return location.contains(query) || description.contains(query) || postedBy.contains(query);
      }).toList();
    }

    // Sort
    if (_sortBy == 'recent') {
      filtered.sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
    } else if (_sortBy == 'amount_high') {
      filtered.sort((a, b) => (int.tryParse(b['amount']?.toString() ?? '0') ?? 0).compareTo(int.tryParse(a['amount']?.toString() ?? '0') ?? 0));
    } else if (_sortBy == 'amount_low') {
      filtered.sort((a, b) => (int.tryParse(a['amount']?.toString() ?? '0') ?? 0).compareTo(int.tryParse(b['amount']?.toString() ?? '0') ?? 0));
    }

    setState(() => _filteredDocs = filtered);
  }

  void _onDelete(String docId) {
    setState(() {
      _docs.removeWhere((d) => d['id'] == docId);
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
    }

    return Column(
      children: [
        Container(
          color: ThemeHelper.getCardColor(context),
          padding: EdgeInsets.all(w * 0.04),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search location, poster...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF4CAF50)),
                  suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => _searchController.clear(),
                        ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PopupMenuButton<String>(
                      initialValue: _statusFilter,
                      onSelected: (v) => setState(() { _statusFilter = v; _applyFilters(); }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.filter_list, size: 18, color: Color(0xFF4CAF50)),
                                const SizedBox(width: 6),
                                Text(_statusFilter == 'all' ? 'All' : _statusFilter == 'open' ? 'Open' : _statusFilter == 'taken' ? 'Taken' : 'Done',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const Icon(Icons.arrow_drop_down, size: 20),
                          ],
                        ),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'all', child: Text('All Status')),
                        const PopupMenuItem(value: 'open', child: Text('🔵 Open')),
                        const PopupMenuItem(value: 'taken', child: Text('🟠 Taken')),
                        const PopupMenuItem(value: 'done', child: Text('🟢 Done')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PopupMenuButton<String>(
                      initialValue: _sortBy,
                      onSelected: (v) => setState(() { _sortBy = v; _applyFilters(); }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.sort, size: 18, color: Color(0xFF4CAF50)),
                                const SizedBox(width: 6),
                                Text(_sortBy == 'recent' ? 'Recent' : _sortBy == 'amount_high' ? 'High ₣' : 'Low ₣',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const Icon(Icons.arrow_drop_down, size: 20),
                          ],
                        ),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'recent', child: Text('Most Recent')),
                        const PopupMenuItem(value: 'amount_high', child: Text('Highest Amount')),
                        const PopupMenuItem(value: 'amount_low', child: Text('Lowest Amount')),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _filteredDocs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: w * 0.18, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('No pickups found', style: TextStyle(fontSize: w * 0.04, color: Colors.grey[600])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(w * 0.04),
                  itemCount: _filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data = _filteredDocs[index];
                    final docId = data['id']?.toString() ?? '';
                    if (docId.isEmpty) return const SizedBox.shrink();
                    return _WasteRequestCard(
                      data: data,
                      docId: docId,
                      onDeleted: () => _onDelete(docId),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// CARD — Single waste request post
// ─────────────────────────────────────────────
class _WasteRequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final VoidCallback onDeleted;

  const _WasteRequestCard({required this.data, required this.docId, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final List imageUrls = data['image_urls'] ?? [];
    final String status = data['status'] ?? 'open';
    final currentUser = SupabaseService.currentUser;

    final statusColor = status == 'taken'
        ? Colors.orange
        : status == 'done'
            ? const Color(0xFF4CAF50)
            : const Color(0xFF1E88E5);
    final statusLabel =
        status == 'taken' ? 'Taken' : status == 'done' ? 'Done' : 'Open';

    return Container(
      margin: EdgeInsets.only(bottom: w * 0.03),
      decoration: BoxDecoration(
        color: ThemeHelper.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Container(
            padding: EdgeInsets.all(w * 0.035),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                  backgroundImage: (data['profile_image_url'] ?? '').isNotEmpty
                      ? NetworkImage(data['profile_image_url'])
                      : null,
                  child: (data['profile_image_url'] ?? '').isEmpty
                      ? const Icon(Icons.person, color: Color(0xFF4CAF50), size: 20)
                      : null,
                ),
                SizedBox(width: w * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['posted_by'] ?? 'Anonymous',
                        style: TextStyle(
                            fontSize: w * 0.04,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[900]),
                      ),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 13, color: Colors.grey[600]),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              data['location'] ?? '',
                              style: TextStyle(fontSize: w * 0.032, color: Colors.grey[700]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5),
                  ),
                ),
                if (data['created_by'] == currentUser?.id) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _confirmDelete(context, docId),
                    child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                  ),
                ],
              ],
            ),
          ),

          // ── Details ──
          Padding(
            padding: EdgeInsets.all(w * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info chips row (moved to top)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _infoChipCompact(Icons.access_time, _formatPickupTime(data['pickupTime']), w),
                      ),
                      Container(width: 1, height: 30, color: Colors.grey[300]),
                      Expanded(
                        child: _infoChipCompact(Icons.account_balance_wallet, '${data['amount']} FCFA', w, color: const Color(0xFF2E7D32)),
                      ),
                    ],
                  ),
                ),
                if ((data['description'] ?? '').isNotEmpty) ...[
                  SizedBox(height: w * 0.03),
                  Text(
                    data['description'],
                    style: TextStyle(fontSize: w * 0.035, color: Colors.grey[700], height: 1.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                SizedBox(height: w * 0.03),

                // ── Waste Image ──
                if (imageUrls.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrls[0],
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Container(
                        height: w * 0.45,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40),
                      ),
                    ),
                  ),

                if (imageUrls.isNotEmpty) SizedBox(height: w * 0.03),

                // ── Action button ──
                if (status == 'open' &&
                    data['created_by'] != currentUser?.id)
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
                    data['created_by'] == currentUser?.id)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3)),
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

                if (status == 'taken' && data['created_by'] != currentUser?.id)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: const Center(
                      child: Text(
                        '🔴 This pickup has already been taken',
                        style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ),
                  ),

                if (status == 'taken' && data['created_by'] == currentUser?.id)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(
                        '🚛 ${data['accepted_by_name'] ?? 'Someone'} is on the way to collect!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ),
                  ),

                if (status == 'taken' && data['accepted_by'] == currentUser?.id)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        const Text('✅ You unlocked this pickup',
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('📞 Contact poster: ${data['phone'] ?? 'N/A'}',
                            style: const TextStyle(color: Colors.blue, fontSize: 12)),
                        Text('📍 Location: ${data['location'] ?? 'N/A'}',
                            style: const TextStyle(color: Colors.blue, fontSize: 12)),
                      ],
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
    if (value is String) {
      try {
        final dt = DateTime.parse(value);
        return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
      } catch (_) {
        return value;
      }
    }
    return value.toString();
  }

  Widget _infoChipCompact(IconData icon, String label, double w, {Color color = const Color(0xFF4CAF50)}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: w * 0.03, color: color, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
    final List imageUrls = data['image_urls'] ?? [];
    int current = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Images carousel
                        if (imageUrls.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              height: 220,
                              child: PageView.builder(
                                itemCount: imageUrls.length,
                                onPageChanged: (i) => setModalState(() => current = i),
                                itemBuilder: (_, index) => InteractiveViewer(
                                  child: Image.network(
                                    imageUrls[index],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, _, _) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                    ),
                                    loadingBuilder: (_, child, progress) => progress == null
                                        ? child
                                        : Container(
                                            color: Colors.grey[100],
                                            child: const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50))),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (imageUrls.length > 1) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                imageUrls.length,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: current == i ? 16 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: current == i ? const Color(0xFF4CAF50) : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                        ],

                        // Poster info
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                              backgroundImage: (data['profile_image_url'] ?? '').isNotEmpty
                                  ? NetworkImage(data['profile_image_url']) : null,
                              child: (data['profile_image_url'] ?? '').isEmpty
                                  ? const Icon(Icons.person, size: 22, color: Color(0xFF4CAF50)) : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['posted_by'] ?? 'Anonymous',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(data['location'] ?? '',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),

                        if ((data['description'] ?? '').isNotEmpty) ...[
                          const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 6),
                          Text(data['description'], style: TextStyle(color: Colors.grey[800], fontSize: 14, height: 1.5)),
                          const SizedBox(height: 16),
                        ],

                        const Text('Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 10),
                        _detailRow(Icons.access_time_outlined, 'Pickup Time', _formatPickupTime(data['pickup_time'])),
                        _detailRow(Icons.account_balance_wallet_outlined, 'Amount', '${data['amount'] ?? '0'} FCFA'),
                        _detailRow(Icons.phone_outlined, 'Contact', data['phone'] ?? 'N/A'),
                        if (data['waste_type'] != null)
                          _detailRow(Icons.delete_outline, 'Waste Type', data['waste_type']),

                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(color: Colors.redAccent),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await _acceptRequest(context, docId, data);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Accept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      onDeleted(); // remove instantly from UI
      await SupabaseService.client
          .from('waste_requests')
          .delete()
          .eq('id', docId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted.')),
        );
      }
    }
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF4CAF50)),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Expanded(child: Text(value, style: TextStyle(color: Colors.grey[700], fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _acceptRequest(
      BuildContext context, String docId, Map<String, dynamic> data) async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    final userProfile = await SupabaseService.getUserProfile(user.id);
    final username = userProfile?['username'] ?? user.email ?? 'Someone';

    await SupabaseService.acceptWasteRequest(docId, username);

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
      });
    } else {
      setState(() {
        _selectedFile = File(file.path);
        _webImage = null;
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

    if (_selectedFile == null && _webImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please add a photo of the waste.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload image
      List<String> imageUrls = [];
      try {
        String url;
        if (kIsWeb && _webImage != null) {
          url = await SupabaseService.uploadImage(
            imageData: _webImage!,
            bucket: 'waste-images',
            folder: 'reports',
          );
        } else {
          url = await SupabaseService.uploadImage(
            imageData: _selectedFile!,
            bucket: 'waste-images',
            folder: 'reports',
          );
        }
        imageUrls = [url];
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Image upload failed: $e')),
        );
        setState(() => _isLoading = false);
        return;
      }

      await SupabaseService.createWasteRequest(
        location: _locationController.text.trim(),
        phone: _phoneController.text.trim(),
        amount: _amountController.text.trim(),
        pickupTime: _timeController.text.trim(),
        description: _descriptionController.text.trim(),
        wasteType: _selectedWasteType,
        imageUrls: imageUrls,
      );

      // Clear form
      _locationController.clear();
      _phoneController.clear();
      _amountController.clear();
      _descriptionController.clear();
      _timeController.clear();
      setState(() {
        _selectedFile = null;
        _webImage = null;
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
          color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
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
              initialValue: _selectedWasteType,
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
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.35),
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
            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
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
