// File: lib/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'signup_page.dart';
import 'profile_page.dart';
import 'notifications_page.dart';
import 'post_page.dart';
import 'engage_page.dart';
import '../utils/theme_helper.dart';
import '../main.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  dynamic user;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    setState(() {
      user = SupabaseService.currentUser;
    });
  }

  void navigateToPostPage() async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PostPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeHelper.getSurfaceColor(context),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17),
            ),
            Text(
              user?.email ?? 'Overview',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              ThemeHelper.isDarkMode(context) ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: () {
              themeNotifier.value = ThemeHelper.isDarkMode(context)
                  ? ThemeMode.light
                  : ThemeMode.dark;
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
      body: _buildCurrentPage(),

      drawer: Drawer(
        backgroundColor: ThemeHelper.getBackgroundColor(context),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.userMetadata?['username'] ?? 'User'),
              accountEmail: Text(user?.email ?? 'No email'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  (user?.userMetadata?['username'] ?? user?.email ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
                ),
              ),
              decoration: const BoxDecoration(color: Color(0xFF4CAF50)),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFF4CAF50)),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 0);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.notifications,
                color: Color(0xFF4CAF50),
              ),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFF4CAF50)),
              title: const Text('Logout'),
              onTap: () async {
                await SupabaseService.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpPage()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _DashboardHome();
      case 1:
        return const EngagePage();
      case 2:
        if (user != null) {
          return ProfilePage(
            fullName: user.userMetadata?['username'] ?? "Anonymous",
            email: user.email ?? "No email",
          );
        } else {
          return const Center(child: Text("No user signed in"));
        }
      case 3:
        return const NotificationsPage();
      case 4:
        return const PostPage();
      default:
        return _DashboardHome();
    }
  }
}

