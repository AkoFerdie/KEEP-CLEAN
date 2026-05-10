import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? user;
  int _currentIndex = 0;
  int _unseenReportCount = 0;
  int _lastSeenCount = 0;

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
    user = FirebaseAuth.instance.currentUser;
    _loadLastSeenCount();
  }

  Future<void> _loadLastSeenCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _lastSeenCount = prefs.getInt('last_seen_report_count') ?? 0);
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

    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(context),

      // APP BAR
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 4,
        shadowColor: Colors.green.withOpacity(0.4),
        automaticallyImplyLeading: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
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
              backgroundColor: Colors.white.withOpacity(0.2),
              child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
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
      bottomNavigationBar: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('waste_requests')
            .where('status', isEqualTo: 'open')
            .snapshots(),
        builder: (context, snapshot) {
          int badge = 0;
          if (snapshot.hasData) {
            final total = snapshot.data!.docs.length;
            badge = (total - _lastSeenCount).clamp(0, 999);
            if (_unseenReportCount != badge) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() => _unseenReportCount = badge);
              });
            }
          }
          return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: ThemeHelper.getCardColor(context),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.home_rounded, Icons.home_outlined, "Home", 0),
              _buildNavItem(Icons.people_rounded, Icons.people_outline, "Events", 1),
              _buildNavItem(Icons.person_rounded, Icons.person_outline, "Profile", 2),
              _buildNavItemWithBadge(Icons.add_circle_rounded, Icons.add_circle_outline_rounded, "Post", 3, badge),
              _buildNavItem(Icons.menu_book_rounded, Icons.menu_book_outlined, "Guide", 4),
            ],
          ),
        ),
      );
        },
      ),
    );
  }

  Widget _buildNavItem(IconData activeIcon, IconData inactiveIcon, String label, int index) {
    final bool isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4CAF50).withOpacity(0.12) : Colors.transparent,
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
                  color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[700],
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

  Widget _buildNavItemWithBadge(IconData activeIcon, IconData inactiveIcon, String label, int index, int badge) {
    final bool isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _currentIndex = index);
          if (badge > 0) {
            FirebaseFirestore.instance
                .collection('waste_requests')
                .where('status', isEqualTo: 'open')
                .get()
                .then((snap) => _markReportsAsSeen(snap.docs.length));
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4CAF50).withOpacity(0.12) : Colors.transparent,
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
                    color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[700],
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
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          badge > 99 ? '99+' : '$badge',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
                  color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[700],
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

  void _showAIChatModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'EcoBot AI Assistant',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // AI Chat Content
              const Expanded(child: AIChatPage()),
            ],
          ),
        ),
      ),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Search')),
        ],
      ),
    );
  }

  // PAGE SWITCHING
 Widget _buildCurrentPage() {
  switch (_currentIndex) {
    case 0:
      return const _HomeContent();

    case 1:
      return const EngagePage();

    case 2:
      return ProfilePage(
        fullName: user?.displayName ?? "Anonymous",
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
            Text(user!.displayName ?? "Anonymous"),
            Text(user!.email ?? "No email"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                setState(() => user = null);
              },
              child: const Text("Logout"),
            )
          ],
        ),
      );
    } else {
      return const Center(child: Text("No user signed in"));
    }
  }
}

