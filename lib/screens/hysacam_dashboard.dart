import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class HysacamDashboard extends StatefulWidget {
  const HysacamDashboard({super.key});

  @override
  State<HysacamDashboard> createState() => _HysacamDashboardState();
}

class _HysacamDashboardState extends State<HysacamDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _locations = [
    'Mile 17',
    'OIC',
    'Bokwaongo Market',
    'Before John Chi',
    'Molyko',
    'Great Soppo',
  ];

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
      backgroundColor: const Color(0xFFF4FAF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 4,
        shadowColor: Colors.green.withValues(alpha: 0.4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hysacam Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17)),
            Text('Waste Management Control', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF4CAF50),
              unselectedLabelColor: Colors.black45,
              indicatorColor: const Color(0xFF4CAF50),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: const [
                Tab(icon: Icon(Icons.report_problem_outlined, size: 20), text: 'Waste Reports'),
                Tab(icon: Icon(Icons.calendar_today_outlined, size: 20), text: 'Patrol Schedule'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _WasteReportsTab(locations: _locations),
                _PatrolScheduleTab(locations: _locations),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 1: WASTE REPORTS BY LOCATION
// ══════════════════════════════════════════════════════════════
class _WasteReportsTab extends StatelessWidget {
  final List<String> locations;
  const _WasteReportsTab({required this.locations});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: locations.length,
      itemBuilder: (context, index) {
        final location = locations[index];
        return _LocationReportCard(location: location);
      },
    );
  }
}