// -----------------------------
// Dashboard Home Class
// -----------------------------
class _DashboardHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    return SingleChildScrollView(
      padding: EdgeInsets.all(w * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: w * 0.06,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E7D32),
            ),
          ),
          SizedBox(height: h * 0.025),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: SupabaseService.client
                .from('waste_reports')
                .stream(primaryKey: ['id']),
            builder: (context, snapshot) {
              // Calculate statistics
              int totalReports = 0;
              int completed = 0;
              int urgent = 0;
              int pending = 0;
              
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                totalReports = snapshot.data!.length;
                for (var report in snapshot.data!) {
                  final status = (report['status'] as String? ?? 'pending').toLowerCase();
                  if (status == 'completed' || status == 'resolved') {
                    completed++;
                  } else if (status == 'urgent' || status == 'high') {
                    urgent++;
                  } else if (status == 'pending' || status == 'submitted') {
                    pending++;
                  }
                }
              }
              
              // Calculate trends (mock percentages for now)
              final completedRate = totalReports > 0 ? ((completed / totalReports) * 100).toStringAsFixed(0) : '0';
              final urgentRate = totalReports > 0 ? ((urgent / totalReports) * 100).toStringAsFixed(0) : '0';
              
              return Column(
                children: [
                  SizedBox(
                    height: h * 0.17,
                    child: Row(
                      children: [
                        Expanded(child: _buildStatCard('Total Reports', '$totalReports', Colors.green, trend: '↑ $completedRate%')),
                        SizedBox(width: w * 0.04),
                        Expanded(child: _buildStatCard('Completed', '$completed', Colors.orange, trend: '↑ $completedRate%')),
                      ],
                    ),
                  ),
                  SizedBox(height: h * 0.012),
                  SizedBox(
                    height: h * 0.17,
                    child: Row(
                      children: [
                        Expanded(child: _buildStatCard('Urgent Cases', '$urgent', Colors.blue, trend: urgent > 0 ? '↑ $urgentRate%' : '↓ 0%')),
                        SizedBox(width: w * 0.04),
                        Expanded(child: _buildStatCard('Pending Cases', '$pending', Colors.purple, trend: pending > 0 ? '↑ ${(pending / (totalReports > 0 ? totalReports : 1) * 100).toStringAsFixed(0)}%' : '↓ 0%')),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: h * 0.035),
          Text(
            'Recent Activities',
            style: TextStyle(
              fontSize: w * 0.05,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E7D32),
            ),
          ),
          SizedBox(height: h * 0.018),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: SupabaseService.client
                .from('waste_reports')
                .stream(primaryKey: ['id'])
                .order('created_at', ascending: false)
                .limit(5),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                  ),
                );
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  padding: EdgeInsets.all(w * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8F5E8)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF4CAF50)),
                      SizedBox(width: w * 0.03),
                      const Text('No recent activities yet.'),
                    ],
                  ),
                );
              }
              
              return Column(
                children: snapshot.data!.map((report) {
                  final wasteType = report['waste_type'] as String? ?? 'Unknown';
                  final status = report['status'] as String? ?? 'Pending';
                  final createdAt = report['created_at'] as String?;
                  
                  // Calculate time ago
                  String timeAgo = 'Recently';
                  if (createdAt != null) {
                    try {
                      final created = DateTime.parse(createdAt);
                      final diff = DateTime.now().difference(created);
                      if (diff.inDays > 0) {
                        timeAgo = 'Reported: ${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
                      } else if (diff.inHours > 0) {
                        timeAgo = 'Reported: ${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
                      } else if (diff.inMinutes > 0) {
                        timeAgo = 'Reported: ${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
                      } else {
                        timeAgo = 'Reported: Just now';
                      }
                    } catch (_) {}
                  }
                  
                  // Map waste type to icon and title
                  IconData icon;
                  String title;
                  switch (wasteType.toLowerCase()) {
                    case 'organic':
                    case 'organic waste':
                      icon = Icons.eco_outlined;
                      title = 'Organic Waste Cleanup';
                      break;
                    case 'recyclable':
                    case 'recyclable waste':
                      icon = Icons.recycling_outlined;
                      title = 'Recyclable Waste Cleanup';
                      break;
                    case 'hazardous':
                    case 'hazardous waste':
                      icon = Icons.warning_outlined;
                      title = 'Hazardous Waste Cleanup';
                      break;
                    case 'electronic':
                    case 'e-waste':
                    case 'electronic waste':
                      icon = Icons.computer_outlined;
                      title = 'Electronic Waste Cleanup';
                      break;
                    case 'plastic':
                    case 'plastic waste':
                      icon = Icons.shopping_bag_outlined;
                      title = 'Plastic Waste Cleanup';
                      break;
                    default:
                      icon = Icons.delete_outline;
                      title = '$wasteType Waste Cleanup';
                  }
                  
                  // Map status to color
                  Color statusColor;
                  String statusText;
                  switch (status.toLowerCase()) {
                    case 'completed':
                    case 'resolved':
                      statusColor = const Color(0xFF4CAF50);
                      statusText = 'Completed';
                      break;
                    case 'in progress':
                    case 'in_progress':
                    case 'processing':
                      statusColor = Colors.blue;
                      statusText = 'In Progress';
                      break;
                    case 'urgent':
                    case 'high':
                      statusColor = Colors.red;
                      statusText = 'Urgent';
                      break;
                    default:
                      statusColor = const Color(0xFFFF9800);
                      statusText = 'Pending';
                  }
                  
                  return _buildActivityItem(
                    icon,
                    title,
                    timeAgo,
                    status: statusText,
                    statusColor: statusColor,
                  );
                }).toList(),
              );
            },
          ),
          SizedBox(height: h * 0.035),
          Text(
            'Hysacam Patrol Schedule',
            style: TextStyle(
              fontSize: w * 0.05,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E7D32),
            ),
          ),
          SizedBox(height: h * 0.018),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: SupabaseService.getPatrolScheduleStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                  ),
                );
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  padding: EdgeInsets.all(w * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8F5E8)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50)),
                      SizedBox(width: w * 0.03),
                      const Text('All clear! No upcoming patrols.'),
                    ],
                  ),
                );
              }
              
              // Filter upcoming patrols only
              final now = DateTime.now();
              final upcomingPatrols = snapshot.data!.where((patrol) {
                try {
                  final dateStr = patrol['date'] as String?;
                  final timeStr = patrol['time'] as String?;
                  if (dateStr == null || timeStr == null) return false;

                  DateTime? patrolDate;
                  if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(dateStr)) {
                    patrolDate = DateTime.tryParse(dateStr);
                  } else {
                    final months = {'january': 1, 'february': 2, 'march': 3, 'april': 4, 'may': 5, 'june': 6, 'july': 7, 'august': 8, 'september': 9, 'october': 10, 'november': 11, 'december': 12};
                    final regex = RegExp(r'(\w+)\s+(\d{1,2}),?\s+(\d{4})', caseSensitive: false);
                    final match = regex.firstMatch(dateStr);
                    if (match != null) {
                      final month = months[match.group(1)!.toLowerCase()];
                      final day = int.tryParse(match.group(2)!);
                      final year = int.tryParse(match.group(3)!);
                      if (month != null && day != null && year != null) {
                        patrolDate = DateTime(year, month, day);
                      }
                    }
                  }
                  if (patrolDate == null) return false;

                  int? hour, minute;
                  final ampmRegex = RegExp(r'(\d{1,2}):(\d{2})\s*(am|pm)', caseSensitive: false);
                  final ampmMatch = ampmRegex.firstMatch(timeStr);
                  if (ampmMatch != null) {
                    hour = int.tryParse(ampmMatch.group(1)!);
                    minute = int.tryParse(ampmMatch.group(2)!);
                    final period = ampmMatch.group(3)!.toLowerCase();
                    if (hour != null && minute != null) {
                      if (period == 'pm' && hour != 12) hour += 12;
                      if (period == 'am' && hour == 12) hour = 0;
                    }
                  } else {
                    final parts = timeStr.split(':');
                    if (parts.length >= 2) {
                      hour = int.tryParse(parts[0]);
                      minute = int.tryParse(parts[1]);
                    }
                  }

                  if (hour != null && minute != null) {
                    final patrolDateTime = DateTime(patrolDate.year, patrolDate.month, patrolDate.day, hour, minute);
                    return patrolDateTime.isAfter(now);
                  }
                  return patrolDate.isAfter(DateTime(now.year, now.month, now.day));
                } catch (_) {
                  return false;
                }
              }).toList();
              
              if (upcomingPatrols.isEmpty) {
                return Container(
                  padding: EdgeInsets.all(w * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8F5E8)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50)),
                      SizedBox(width: w * 0.03),
                      const Text('All clear! No upcoming patrols.'),
                    ],
                  ),
                );
              }
              
              return Column(
                children: upcomingPatrols.map((patrol) {
                  return _PatrolScheduleCard(
                    location: patrol['location'] ?? 'Unknown',
                    date: patrol['date'] ?? '',
                    time: patrol['time'] ?? '',
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  static Widget _buildStatCard(
    String title,
    String value,
    Color progressColor, {
    String trend = '↑ 12%',
  }) {
    final int numericValue = int.tryParse(value) ?? 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = MediaQuery.of(context).size.width;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8F5E8), width: 1),
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(26, 128, 128, 128),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(w * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: w * 0.032,
                          color: const Color(0xFF4CAF50),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: progressColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        trend,
                        style: TextStyle(fontSize: w * 0.025, color: progressColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: w * 0.02),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: w * 0.07,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                SizedBox(height: w * 0.02),
                SizedBox(
                  height: 6,
                  child: LinearProgressIndicator(
                    value: numericValue / 120,
                    backgroundColor: const Color(0xFFE8F5E8),
                    valueColor: AlwaysStoppedAnimation(progressColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildActivityItem(
    IconData icon,
    String title,
    String subtitle, {
    String status = 'Pending',
    Color statusColor = const Color(0xFFFF9800),
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = MediaQuery.of(context).size.width;
        return Container(
          margin: EdgeInsets.only(bottom: w * 0.03),
          padding: EdgeInsets.all(w * 0.04),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8F5E8), width: 1),
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(13, 0, 0, 0),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: w * 0.09,
                height: w * 0.09,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: w * 0.05, color: const Color(0xFF4CAF50)),
              ),
              SizedBox(width: w * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: w * 0.038,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                    SizedBox(height: w * 0.01),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: w * 0.032, color: Colors.grey[700]),
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
                  status,
                  style: TextStyle(
                    fontSize: w * 0.028,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PatrolScheduleCard extends StatelessWidget {
  final String location;
  final String date;
  final String time;

  const _PatrolScheduleCard({
    required this.location,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Container(
      margin: EdgeInsets.only(bottom: w * 0.03),
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: ThemeHelper.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3F2FD), width: 1),
        boxShadow: [
          ThemeHelper.getCardShadow(context),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: w * 0.09,
            height: w * 0.09,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.local_shipping, size: w * 0.05, color: const Color(0xFF1976D2)),
          ),
          SizedBox(width: w * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location,
                  style: TextStyle(
                    fontSize: w * 0.038,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1976D2),
                  ),
                ),
                SizedBox(height: w * 0.01),
                Text(
                  '$date at $time',
                  style: TextStyle(fontSize: w * 0.032, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
