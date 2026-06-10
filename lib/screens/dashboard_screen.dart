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
          SizedBox(
            height: h * 0.17,
            child: Row(
              children: [
                Expanded(child: _buildStatCard('Total Reports', '120', Colors.green, trend: '↑ 8%')),
                SizedBox(width: w * 0.04),
                Expanded(child: _buildStatCard('Completed', '95', Colors.orange, trend: '↑ 5%')),
              ],
            ),
          ),
          SizedBox(height: h * 0.012),
          SizedBox(
            height: h * 0.17,
            child: Row(
              children: [
                Expanded(child: _buildStatCard('Urgent Cases', '15', Colors.blue, trend: '↓ 3%')),
                SizedBox(width: w * 0.04),
                Expanded(child: _buildStatCard('Pending Cases', '10', Colors.purple, trend: '↓ 2%')),
              ],
            ),
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
          _buildActivityItem(
            Icons.eco_outlined,
            'Organic Waste Cleanup',
            'Reported: 2 days ago',
            status: 'In Progress',
            statusColor: Colors.blue,
          ),
          _buildActivityItem(
            Icons.recycling_outlined,
            'Recyclable Waste Cleanup',
            'Reported: 3 days ago',
            status: 'Completed',
            statusColor: Color(0xFF4CAF50),
          ),
          _buildActivityItem(
            Icons.warning_outlined,
            'Hazardous Waste Cleanup',
            'Reported: 5 days ago',
            status: 'Urgent',
            statusColor: Colors.red,
          ),
          _buildActivityItem(
            Icons.computer_outlined,
            'Electronic Waste Cleanup',
            'Reported: 7 days ago',
            status: 'Pending',
            statusColor: Color(0xFFFF9800),
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
          StreamBuilder(
            stream: Stream.empty(), // Placeholder since we're using compatibility layer
            builder: (context, snapshot) {
              // Static data for now
              return Column(
                children: [
                  _PatrolScheduleCard(
                    location: 'Mile 17',
                    date: '2024-01-15',
                    time: '08:00 AM',
                  ),
                  _PatrolScheduleCard(
                    location: 'Molyko',
                    date: '2024-01-16', 
                    time: '10:00 AM',
                  ),
                ],
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
