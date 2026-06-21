import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'engage_page.dart';
import 'profile_page.dart';
import 'report_page.dart';
import 'report_waste_form.dart';
import 'guide_page.dart';
import 'ai_chat_page.dart';
import 'dashboard_screen.dart';
import 'hysacam_dashboard.dart';
import 'volunteer_dashboard.dart';
import '../utils/theme_helper.dart';
import '../main.dart';
import 'notifications_page.dart';
import 'map_page.dart';
import 'drop_points_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  dynamic user;
  int _currentIndex = 0;
  int _unseenReportCount = 0;
  int _lastSeenCount = 0;
  int _patrolCount = 0;
  int _seenPatrolCount = 0;

  final List<String> _pageTitles = [
    "Home",
    "Events",
    "Profile",
    "Post",
    "Guide",
  ];

  @override
  void initState() {
    super.initState();
    user = SupabaseService.currentUser;
    _loadLastSeenCount();
    NotificationService.init();
    int previousPatrolCount = -1;
    SupabaseService.getPatrolScheduleStream().listen((data) async {
      if (mounted) {
        // Calculate upcoming patrol count
        final upcomingCount = await SupabaseService.getUpcomingPatrolCount();
        
        if (previousPatrolCount >= 0 && upcomingCount > previousPatrolCount) {
          // Find the newest patrol that's in the future
          final now = DateTime.now();
          for (var patrol in data) {
            try {
              final dateStr = patrol['date'] as String?;
              final timeStr = patrol['time'] as String?;
              if (dateStr == null || timeStr == null) continue;
              
              // Basic future check (you can add full parsing here if needed)
              NotificationService.showPatrolNotification(
                location: patrol['location'] ?? 'Unknown',
                date: dateStr,
                time: timeStr,
              );
              break; // Show notification for first upcoming patrol
            } catch (_) {
              continue;
            }
          }
        }
        previousPatrolCount = upcomingCount;
        setState(() => _patrolCount = upcomingCount);
      }
    });
  }

  Future<void> _loadLastSeenCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastSeenCount = prefs.getInt('last_seen_report_count') ?? 0;
      _seenPatrolCount = prefs.getInt('seen_patrol_count') ?? 0;
    });
  }

  Future<void> _markReportsAsSeen(int total) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_seen_report_count', total);
    setState(() {
      _lastSeenCount = total;
      _unseenReportCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    String currentTitle = _pageTitles[_currentIndex];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        } else {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Exit App'),
              content: const Text('Are you sure you want to exit?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text(
                    'Exit',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: ThemeHelper.getBackgroundColor(context),

        // APP BAR
        appBar: AppBar(
          backgroundColor: const Color(0xFF4CAF50),
          elevation: 4,
          shadowColor: Colors.green.withValues(alpha: 0.4),
          automaticallyImplyLeading: false,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          title: Text(
            currentTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          actions: [
            if (_currentIndex == 4)
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white, size: 22),
                onPressed: () => _showSearchDialog(),
              ),
            IconButton(
              icon: Icon(
                ThemeHelper.isDarkMode(context)
                    ? Icons.light_mode
                    : Icons.dark_mode,
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
              child: GestureDetector(
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('seen_patrol_count', _patrolCount);
                  setState(() => _seenPatrolCount = _patrolCount);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsPage(),
                    ),
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    if (_patrolCount > _seenPatrolCount)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '${_patrolCount - _seenPatrolCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // BODY
        body: _buildCurrentPage(),

        // AI Chat Floating Button
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAIChatModal(),
          backgroundColor: const Color(0xFF4CAF50),
          elevation: 6,
          child: Container(
            padding: const EdgeInsets.all(12),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

        // BOTTOM NAV
        bottomNavigationBar: Builder(
          builder: (context) {
            // Static badge for now since we're using compatibility layer
            int badge = 0;
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: ThemeHelper.getCardColor(context),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      Icons.home_rounded,
                      Icons.home_outlined,
                      "Home",
                      0,
                    ),
                    _buildNavItem(
                      Icons.people_rounded,
                      Icons.people_outline,
                      "Events",
                      1,
                    ),
                    _buildNavItem(
                      Icons.person_rounded,
                      Icons.person_outline,
                      "Profile",
                      2,
                    ),
                    _buildNavItemWithBadge(
                      Icons.add_circle_rounded,
                      Icons.add_circle_outline_rounded,
                      "Post",
                      3,
                      badge,
                    ),
                    _buildNavItem(
                      Icons.menu_book_rounded,
                      Icons.menu_book_outlined,
                      "Guide",
                      4,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    int index,
  ) {
    final bool isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF4CAF50).withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[700],
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? const Color(0xFF4CAF50)
                      : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItemWithBadge(
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    int index,
    int badge,
  ) {
    final bool isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _currentIndex = index);
          if (badge > 0) {
            // Static implementation for compatibility
            _markReportsAsSeen(0);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF4CAF50).withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? activeIcon : inactiveIcon,
                    color: isSelected
                        ? const Color(0xFF4CAF50)
                        : Colors.grey[700],
                    size: 26,
                  ),
                  if (badge > 0)
                    Positioned(
                      top: -8,
                      right: -10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          badge > 99 ? '99+' : '$badge',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? const Color(0xFF4CAF50)
                      : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPatrolNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active, color: Color(0xFF4CAF50)),
                    SizedBox(width: 8),
                    Text(
                      'Patrol Schedules',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: SupabaseService.getPatrolScheduleStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'No patrol schedules yet.',
                          style: TextStyle(color: Colors.black45),
                        ),
                      );
                    }
                    final patrols = snapshot.data!;
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: patrols.length,
                      itemBuilder: (_, i) {
                        final p = patrols[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4FAF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDDEEDD)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF4CAF50,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.local_shipping,
                                  color: Color(0xFF4CAF50),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p['location'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${p['date'] ?? ''} at ${p['time'] ?? ''}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAIChatModal() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AIChatPage()),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Guide'),
        content: const TextField(
          decoration: InputDecoration(hintText: 'Enter search term...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  // PAGE SWITCHING
  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _HomeContent(
          onJoinEvent: () => setState(() => _currentIndex = 1),
          onSchedule: () => setState(() => _currentIndex = 3),
        );

      case 1:
        return const EngagePage();

      case 2:
        return ProfilePage(
          fullName: user?.userMetadata?['username'] ?? "Anonymous",
          email: user?.email ?? "No email",
        );

      case 3:
        return const ReportPage();

      case 4:
        return const GuidePage();

      default:
        return const Center(child: Text("Page not found"));
    }
  }

  // PROFILE PAGE
  Widget _buildProfile() {
    if (user != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 80, color: Colors.green),
            const SizedBox(height: 12),
            Text(user!.userMetadata?['username'] ?? "Anonymous"),
            Text(user!.email ?? "No email"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await SupabaseService.signOut();
                setState(() => user = null);
              },
              child: const Text("Logout"),
            ),
          ],
        ),
      );
    } else {
      return const Center(child: Text("No user signed in"));
    }
  }
}