// ------------------ HOME CONTENT ------------------
class _HomeContent extends StatelessWidget {
  const _HomeContent();

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
    final user = FirebaseAuth.instance.currentUser;
    final tipIndex = DateTime.now().day % _ecoTips.length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(w * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Greeting ──
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .get(),
              builder: (context, snapshot) {
                String name = 'there';
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  name = data?['username'] ?? 'there';
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, $name 👋",
                      style: TextStyle(fontSize: w * 0.055, fontWeight: FontWeight.bold, color: ThemeHelper.getTextColor(context)),
                    ),
                    SizedBox(height: h * 0.005),
                    Text(
                      "Let's keep our environment clean today.",
                      style: TextStyle(fontSize: w * 0.033, color: Colors.grey[700]),
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
                          style: TextStyle(color: Colors.white70, fontSize: w * 0.03, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: h * 0.005),
                        Text(
                          _ecoTips[tipIndex],
                          style: TextStyle(color: Colors.white, fontSize: w * 0.033, fontWeight: FontWeight.w600, height: 1.4),
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
              style: TextStyle(fontSize: w * 0.045, fontWeight: FontWeight.bold, color: ThemeHelper.getTextColor(context)),
            ),
            SizedBox(height: h * 0.015),
            Row(
              children: [
                _buildQuickAction(context, Icons.report_problem_outlined, "Report\nWaste", const Color(0xFFE53935), () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportWasteForm()));
                }),
                SizedBox(width: w * 0.03),
                _buildQuickAction(context, Icons.campaign_outlined, "Join\nCampaign", const Color(0xFF1E88E5), null),
                SizedBox(width: w * 0.03),
                _buildQuickAction(context, Icons.map_outlined, "View\nMap", const Color(0xFF8E24AA), null),
                SizedBox(width: w * 0.03),
                _buildQuickAction(context, Icons.calendar_today_outlined, "Schedule", const Color(0xFF4CAF50), null),
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: w * 0.045, color: ThemeHelper.getTextColor(context)),
                        ),
                        SizedBox(height: h * 0.005),
                        Text(
                          "View your activities, patrol schedules, and track progress.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: w * 0.035, color: ThemeHelper.getSecondaryTextColor(context)),
                        ),
                        SizedBox(height: h * 0.015),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                try {
                                  final userDoc = await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .get();
                                  
                                  if (userDoc.exists) {
                                    final userData = userDoc.data() as Map<String, dynamic>;
                                    final role = userData['role'] ?? 'user';
                                    
                                    // Debug: Print the role to console
                                    print('User role from database: $role');
                                    
                                    Widget targetDashboard;
                                    switch (role.toLowerCase().trim()) {
                                      case 'hysacam':
                                      case 'hysacam worker':
                                      case 'cleanup organization':
                                      case 'government company (hysacam)':
                                      case 'admin':
                                        print('Navigating to Hysacam Dashboard');
                                        targetDashboard = const HysacamDashboard();
                                        break;
                                      case 'volunteer':
                                      case 'volunteers':
                                      case 'organization / volunteer':
                                        print('Navigating to Volunteer Dashboard');
                                        targetDashboard = const VolunteerDashboard();
                                        break;
                                      case 'user':
                                      case 'users':
                                      default:
                                        print('Navigating to User Dashboard (default)');
                                        targetDashboard = const DashboardScreen();
                                        break;
                                    }
                                    
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => targetDashboard),
                                    );
                                  } else {
                                    print('No user document found, defaulting to user dashboard');
                                    // Default to user dashboard if no user data found
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const DashboardScreen()),
                                    );
                                  }
                                } catch (e) {
                                  print('Error fetching user role: $e');
                                  // Handle error - default to user dashboard
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                                  );
                                }
                              } else {
                                print('No authenticated user found');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(vertical: h * 0.017),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "View Dashboard",
                              style: TextStyle(fontSize: w * 0.04, fontWeight: FontWeight.w600),
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),

            SizedBox(height: h * 0.03),

            // ── Recent Campaigns ──
            Text(
              "Recent Campaigns",
              style: TextStyle(fontSize: w * 0.045, fontWeight: FontWeight.bold, color: ThemeHelper.getTextColor(context)),
            ),
            SizedBox(height: h * 0.015),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('campaigns')
                  .orderBy('createdAt', descending: true)
                  .limit(3)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(w * 0.04),
                    decoration: BoxDecoration(
                      color: ThemeHelper.getSurfaceColor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ThemeHelper.getBorderColor(context)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF4CAF50)),
                        SizedBox(width: w * 0.03),
                        Text("No campaigns yet. Be the first!",
                            style: TextStyle(fontSize: w * 0.035, color: ThemeHelper.getSecondaryTextColor(context))),
                      ],
                    ),
                  );
                }
                return Column( 
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
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
              style: TextStyle(fontSize: w * 0.045, fontWeight: FontWeight.bold, color: ThemeHelper.getTextColor(context)),
            ),
            SizedBox(height: h * 0.015),
            SizedBox(
              height: h * 0.22,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _GuideCard(img: "assets/recy.jpg", title: "Recycling Guide"),
                  SizedBox(width: w * 0.03),
                  _GuideCard(img: "assets/compositing.jpg", title: "Composting"),
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

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, Color color, VoidCallback? onTap) {
    final w = MediaQuery.of(context).size.width;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: w * 0.035),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: w * 0.06),
              SizedBox(height: w * 0.015),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: w * 0.028, fontWeight: FontWeight.w600, color: color, height: 1.2),
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
          BoxShadow(color: Colors.green.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(w * 0.03),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.campaign_outlined, color: const Color(0xFF4CAF50), size: w * 0.06),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location,
                  style: TextStyle(fontSize: w * 0.038, fontWeight: FontWeight.w600, color: ThemeHelper.getTextColor(context)),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: w * 0.01),
                Text(
                  description.isNotEmpty ? description : 'Cleanup campaign',
                  style: TextStyle(fontSize: w * 0.032, color: Colors.grey[700]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: w * 0.01),
                Text(
                  date,
                  style: TextStyle(fontSize: w * 0.03, color: const Color(0xFF4CAF50)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status[0].toUpperCase() + status.substring(1),
              style: TextStyle(fontSize: w * 0.028, color: statusColor, fontWeight: FontWeight.w600),
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

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Container(
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
    );
  }
}