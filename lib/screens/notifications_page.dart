import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = SupabaseService.currentUser?.id ?? '';

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
        actions: [
          TextButton(
            onPressed: () async {
              if (uid.isEmpty) return;
              final items = await SupabaseService.client
                  .from('notifications')
                  .select('id')
                  .eq('user_id', uid)
                  .eq('is_read', false);
              for (final n in items) {
                await SupabaseService.markNotificationRead(n['id'].toString());
              }
            },
            child: const Text('Mark all read',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ],
      ),
      body: uid.isEmpty
          ? const Center(child: Text('Not signed in'))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: SupabaseService.getNotificationsStream(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
                }

                final notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('No notifications yet',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text('Pickup updates will appear here',
                            style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    final isRead = n['is_read'] == true;
                    final type = n['type']?.toString() ?? 'general';

                    final icon = type == 'pickup_taken'
                        ? Icons.local_shipping_outlined
                        : type == 'pickup_done'
                            ? Icons.check_circle_outline
                            : Icons.notifications_outlined;

                    final iconColor = type == 'pickup_taken'
                        ? Colors.orange
                        : type == 'pickup_done'
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF1E88E5);

                    return GestureDetector(
                      onTap: () async {
                        if (!isRead) {
                          await SupabaseService.markNotificationRead(
                              n['id'].toString());
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isRead ? Colors.white : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isRead
                                ? Colors.grey[200]!
                                : const Color(0xFF4CAF50).withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: iconColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(icon, color: iconColor, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n['title'] ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isRead
                                            ? FontWeight.w600
                                            : FontWeight.w800,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      n['body'] ?? '',
                                      style: TextStyle(
                                          fontSize: 13, color: Colors.grey[700]),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _timeAgo(n['created_at']),
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey[400]),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4CAF50),
                                    shape: BoxShape.circle,
                                  ),
                                ),
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

  String _timeAgo(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      final dt = DateTime.parse(createdAt.toString()).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}
