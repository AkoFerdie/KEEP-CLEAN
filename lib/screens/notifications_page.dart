// File: lib/notifications_page.dart
import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String selectedTab = "All";

  final List<Map<String, String>> notifications = [
    {
      "type": "User",
      "title": "User: Besong",
      "subtitle": "Request for waste disposal",
      "avatar": "https://randomuser.me/api/portraits/men/1.jpg"
    },
    {
      "type": "User",
      "title": "User: Sarah",
      "subtitle": "Request for waste disposal",
      "avatar": "https://randomuser.me/api/portraits/women/2.jpg"
    },
    {
      "type": "Volunteer",
      "title": "Volunteer: Clean Beach",
      "subtitle": "Volunteer campaign Malingo Street",
      "avatar": "https://randomuser.me/api/portraits/women/3.jpg"
    },
    {
      "type": "Hysacam",
      "title": "Hysacam: Patrol",
      "subtitle": "Patrol area: Dirty South",
      "avatar": "https://cdn-icons-png.flaticon.com/512/847/847969.png"
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Filter notifications
    List<Map<String, String>> filteredNotifications = notifications.where((item) {
      if (selectedTab == "All") return true;
      if (selectedTab == "Users") return item["type"] == "User" || item["type"] == "Hysacam";
      if (selectedTab == "Volunteers") return item["type"] == "Volunteer";
      return true;
    }).toList();

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ...["All", "Users", "Volunteers"].map((tab) {
                  bool isSelected = selectedTab == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedTab = tab;
                        });
                      },
                      child: Column(
                        children: [
                          Text(
                            tab,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isSelected ? Colors.green : Colors.grey[700],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              height: 2,
                              width: 50,
                              color: Colors.green,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Notification list
          Expanded(
            child: ListView(
              children: [
                ...filteredNotifications.map((item) => ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(item["avatar"]!),
                        radius: 24,
                      ),
                      title: Text(
                        item["title"]!,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Text(
                        item["subtitle"]!,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )),

                // Only show schedules in "All"
                if (selectedTab == "All") ...[
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text("Volunteer Schedule",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  _buildScheduleCard(
                    assetImagePath: 'assets/event.jpg', // 👈 YOUR LOCAL ASSET
                    iconColor: Colors.blue,
                    title: "Saturday, July 20, 9 AM - 12 PM",
                    subtitle: "Cleanup Event: Riverbank Restoration",
                  ),
                  _buildScheduleCard(
                    assetImagePath: 'assets/event.jpg', // 👈 YOUR LOCAL ASSET
                    iconColor: Colors.blue,
                    title: "Sunday, July 21, 10 AM - 1 PM",
                    subtitle: "Cleanup Event: Park Beautification",
                  ),
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text("Hysacam Patrol Schedule",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  _buildScheduleCard(
                    icon: Icons.location_on,
                    iconColor: Colors.blue,
                    title: "Today's Patrol: 8 AM - 12 PM",
                    subtitle: "Patrol Area: OIC Market",
                  ),
                  _buildScheduleCard(
                    icon: Icons.location_on,
                    iconColor: Colors.blue,
                    title: "Today's Patrol: 1 PM - 5 PM",
                    subtitle: "Patrol Area: Mile 17",
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard({
    IconData? icon, // for Hysacam
    String? assetImagePath, // for custom local image (volunteer)
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.2),
            child: icon != null
                ? Icon(icon, color: iconColor)
                : assetImagePath != null
                    ? Image.asset(
                        assetImagePath,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(Icons.image, color: iconColor),
                      )
                    : Icon(Icons.image, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}