// ------------------ HOME CONTENT ------------------
class _HomeContent extends StatefulWidget {
  final VoidCallback? onJoinEvent;
  final VoidCallback? onSchedule;
  const _HomeContent({this.onJoinEvent, this.onSchedule});

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  String? _cachedName;

  String _extractFirstNameFromFullName(String fullName) {
    final clean = fullName.trim();
    if (clean.isEmpty) return 'there';
    return clean.split(' ').first;
  }

  String _extractFirstNameFromEmail(String email) {
    final localPart = email.split('@').first;
    if (localPart.isEmpty) return 'there';
    final parts = localPart.split(RegExp(r'[._\-]'));
    final rawName = parts.firstWhere(
      (part) => part.isNotEmpty,
      orElse: () => localPart,
    );
    return rawName.isEmpty
        ? 'there'
        : rawName[0].toUpperCase() + rawName.substring(1);
  }

  final List<String> _ecoTips = const [
    "♻️ Rinse containers before recycling to avoid contamination.",
    "🌱 Composting food scraps reduces landfill waste by up to 30%.",
    "💧 Avoid single-use plastics — carry a reusable bottle.",
    "🔋 Drop old batteries at certified e-waste collection points.",
    "🛍️ One reusable bag saves ~700 plastic bags per year.",
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final user = SupabaseService.currentUser;
    final tipIndex = DateTime.now().day % _ecoTips.length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(w * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting ──
            FutureBuilder<Map<String, dynamic>?>(
              future: user != null
                  ? SupabaseService.client
                        .from('users')
                        .select()
                        .eq('id', user.id)
                        .maybeSingle()
                  : Future.value(null),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  final username = snapshot.data!['username'] as String?;
                  if (username != null && username.trim().isNotEmpty) {
                    _cachedName = _extractFirstNameFromFullName(username.trim());
                  }
                }

                if (_cachedName == null) {
                  final meta = user?.userMetadata;
                  final metadataName = (meta?['name'] ?? meta?['full_name'] ?? meta?['preferred_username'])?.toString();
                  if (metadataName != null && metadataName.trim().isNotEmpty) {
                    _cachedName = _extractFirstNameFromFullName(metadataName);
                  } else if (user?.email != null) {
                    _cachedName = _extractFirstNameFromEmail(user!.email!);
                  }
                }

                final name = _cachedName ?? 'there';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, $name 👋",
                      style: TextStyle(
                        fontSize: w * 0.055,
                        fontWeight: FontWeight.bold,
                        color: ThemeHelper.getTextColor(context),
                      ),
                    ),
                    SizedBox(height: h * 0.005),
                    Text(
                      "Let's keep our environment clean today.",
                      style: TextStyle(
                        fontSize: w * 0.033,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                );
              },
            ),

