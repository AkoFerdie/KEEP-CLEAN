import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

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
        title: const Text('Notifications',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SupabaseService.getPatrolScheduleStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No notifications yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text('Patrol schedules will appear here',
                      style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                ],
              ),
            );
          }

          // Filter out past patrols
          final now = DateTime.now();
          final upcomingPatrols = snapshot.data!.where((patrol) {
            try {
              // Parse date and time
              final dateStr = patrol['date'] as String?;
              final timeStr = patrol['time'] as String?;
              
              if (dateStr == null || timeStr == null) return false;
              
              // Parse date (format: "May 24, 2025" or "2025-05-24")
              DateTime? patrolDate;
              try {
                // Try ISO format first
                patrolDate = DateTime.parse(dateStr);
              } catch (_) {
                // Try parsing common formats
                final months = {
                  'January': 1, 'February': 2, 'March': 3, 'April': 4,
                  'May': 5, 'June': 6, 'July': 7, 'August': 8,
                  'September': 9, 'October': 10, 'November': 11, 'December': 12
                };
                
                final parts = dateStr.split(' ');
                if (parts.length >= 3) {
                  final month = months[parts[0]];
                  final day = int.tryParse(parts[1].replaceAll(',', ''));
                  final year = int.tryParse(parts[2]);
                  
                  if (month != null && day != null && year != null) {
                    patrolDate = DateTime(year, month, day);
                  }
                }
              }
              
              if (patrolDate == null) return false;
              
              // Parse time (format: "2:00 PM" or "14:00")
              int hour = 0;
              int minute = 0;
              
              if (timeStr.contains('PM') || timeStr.contains('AM')) {
                final isPM = timeStr.contains('PM');
                final cleanTime = timeStr.replaceAll(RegExp(r'[APM ]'), '');
                final timeParts = cleanTime.split(':');
                if (timeParts.length >= 2) {
                  hour = int.tryParse(timeParts[0]) ?? 0;
                  minute = int.tryParse(timeParts[1]) ?? 0;
                  if (isPM && hour != 12) hour += 12;
                  if (!isPM && hour == 12) hour = 0;
                }
              } else {
                final timeParts = timeStr.split(':');
                if (timeParts.length >= 2) {
                  hour = int.tryParse(timeParts[0]) ?? 0;
                  minute = int.tryParse(timeParts[1]) ?? 0;
                }
              }
              
              final patrolDateTime = DateTime(
                patrolDate.year,
                patrolDate.month,
                patrolDate.day,
                hour,
                minute,
              );
              
              // Return true only if patrol is in the future
              return patrolDateTime.isAfter(now);
            } catch (e) {
              return false; // Skip patrols with invalid date/time
            }
          }).toList();

          if (upcomingPatrols.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('All clear!',
                      style: TextStyle(fontSize: 16, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text('No upcoming patrols scheduled',
                      style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: upcomingPatrols.length,
            itemBuilder: (context, index) {
              final p = upcomingPatrols[index];
              return GestureDetector(
                onTap: () => _showDetail(context, p),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.green.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.local_shipping_outlined,
                              color: Color(0xFF4CAF50), size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('🚛 Patrol Scheduled',
                                  style: TextStyle(fontSize: 13, color: Color(0xFF4CAF50), fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                p['location'] ?? 'Unknown location',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 12, color: Colors.black45),
                                  const SizedBox(width: 4),
                                  Text(p['date'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black45)),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.access_time, size: 12, color: Colors.black45),
                                  const SizedBox(width: 4),
                                  Text(p['time'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black45)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.black26),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDetail(BuildContext context, Map<String, dynamic> p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),

            // Icon + title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.local_shipping, color: Color(0xFF4CAF50), size: 30),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Patrol Schedule', style: TextStyle(fontSize: 12, color: Color(0xFF4CAF50), fontWeight: FontWeight.w600)),
                      Text('Full Schedule Details', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Details
            _detailRow(Icons.location_on, 'Location', p['location'] ?? 'N/A', const Color(0xFF4CAF50)),
            const SizedBox(height: 14),
            _detailRow(Icons.calendar_today, 'Date', p['date'] ?? 'N/A', const Color(0xFF1E88E5)),
            const SizedBox(height: 14),
            _detailRow(Icons.access_time, 'Time', p['time'] ?? 'N/A', const Color(0xFFFF9800)),
            const SizedBox(height: 14),
            _detailRow(Icons.info_outline, 'Status', 'Scheduled', const Color(0xFF4CAF50)),

            const SizedBox(height: 28),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w500)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
          ],
        ),
      ],
    );
  }
}