class _LocationReportCard extends StatelessWidget {
  final String location;
  const _LocationReportCard({required this.location});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.client
          .from('hysacam_reports')
          .stream(primaryKey: ['id'])
          .eq('location', location)
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        final docs = snapshot.hasData
            ? snapshot.data!.where((d) => d['location'] == location && d['status'] != 'done').toList()
            : [];
        final reportCount = docs.length;
        final countColor = reportCount < 4 ? Colors.green : Colors.red;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.green.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on, color: Color(0xFF4CAF50), size: 24),
              ),
              title: Text(
                location,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
              ),
              subtitle: Text(
                '$reportCount ${reportCount == 1 ? 'report' : 'reports'}',
                style: TextStyle(fontSize: 12, color: countColor),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: countColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$reportCount',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: countColor,
                  ),
                ),
              ),
              children: [
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50))),
                  )
                else if (!snapshot.hasData || docs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.green.shade300, size: 20),
                        const SizedBox(width: 8),
                        const Text('No reports for this location', style: TextStyle(fontSize: 13, color: Colors.black38)),
                      ],
                    ),
                  )
                else
                  ...docs.map((data) {
                    final docId = data['id']?.toString() ?? '';
                    return _ReportItem(data: data, docId: docId);
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReportItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  const _ReportItem({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'open';
    final statusColor = status == 'done' ? const Color(0xFF4CAF50) : status == 'taken' ? Colors.orange : Colors.red;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FFF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDEEDD)),
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
                      data['reported_by'] ?? 'Anonymous',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data['location'] ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.black45),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status == 'done' ? 'Done' : status == 'taken' ? 'In Progress' : 'Pending',
                  style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if ((data['description'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              data['description'],
              style: const TextStyle(fontSize: 12, color: Colors.black54),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(data['phone'] ?? 'N/A', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
          if (status != 'done') ...[
            const SizedBox(height: 10),
            // Waste image
            if ((data['image_urls'] as List?)?.isNotEmpty == true)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  data['image_urls'][0],
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _markAsDone(context, docId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('Mark as Done', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _markAsDone(BuildContext context, String docId) async {
    await SupabaseService.client
        .from('hysacam_reports')
        .update({'status': 'done'})
        .eq('id', docId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Marked as done!'), backgroundColor: Color(0xFF4CAF50)),
      );
    }
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 2: PATROL SCHEDULE
// ══════════════════════════════════════════════════════════════
class _PatrolScheduleTab extends StatefulWidget {
  final List<String> locations;
  const _PatrolScheduleTab({required this.locations});

  @override
  State<_PatrolScheduleTab> createState() => _PatrolScheduleTabState();
}

class _PatrolScheduleTabState extends State<_PatrolScheduleTab> {
  final _locationController = TextEditingController();
  final _timeController = TextEditingController();
  final _dateController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _locationController.dispose();
    _timeController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) _timeController.text = picked.format(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) _dateController.text = '${picked.year}-${picked.month}-${picked.day}';
  }

  Future<void> _schedulePatrol() async {
    if (_locationController.text.isEmpty || _timeController.text.isEmpty || _dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await SupabaseService.createPatrolSchedule(
        location: _locationController.text.trim(),
        time: _timeController.text.trim(),
        date: _dateController.text.trim(),
      );

      _locationController.clear();
      _timeController.clear();
      _dateController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Patrol scheduled!'), backgroundColor: Color(0xFF4CAF50)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Schedule form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.green.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Schedule New Patrol', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: null,
                  hint: const Text('Select Location'),
                  items: widget.locations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc))).toList(),
                  onChanged: (val) => _locationController.text = val ?? '',
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on, color: Color(0xFF4CAF50)),
                    filled: true,
                    fillColor: const Color(0xFFF9FFF9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _dateController,
                      decoration: InputDecoration(
                        hintText: 'Select Date',
                        prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF4CAF50)),
                        filled: true,
                        fillColor: const Color(0xFFF9FFF9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickTime,
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _timeController,
                      decoration: InputDecoration(
                        hintText: 'Select Time',
                        prefixIcon: const Icon(Icons.access_time, color: Color(0xFF4CAF50)),
                        filled: true,
                        fillColor: const Color(0xFFF9FFF9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _schedulePatrol,
                    icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.add_circle_outline, color: Colors.white),
                    label: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Schedule Patrol', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Scheduled patrols list
          const Text('Upcoming Patrols', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 12),

          StreamBuilder<List<Map<String, dynamic>>>(
            stream: SupabaseService.getPatrolScheduleStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDDEEDD)),
                  ),
                  child: const Center(child: Text('No patrols scheduled yet', style: TextStyle(color: Colors.black38))),
                );
              }

              final docs = snapshot.data!;

              return Column(
                children: docs.map((data) {
                  final docId = data['id'] as String;
                  return _PatrolCard(data: data, docId: docId);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PatrolCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  const _PatrolCard({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDEEDD)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_shipping, color: Color(0xFF4CAF50), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['location'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 12, color: Colors.black45),
                    const SizedBox(width: 4),
                    Text(data['date'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black45)),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time, size: 12, color: Colors.black45),
                    const SizedBox(width: 4),
                    Text(data['time'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black45)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF4CAF50), size: 20),
            onPressed: () => _showEditDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
            onPressed: () => _deletePatrol(context, docId),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final locations = ['Mile 17', 'OIC', 'Bokwaongo Market', 'Before John Chi', 'Molyko', 'Great Soppo'];
    String selectedLocation = data['location'] ?? locations.first;
    final timeController = TextEditingController(text: data['time'] ?? '');
    final dateController = TextEditingController(text: data['date'] ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Patrol', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedLocation,
                items: locations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc))).toList(),
                onChanged: (val) => setDialogState(() => selectedLocation = val ?? selectedLocation),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.location_on, color: Color(0xFF4CAF50)),
                  filled: true,
                  fillColor: const Color(0xFFF9FFF9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.tryParse(dateController.text) ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) dateController.text = '${picked.year}-${picked.month}-${picked.day}';
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: dateController,
                    decoration: InputDecoration(
                      hintText: 'Select Date',
                      prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF4CAF50)),
                      filled: true,
                      fillColor: const Color(0xFFF9FFF9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                  if (picked != null) timeController.text = picked.format(ctx);
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: timeController,
                    decoration: InputDecoration(
                      hintText: 'Select Time',
                      prefixIcon: const Icon(Icons.access_time, color: Color(0xFF4CAF50)),
                      filled: true,
                      fillColor: const Color(0xFFF9FFF9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.black45)),
            ),
            ElevatedButton(
              onPressed: () async {
                await SupabaseService.client.from('patrol_schedules').update({
                  'location': selectedLocation,
                  'date': dateController.text.trim(),
                  'time': timeController.text.trim(),
                }).eq('id', docId);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('✅ Patrol updated!'), backgroundColor: Color(0xFF4CAF50)),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePatrol(BuildContext context, String docId) async {
    await SupabaseService.deletePatrolSchedule(docId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Patrol deleted'), backgroundColor: Colors.redAccent),
      );
    }
  }
}
