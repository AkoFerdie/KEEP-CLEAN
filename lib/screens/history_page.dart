import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Pickups',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: 'Posted by Me'),
            Tab(text: 'Accepted by Me'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [_PostedPickups(), _AcceptedPickups()],
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _PostedPickups extends StatefulWidget {
  const _PostedPickups();

  @override
  State<_PostedPickups> createState() => _PostedPickupsState();
}

class _PostedPickupsState extends State<_PostedPickups> {
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    final uid = SupabaseService.currentUser?.id;
    if (uid != null) {
      SupabaseService.getUserWasteRequestsStream(uid).listen((data) {
        if (mounted) setState(() => _items = data);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const Center(
        child: Text('No pickups posted yet.', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (_, i) => _PickupManageCard(data: _items[i]),
    );
  }
}

// ─────────────────────────────────────────────
class _AcceptedPickups extends StatefulWidget {
  const _AcceptedPickups();

  @override
  State<_AcceptedPickups> createState() => _AcceptedPickupsState();
}

class _AcceptedPickupsState extends State<_AcceptedPickups> {
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    final uid = SupabaseService.currentUser?.id;
    if (uid != null) {
      SupabaseService.getAcceptedPickupsStream(uid).listen((data) {
        if (mounted) setState(() => _items = data);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const Center(
        child: Text('No accepted pickups yet.', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (_, i) => _PickupManageCard(data: _items[i], isCollector: true),
    );
  }
}

// ─────────────────────────────────────────────
class _PickupManageCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isCollector;

  const _PickupManageCard({required this.data, this.isCollector = false});

  @override
  State<_PickupManageCard> createState() => _PickupManageCardState();
}

class _PickupManageCardState extends State<_PickupManageCard> {
  bool _marking = false;
  bool _markedDone = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final status = _markedDone ? 'done' : (data['status'] ?? 'open').toString().trim().toLowerCase();
    final statusColor = status == 'done'
        ? const Color(0xFF4CAF50)
        : status == 'taken'
            ? Colors.orange
            : const Color(0xFF1E88E5);
    final statusLabel = status == 'done' ? 'DONE' : status == 'taken' ? 'TAKEN' : 'OPEN';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['location'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${data['amount'] ?? 0} FCFA',
                      style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration:
                    BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _confirmDelete(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                ),
              ),
            ],
          ),
          if ((data['description'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              data['description'],
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // Poster: taken → Mark as Done
          if (!widget.isCollector && status == 'taken') ...[
            const SizedBox(height: 10),
            Text(
              '🚛 Collector: ${data['accepted_by_name'] ?? 'Someone'}',
              style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _marking ? null : () => _markDone(context),
                icon: _marking
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                label: Text(
                  _marking ? 'Confirming...' : 'Mark as Done',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _marking ? Colors.grey : const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),
          ],
          // Poster: done → show confirmation + Rate Collector
          if (!widget.isCollector && status == 'done') ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
              ),
              child: const Center(
                child: Text('✅ Pickup completed!',
                    style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          ],
          if (!widget.isCollector && status == 'done' && (data['accepted_by'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showRatingDialog(context),
                icon: const Icon(Icons.star_outline, color: Color(0xFFFFC107), size: 18),
                label: const Text('Rate Collector',
                    style: TextStyle(color: Color(0xFFFFC107), fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFC107)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
          // Collector: show contact info
          if (widget.isCollector && status == 'taken') ...[
            const SizedBox(height: 6),
            Text('📞 Poster phone: ${data['phone'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            Text('📍 ${data['location'] ?? ''}',
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Pickup'),
        content: const Text('Remove this pickup from your list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SupabaseService.client
          .from('waste_requests')
          .delete()
          .eq('id', widget.data['id']);
    }
  }

  Future<void> _markDone(BuildContext context) async {
    final id = widget.data['id']?.toString() ?? '';
    if (id.isEmpty) return;
    setState(() => _marking = true);
    await SupabaseService.markWasteRequestDone(id);
    final collectorId = widget.data['accepted_by']?.toString() ?? '';
    if (collectorId.isNotEmpty) {
      await SupabaseService.sendNotification(
        userId: collectorId,
        title: '✅ Pickup Confirmed',
        body: 'The poster confirmed your pickup at ${widget.data['location']}.',
        type: 'pickup_done',
        referenceId: id,
      );
    }
    if (mounted) {
      setState(() {
        _marking = false;
        _markedDone = true;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Marked as done!'),
              backgroundColor: Color(0xFF4CAF50)),
        );
      }
    }
  }
  Future<void> _showRatingDialog(BuildContext context) async {
    int rating = 5;
    final reviewCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Rate Collector ⭐'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How was ${widget.data['accepted_by_name'] ?? 'the collector'}?'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => GestureDetector(
                    onTap: () => setS(() => rating = i + 1),
                    child: Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      color: const Color(0xFFFFC107),
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reviewCtrl,
                decoration: const InputDecoration(
                  hintText: 'Leave a comment (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
              onPressed: () async {
                Navigator.pop(ctx);
                await SupabaseService.rateCollector(
                  collectorId: widget.data['accepted_by'],
                  requestId: widget.data['id'],
                  rating: rating,
                  review: reviewCtrl.text,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('⭐ Rating submitted!'),
                        backgroundColor: Color(0xFF4CAF50)),
                  );
                }
              },
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