            SizedBox(height: h * 0.022),

            // ── Eco Tip of the Day ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(w * 0.04),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Text("🌿", style: TextStyle(fontSize: 28)),
                  SizedBox(width: w * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Eco Tip of the Day",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: w * 0.03,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: h * 0.005),
                        Text(
                          _ecoTips[tipIndex],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: w * 0.033,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: h * 0.025),

            // ── Quick Actions ──
            Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: w * 0.045,
                fontWeight: FontWeight.bold,
                color: ThemeHelper.getTextColor(context),
              ),
            ),
            SizedBox(height: h * 0.015),
            Row(
              children: [
                _buildQuickAction(
                  context,
                  Icons.report_problem_outlined,
                  "Report\nWaste",
                  const Color(0xFFE53935),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReportWasteForm(),
                      ),
                    );
                  },
                ),
                SizedBox(width: w * 0.03),
                _buildQuickAction(
                  context,
                  Icons.campaign_outlined,
                  "Join\nEvent",
                  const Color(0xFF1E88E5),
                  widget.onJoinEvent,
                ),
                SizedBox(width: w * 0.03),
                _buildQuickAction(
                  context,
                  Icons.map_outlined,
                  "View\nMap",
                  const Color(0xFF8E24AA),
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapPage())),
                ),
                SizedBox(width: w * 0.03),
                _buildQuickAction(
                  context,
                  Icons.location_on_outlined,
                  "Drop\nPoints",
                  const Color(0xFF00897B),
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DropPointsPage())),
                ),
              ],
            ),

            SizedBox(height: h * 0.025),

            // ── Schedule Pickup Card ──
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: ThemeHelper.getCardColor(context),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.asset(
                      "assets/Picture2.png",
                      height: h * 0.28,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(w * 0.03),
                    child: Column(
                      children: [
                        SizedBox(height: h * 0.008),
                        Text(
                          "Access Your Dashboard",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: w * 0.045,
                            color: ThemeHelper.getTextColor(context),
                          ),
                        ),
                        SizedBox(height: h * 0.005),
                        Text(
                          "View your activities, patrol schedules, and track progress.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: w * 0.035,
                            color: ThemeHelper.getSecondaryTextColor(context),
                          ),
                        ),
                        SizedBox(height: h * 0.015),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final user = SupabaseService.currentUser;
                              if (user != null) {
                                try {
                                  final userData = await SupabaseService.client
                                      .from('users')
                                      .select()
                                      .eq('id', user.id)
                                      .maybeSingle();

                                  if (userData != null) {
                                    final role = (userData['role'] ?? 'user').toString().trim();

                                    Widget targetDashboard;
                                    if (role == 'Government Company (Hysacam)' || role.toLowerCase().contains('hysacam') || role.toLowerCase().contains('cleanup') || role.toLowerCase() == 'admin') {
                                      targetDashboard = const HysacamDashboard();
                                    } else if (role == 'Organization / Volunteer' || role.toLowerCase().contains('volunteer') || role.toLowerCase().contains('organization')) {
                                      targetDashboard = const VolunteerDashboard();
                                    } else {
                                      targetDashboard = const DashboardScreen();
                                    }

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => targetDashboard,
                                      ),
                                    );
                                  } else {
                                    print('No user document found, defaulting to user dashboard');
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const DashboardScreen(),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  print('Error fetching user role: $e');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const DashboardScreen(),
                                    ),
                                  );
                                }
                              } else {
                                print('No authenticated user found');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(
                                vertical: h * 0.017,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "View Dashboard",
                              style: TextStyle(
                                fontSize: w * 0.04,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: h * 0.03),

            // ── Recent Campaigns ──
            Text(
              "Recent Events",
              style: TextStyle(
                fontSize: w * 0.045,
                fontWeight: FontWeight.bold,
                color: ThemeHelper.getTextColor(context),
              ),
            ),
            SizedBox(height: h * 0.015),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: SupabaseService.client
                  .from('campaigns')
                  .select()
                  .order('created_at', ascending: false)
                  .then((data) {
                    final now = DateTime.now();
                    final filtered = List<Map<String, dynamic>>.from(data).where((event) {
                      try {
                        final dateStr = event['date'] as String?;
                        final timeStr = event['time'] as String?;
                        if (dateStr == null || timeStr == null) return true;

                        DateTime? eventDate;
                        if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(dateStr)) {
                          eventDate = DateTime.tryParse(dateStr);
                        } else {
                          final months = {'january': 1, 'february': 2, 'march': 3, 'april': 4, 'may': 5, 'june': 6, 'july': 7, 'august': 8, 'september': 9, 'october': 10, 'november': 11, 'december': 12};
                          final regex = RegExp(r'(\w+)\s+(\d{1,2}),?\s+(\d{4})', caseSensitive: false);
                          final match = regex.firstMatch(dateStr);
                          if (match != null) {
                            final month = months[match.group(1)!.toLowerCase()];
                            final day = int.tryParse(match.group(2)!);
                            final year = int.tryParse(match.group(3)!);
                            if (month != null && day != null && year != null) {
                              eventDate = DateTime(year, month, day);
                            }
                          }
                        }
                        if (eventDate == null) return true;

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
                          final eventDateTime = DateTime(eventDate.year, eventDate.month, eventDate.day, hour, minute);
                          return eventDateTime.isAfter(now);
                        }
                        return eventDate.isAfter(DateTime(now.year, now.month, now.day));
                      } catch (_) {
                        return true;
                      }
                    }).take(3).toList();
                    return filtered;
                  }).catchError((_) => <Map<String, dynamic>>[]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(w * 0.04),
                    decoration: BoxDecoration(
                      color: ThemeHelper.getSurfaceColor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ThemeHelper.getBorderColor(context),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF4CAF50),
                        ),
                        SizedBox(width: w * 0.03),
                        Text(
                          "No upcoming events",
                          style: TextStyle(
                            fontSize: w * 0.035,
                            color: ThemeHelper.getSecondaryTextColor(context),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: snapshot.data!.map((data) {
                    return _CampaignCard(
                      location: data['location'] ?? 'Unknown location',
                      date: data['date'] ?? '',
                      description: data['description'] ?? '',
                      status: data['status'] ?? 'pending',
                    );
                  }).toList(),
                );
              },
            ),

            SizedBox(height: h * 0.03),

            // ── Explore Waste Guides ──
            Text(
              "Explore Waste Guides",
              style: TextStyle(
                fontSize: w * 0.045,
                fontWeight: FontWeight.bold,
                color: ThemeHelper.getTextColor(context),
              ),
            ),
            SizedBox(height: h * 0.015),
            SizedBox(
              height: h * 0.22,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _GuideCard(img: "assets/recy.jpg", title: "Recycling Guide"),
                  SizedBox(width: w * 0.03),
                  _GuideCard(
                    img: "assets/compositing.jpg",
                    title: "Composting",
                  ),
                  SizedBox(width: w * 0.03),
                  _GuideCard(img: "assets/hazard.jpg", title: "Hazard Waste"),
                  SizedBox(width: w * 0.03),
                  _GuideCard(img: "assets/Ewaste.jpg", title: "E-Waste"),
                  SizedBox(width: w * 0.03),
                  _GuideCard(img: "assets/plastic.jpg", title: "Plastic Waste"),
                ],
              ),
            ),

            SizedBox(height: h * 0.03),
          ],
        ),
      ),
    );
  }

  void _showMapModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
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
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.map_outlined, color: Color(0xFF8E24AA)),
                    SizedBox(width: 8),
                    Text('Locations Map', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: FutureBuilder<List<List<Map<String, dynamic>>>>(
                  future: Future.wait([
                    SupabaseService.client.from('waste_requests').select('location, status, amount').limit(20),
                    SupabaseService.client.from('patrol_schedules').select('location, date, time').limit(20),
                    SupabaseService.client.from('campaigns').select('location, date, status').limit(20),
                  ]).then((r) => [
                    List<Map<String, dynamic>>.from(r[0]),
                    List<Map<String, dynamic>>.from(r[1]),
                    List<Map<String, dynamic>>.from(r[2]),
                  ]),
                  builder: (ctx, snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
                    final wasteReqs = snap.data![0];
                    final patrols = snap.data![1];
                    final events = snap.data![2];

                    return SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Open in Google Maps button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                const url = 'https://www.google.com/maps/search/waste+collection+Yaounde+Cameroon';
                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                }
                              },
                              icon: const Icon(Icons.open_in_new, color: Colors.white, size: 18),
                              label: const Text('Open Google Maps', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8E24AA),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Waste Pickup Requests
                          if (wasteReqs.isNotEmpty) ...[
                            _mapSectionTitle('🗑️ Waste Pickup Locations', wasteReqs.length, const Color(0xFF1E88E5)),
                            ...wasteReqs.map((r) => _mapLocationTile(
                              icon: Icons.delete_outline,
                              color: r['status'] == 'open' ? const Color(0xFF1E88E5) : r['status'] == 'taken' ? Colors.orange : Colors.green,
                              title: r['location'] ?? 'Unknown location',
                              subtitle: '${r['status']?.toString().toUpperCase() ?? 'OPEN'} · ${r['amount'] ?? '0'} FCFA',
                              onTap: () => _openLocationOnMap(r['location'] ?? ''),
                            )),
                            const SizedBox(height: 16),
                          ],

                          // Patrol Schedules
                          if (patrols.isNotEmpty) ...[
                            _mapSectionTitle('🚛 Patrol Schedule Areas', patrols.length, const Color(0xFF4CAF50)),
                            ...patrols.map((p) => _mapLocationTile(
                              icon: Icons.local_shipping_outlined,
                              color: const Color(0xFF4CAF50),
                              title: p['location'] ?? 'Unknown location',
                              subtitle: '${p['date'] ?? ''} at ${p['time'] ?? ''}',
                              onTap: () => _openLocationOnMap(p['location'] ?? ''),
                            )),
                            const SizedBox(height: 16),
                          ],

                          // Events/Campaigns
                          if (events.isNotEmpty) ...[
                            _mapSectionTitle('📍 Event Locations', events.length, Colors.orange),
                            ...events.map((e) => _mapLocationTile(
                              icon: Icons.campaign_outlined,
                              color: Colors.orange,
                              title: e['location'] ?? 'Unknown location',
                              subtitle: e['date'] ?? '',
                              onTap: () => _openLocationOnMap(e['location'] ?? ''),
                            )),
                          ],

                          if (wasteReqs.isEmpty && patrols.isEmpty && events.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(30),
                                child: Text('No locations found yet.', style: TextStyle(color: Colors.grey)),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mapSectionTitle(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Text('$count', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _mapLocationTile({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.open_in_new, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Future<void> _openLocationOnMap(String location) async {
    final encoded = Uri.encodeComponent('$location Cameroon');
    final url = 'https://www.google.com/maps/search/?api=1&query=$encoded';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildQuickAction(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback? onTap,
  ) {    final w = MediaQuery.of(context).size.width;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: w * 0.035),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: w * 0.06),
              SizedBox(height: w * 0.015),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: w * 0.028,
                  fontWeight: FontWeight.w600,
                  color: color,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// CAMPAIGN CARD
class _CampaignCard extends StatelessWidget {
  final String location;
  final String date;
  final String description;
  final String status;

  const _CampaignCard({
    required this.location,
    required this.date,
    required this.description,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final statusColor = status == 'completed'
        ? const Color(0xFF4CAF50)
        : status == 'pending'
        ? const Color(0xFFFF9800)
        : const Color(0xFF1E88E5);

    return Container(
      margin: EdgeInsets.only(bottom: w * 0.03),
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: ThemeHelper.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(w * 0.03),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.campaign_outlined,
              color: const Color(0xFF4CAF50),
              size: w * 0.06,
            ),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location,
                  style: TextStyle(
                    fontSize: w * 0.038,
                    fontWeight: FontWeight.w600,
                    color: ThemeHelper.getTextColor(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: w * 0.01),
                Text(
                  description.isNotEmpty ? description : 'Cleanup campaign',
                  style: TextStyle(
                    fontSize: w * 0.032,
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: w * 0.01),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: w * 0.03,
                    color: const Color(0xFF4CAF50),
                  ),
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
              status[0].toUpperCase() + status.substring(1),
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
  }
}

// GUIDE CARD
class _GuideCard extends StatelessWidget {
  final String img;
  final String title;

  const _GuideCard({required this.img, required this.title});

  static const _guideData = {
    'Recycling Guide': {
      'emoji': '♻️',
      'description':
          'Recycling turns waste materials into new products, reducing the need for raw materials and saving energy.',
      'tips': [
        '🧼 Rinse containers before placing them in the recycling bin',
        '📦 Flatten cardboard boxes to save space',
        '🚫 Never recycle greasy pizza boxes or food-soiled paper',
        '🔢 Check the recycling number on plastics (1 & 2 are most accepted)',
        '🪟 Keep glass separate from other recyclables',
      ],
    },
    'Composting': {
      'emoji': '🌱',
      'description':
          'Composting converts organic waste into nutrient-rich fertilizer, reducing landfill waste by up to 30%.',
      'tips': [
        '🍎 Add fruit and vegetable scraps, coffee grounds, and eggshells',
        '🍂 Mix green (wet) and brown (dry) materials equally',
        '💧 Keep compost moist but not waterlogged',
        '🚫 Avoid meat, dairy, and oily foods in compost',
        '🔄 Turn the pile every 1–2 weeks to speed decomposition',
      ],
    },
    'Hazard Waste': {
      'emoji': '⚠️',
      'description':
          'Hazardous waste includes chemicals, paints, and batteries that require special disposal to protect health and environment.',
      'tips': [
        '🔋 Drop batteries at certified collection points only',
        '🎨 Never pour paint or chemicals down the drain',
        '💊 Return unused medicines to pharmacies',
        '🧴 Store hazardous items in original containers',
        '📍 Locate your nearest hazardous waste facility',
      ],
    },
    'E-Waste': {
      'emoji': '💻',
      'description':
          'Electronic waste contains toxic materials like lead and mercury. Proper disposal prevents soil and water contamination.',
      'tips': [
        '📱 Donate working devices instead of discarding them',
        '🏪 Return old electronics to manufacturer take-back programs',
        '🔒 Wipe personal data before disposing of any device',
        '🚫 Never throw electronics in regular trash bins',
        '🔧 Consider repairing before replacing devices',
      ],
    },
    'Plastic Waste': {
      'emoji': '🛍️',
      'description':
          'Plastic takes 400+ years to decompose. Reducing plastic use is one of the most impactful environmental actions.',
      'tips': [
        '🛒 Carry reusable bags — saves ~700 plastic bags per year',
        '🍶 Use a reusable water bottle instead of single-use plastic',
        '🥤 Say no to plastic straws and cutlery',
        '🧴 Choose products with minimal plastic packaging',
        '♻️ Only plastics labeled 1, 2, and 5 are widely recyclable',
      ],
    },
  };

  void _showGuideSheet(BuildContext context) {
    final data = _guideData[title];
    if (data == null) return;
    final tips = data['tips'] as List<String>;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero image
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        child: Stack(
                          children: [
                            Image.asset(
                              img,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Container(
                              height: 200,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.transparent, Colors.black54],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 16,
                              left: 16,
                              child: Text(
                                '${data['emoji']} $title',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Description
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4FAF4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFF4CAF50,
                                  ).withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                data['description'] as String,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              '💡 Key Tips',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...tips.map(
                              (tip) => Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withValues(alpha: 0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: const Color(0xFFDDEEDD),
                                  ),
                                ),
                                child: Text(
                                  tip,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () => _showGuideSheet(context),
      child: Container(
        width: w * 0.35,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(image: AssetImage(img), fit: BoxFit.cover),
        ),
        child: Container(
          alignment: Alignment.bottomCenter,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Colors.transparent, Colors.black54],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(w * 0.02),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: w * 0.032,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
