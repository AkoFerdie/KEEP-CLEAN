import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/supabase_service.dart';

class VolunteerDashboard extends StatefulWidget {
  const VolunteerDashboard({super.key});

  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String get userId => SupabaseService.currentUser?.id ?? '';

  // Add these variables for edit mode
  bool _isEditMode = false;
  String? _editingEventId;

  // Event creation form controllers
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedFiles = [];
  final List<Uint8List> _webImages = [];
  final List<String> _fileNames = [];
  bool _isLoading = false;
  bool _showCreateForm = false;

  @override
  void initState() {
    super.initState();
    // Force rebuild with 3 tabs only
    _tabController = TabController(length: 3, vsync: this);
    _showCreateForm = false; // Initialize the form state
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Volunteer Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            Text(
              'Cleanup Organizations Hub',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Events'),
            Tab(text: 'Volunteers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildCampaignsTab(),
          _buildVolunteersTab(),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 16),
        child: FloatingActionButton.extended(
          onPressed: () {
            if (mounted) {
              setState(() {
                _showCreateForm = !_showCreateForm;
                if (!_showCreateForm) {
                  _clearForm();
                }
              });
              if (_showCreateForm) {
                _tabController.animateTo(1); // Switch to Events tab
              }
            }
          },
          backgroundColor: const Color(0xFF4CAF50),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('New Event', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickStats(),
          const SizedBox(height: 20),
          _buildUpcomingEvents(),
          const SizedBox(height: 20),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.getUserCampaignsStream(userId),
      builder: (context, snapshot) {
        int activeEvents = 0, totalLikes = 0, totalComments = 0, totalEvents = 0;

        if (snapshot.hasData) {
          final now = DateTime.now();
          
          for (var data in snapshot.data!) {
            // Check if event is in the future
            bool isFutureEvent = false;
            try {
              final dateStr = data['date'] as String?;
              final timeStr = data['time'] as String?;
              
              if (dateStr != null && timeStr != null) {
                // Parse date
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
                
                if (eventDate != null) {
                  // Parse time
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
                    isFutureEvent = eventDateTime.isAfter(now);
                  } else {
                    isFutureEvent = eventDate.isAfter(DateTime(now.year, now.month, now.day));
                  }
                }
              }
            } catch (_) {}
            
            // Only count if it's a future event
            if (isFutureEvent) {
              activeEvents++;
              totalEvents++;
              totalLikes += (data['likes'] as int?) ?? 0;
              totalComments += ((data['comments'] as List?)?.length ?? 0);
            }
          }
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildStatCard(
              'Active Events',
              '$activeEvents',
              Icons.event,
              Colors.blue,
            ),
            _buildStatCard(
              'Total Likes',
              '$totalLikes',
              Icons.favorite,
              Colors.red,
            ),
            _buildStatCard(
              'Total Comments',
              '$totalComments',
              Icons.comment,
              Colors.orange,
            ),
            _buildStatCard(
              'Events Posted',
              '$totalEvents',
              Icons.post_add,
              Colors.purple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.trending_up, color: color, size: 16),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Events',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: SupabaseService.getUserCampaignsStream(userId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();

            // Filter only upcoming events (future date/time)
            final now = DateTime.now();
            final events = snapshot.data!.where((e) {
              try {
                final dateStr = e['date'] as String?;
                final timeStr = e['time'] as String?;
                if (dateStr == null || timeStr == null) return false;

                // Parse date
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
                if (eventDate == null) return false;

                // Parse time
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
                return false;
              }
            }).take(3).toList();

            if (events.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'No upcoming events',
                    style: TextStyle(fontSize: 14, color: Colors.black45),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              itemBuilder: (context, index) {
                return _buildOverviewEventCard(events[index]);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildOverviewEventCard(Map<String, dynamic> event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.event, color: Color(0xFF4CAF50)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['location'] ?? 'Event Location',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${event['date']} at ${event['time']}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  '${event['likes'] ?? 0} likes • ${(event['comments'] as List?)?.length ?? 0} comments',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              event['status'] ?? 'Pending',
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: SupabaseService.getUserCampaignsStream(userId),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: const Center(
                  child: Text(
                    'No recent activity yet',
                    style: TextStyle(fontSize: 13, color: Colors.black38),
                  ),
                ),
              );
            }

            // Filter only upcoming/active events
            final now = DateTime.now();
            final recentUpcoming = snapshot.data!.where((event) {
              try {
                final dateStr = event['date'] as String?;
                final timeStr = event['time'] as String?;
                if (dateStr == null || timeStr == null) return false;

                // Parse date
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
                if (eventDate == null) return false;

                // Parse time
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
                return false;
              }
            }).take(5).toList();

            if (recentUpcoming.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: const Center(
                  child: Text(
                    'No upcoming activities',
                    style: TextStyle(fontSize: 13, color: Colors.black38),
                  ),
                ),
              );
            }

            return Column(
              children: recentUpcoming.map((event) {
                final location = event['location'] ?? 'Unknown location';
                final status = event['status'] ?? 'pending';
                final timeAgo = _getTimeAgo(event['createdAt']);
                final isCompleted = status == 'completed';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle : Icons.event,
                        color: isCompleted
                            ? Colors.blue
                            : const Color(0xFF4CAF50),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Event posted at $location',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              timeAgo,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isCompleted
                                      ? Colors.blue
                                      : const Color(0xFF4CAF50))
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 10,
                            color: isCompleted
                                ? Colors.blue
                                : const Color(0xFF4CAF50),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCampaignsTab() {
    if (_showCreateForm) {
      return _buildCreateEventForm();
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.getUserCampaignsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
          );
        }

        // If there's an error but we have data, show the data anyway
        if (snapshot.hasError && !snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No events yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first event to get started',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No events yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first event to get started',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        // Filter only upcoming events
        final now = DateTime.now();
        final upcomingEvents = snapshot.data!.where((event) {
          try {
            final dateStr = event['date'] as String?;
            final timeStr = event['time'] as String?;
            if (dateStr == null || timeStr == null) return false;

            // Parse date
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
            if (eventDate == null) return false;

            // Parse time
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
            return false;
          }
        }).toList();

        if (upcomingEvents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No upcoming events',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All events have concluded',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: upcomingEvents.length,
          itemBuilder: (context, index) {
            final data = upcomingEvents[index];
            final id = data['id'] as String;
            return _buildDetailedEventCard(id, data);
          },
        );
      },
    );
  }

  Widget _buildDetailedEventCard(String id, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  data['location'] ?? 'Event Location',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              _buildStatusChip(data['status'] ?? 'pending'),
            ],
          ),
          const SizedBox(height: 8),
          if (data['description'] != null &&
              data['description'].toString().isNotEmpty)
            Text(
              data['description'],
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${data['date'] ?? 'Date TBD'} at ${data['time'] ?? 'Time TBD'}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.favorite, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${data['likes'] ?? 0} likes',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(width: 16),
              Icon(Icons.comment, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${(data['comments'] as List?)?.length ?? 0} comments',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          if (data['mediaUrls'] != null &&
              (data['mediaUrls'] as List).isNotEmpty)
            Column(
              children: [
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: (data['mediaUrls'] as List).length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            data['mediaUrls'][index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Posted ${_getTimeAgo(data['createdAt'])}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _editEvent(id, data),
                    child: const Text(
                      'Edit',
                      style: TextStyle(color: Color(0xFF4CAF50)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _deleteEvent(id),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = status == 'active'
        ? Colors.green
        : status == 'completed'
        ? Colors.blue
        : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildVolunteersTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.client
          .from('campaigns')
          .stream(primaryKey: ['id'])
          .eq('created_by', userId),
      builder: (context, snapshot) {
        // Show loading only if there's no data at all
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
          );
        }

        // If there's an error but we have data, show the data anyway
        // This prevents flickering when connection drops
        if (snapshot.hasError && !snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No volunteers yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Volunteers will appear here when they join your campaigns',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Extract all volunteers from all campaigns
        List<Map<String, dynamic>> allVolunteers = [];
        if (snapshot.hasData && snapshot.data != null) {
          for (var campaign in snapshot.data!) {
            final registrationDetails =
                campaign['registration_details'] as Map<String, dynamic>?;
            if (registrationDetails != null && registrationDetails.isNotEmpty) {
              for (var entry in registrationDetails.entries) {
                final volunteerData =
                    entry.value as Map<String, dynamic>? ?? {};
                allVolunteers.add({
                  'id': entry.key,
                  'name': volunteerData['name'] ?? 'Unknown',
                  'email': volunteerData['email'] ?? 'No email',
                  'phone': volunteerData['phone'] ?? 'No phone',
                  'tshirtSize': volunteerData['tshirtSize'] ?? 'M',
                  'experience': volunteerData['experience'] ?? 'First time',
                  'hasTransport': volunteerData['hasTransport'] ?? false,
                  'eventLocation':
                      volunteerData['eventLocation'] ??
                      campaign['location'] ??
                      'Unknown Location',
                  'eventDate':
                      volunteerData['eventDate'] ??
                      campaign['date'] ??
                      'Unknown Date',
                  'eventTime':
                      volunteerData['eventTime'] ??
                      campaign['time'] ??
                      'Unknown Time',
                  'registeredAt':
                      volunteerData['registeredAt'] ??
                      DateTime.now().toIso8601String(),
                  'registrationStatus':
                      volunteerData['registrationStatus'] ?? 'registered',
                  'campaignsJoined': 0,
                  'hoursContributed': 0,
                });
              }
            }
          }
        }

        if (allVolunteers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No volunteers yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Volunteers will appear here when they join your campaigns',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Show the data even if there's a connection error
        // This keeps the UI stable and prevents flickering
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allVolunteers.length,
          itemBuilder: (context, index) {
            final volunteer = allVolunteers[index];
            return _buildVolunteerCard(volunteer);
          },
        );
      },
    );
  }

  Widget _buildVolunteerCard(Map<String, dynamic> volunteer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF4CAF50),
                child: Text(
                  (volunteer['name'] ?? 'V')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      volunteer['name'] ?? 'Volunteer',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      volunteer['email'] ?? 'No email',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Registered ${_getTimeAgo(volunteer['registeredAt'])}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Event info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Event Details',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.blue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        volunteer['eventLocation'] ?? 'Unknown Location',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.blue),
                    const SizedBox(width: 6),
                    Text(
                      '${volunteer['eventDate'] ?? 'TBD'} at ${volunteer['eventTime'] ?? 'TBD'}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Contact info
          Row(
            children: [
              Icon(Icons.phone, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                volunteer['phone'] ?? 'No phone',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // T-shirt size and Experience
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Size: ${volunteer['tshirtSize'] ?? 'M'}',
                  style: const TextStyle(color: Colors.blue, fontSize: 11),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  volunteer['experience'] ?? 'First time',
                  style: const TextStyle(color: Colors.orange, fontSize: 11),
                ),
              ),
              if (volunteer['hasTransport'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '🚗 Has Transport',
                    style: TextStyle(color: Colors.green, fontSize: 11),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _addSampleVolunteer() async {
    await SupabaseService.client.from('volunteers').insert({
      'name': 'John Doe',
      'email': 'john.doe@example.com',
      'organizer_id': userId,
      'campaigns_joined': 3,
      'hours_contributed': 24,
      'joined_at': DateTime.now().toIso8601String(),
    });
  }

  void _createCampaign(
    String title,
    String description,
    String location,
  ) async {
    if (title.isEmpty) return;

    await SupabaseService.client.from('campaigns').insert({
      'title': title,
      'description': description,
      'location': location,
      'created_by': userId,
      'status': 'upcoming',
      'volunteers': [],
      'waste_collected': 0,
      'date': DateTime.now()
          .add(const Duration(days: 7))
          .toString()
          .split(' ')[0],
      'created_at': DateTime.now().toIso8601String(),
    });

    if (mounted) Navigator.pop(context);
  }

  void _editEvent(String id, Map<String, dynamic> data) {
    // Populate form with existing data
    _locationController.text = data['location'] ?? '';
    _dateController.text = data['date'] ?? '';
    _timeController.text = data['time'] ?? '';
    _descriptionController.text = data['description'] ?? '';

    // Set edit mode
    setState(() {
      _isEditMode = true;
      _editingEventId = id;
      _showCreateForm = true;
    });

    // Switch to Events tab
    _tabController.animateTo(1);
  }

  void _deleteEvent(String id) async {
    await SupabaseService.deleteCampaign(id);
  }

  String _getTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'recently';

    DateTime eventTime;
    try {
      if (timestamp is String) {
        eventTime = DateTime.parse(timestamp);
      } else if (timestamp is DateTime) {
        eventTime = timestamp;
      } else {
        return 'recently';
      }
    } catch (e) {
      return 'recently';
    }

    final now = DateTime.now();
    final difference = now.difference(eventTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'just now';
    }
  }

  void _clearForm() {
    _locationController.clear();
    _dateController.clear();
    _timeController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedFiles.clear();
      _webImages.clear();
      _fileNames.clear();
      _showCreateForm = false;
      _isEditMode = false;
      _editingEventId = null;
    });
  }

  InputDecoration _fieldDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Color(0xFF4CAF50)),
      prefixIcon: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF4CAF50), size: 18),
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4CAF50)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
      ),
    );
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _dateController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      _timeController.text = picked.format(context);
    }
  }

  Future<void> _pickMedia() async {
    final int currentCount = kIsWeb ? _webImages.length : _selectedFiles.length;
    if (currentCount >= 4) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Maximum 4 images allowed')));
      return;
    }

    final List<XFile> files = await _picker.pickMultiImage();
    if (files.isEmpty) return;

    if (kIsWeb) {
      for (var file in files) {
        if (_webImages.length >= 4) break;
        final bytes = await file.readAsBytes();
        _webImages.add(bytes);
        _fileNames.add(file.name);
      }
      setState(() {});
    } else {
      for (var file in files) {
        if (_selectedFiles.length >= 4) break;
        _selectedFiles.add(File(file.path));
        _fileNames.add(file.name);
      }
      setState(() {});
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (kIsWeb) {
        _webImages.removeAt(index);
      } else {
        _selectedFiles.removeAt(index);
      }
      if (index < _fileNames.length) _fileNames.removeAt(index);
    });
  }

  Widget _buildImageUploadBox() {
    final count = kIsWeb ? _webImages.length : _selectedFiles.length;
    final canAddMore = count < 4;

    if (count == 0) {
      return GestureDetector(
        onTap: _pickMedia,
        child: Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload, color: Color(0xFF4CAF50), size: 40),
              SizedBox(height: 8),
              Text(
                'Tap to upload images',
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Up to 4 images',
                style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    // Total tiles = selected images + (add more tile if under limit)
    final totalTiles = canAddMore ? count + 1 : count;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: totalTiles,
      itemBuilder: (context, i) {
        // Last tile = "add more" button
        if (canAddMore && i == count) {
          return GestureDetector(
            onTap: _pickMedia,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                  style: BorderStyle.solid,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    color: Color(0xFF4CAF50),
                    size: 32,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Add more',
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Image tile with remove button
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: kIsWeb
                  ? Image.memory(_webImages[i], fit: BoxFit.cover)
                  : Image.file(_selectedFiles[i], fit: BoxFit.cover),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeImage(i),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _postEvent() async {
    if (_locationController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('User not signed in');

      // Upload media files
      List<String> mediaUrls = [];
      try {
        if (kIsWeb && _webImages.isNotEmpty) {
          mediaUrls = await SupabaseService.uploadMultipleImages(
            imageDataList: _webImages,
            bucket: 'campaigns',
            folder: 'events',
          );
        } else if (_selectedFiles.isNotEmpty) {
          mediaUrls = await SupabaseService.uploadMultipleImages(
            imageDataList: _selectedFiles,
            bucket: 'campaigns',
            folder: 'events',
          );
        }
      } catch (_) {
        // bucket may not exist — post event without images
      }

      if (_isEditMode && _editingEventId != null) {
        // Update existing event
        Map<String, dynamic> updateData = {
          'location': _locationController.text.trim(),
          'date': _dateController.text.trim(),
          'time': _timeController.text.trim(),
          'description': _descriptionController.text.trim(),
          'status': 'active',
        };

        if (mediaUrls.isNotEmpty) {
          updateData['media_urls'] = mediaUrls;
        }

        await SupabaseService.updateCampaign(_editingEventId!, updateData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Event updated successfully!')),
          );
        }
      } else {
        // Create new event
        await SupabaseService.createCampaign(
          location: _locationController.text.trim(),
          date: _dateController.text.trim(),
          time: _timeController.text.trim(),
          description: _descriptionController.text.trim(),
          mediaUrls: mediaUrls,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Event posted successfully!')),
          );
        }
      }

      // Clear form and reset state
      _clearForm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildCreateEventForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with back button
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (mounted) {
                    setState(() {
                      _showCreateForm = false;
                      _isEditMode = false;
                      _editingEventId = null;
                    });
                    _clearForm();
                  }
                },
                icon: const Icon(Icons.arrow_back, color: Color(0xFF4CAF50)),
              ),
              Text(
                _isEditMode ? 'Edit Event' : 'Create New Event',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Event Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Event Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 16),

                // Location
                TextField(
                  controller: _locationController,
                  decoration: _fieldDecoration(
                    'Location',
                    'e.g. Central Park, Lagos',
                    Icons.location_on,
                  ),
                ),
                const SizedBox(height: 16),

                // Date
                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _dateController,
                      decoration: _fieldDecoration(
                        'Date',
                        'Select event date',
                        Icons.calendar_month,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Time
                GestureDetector(
                  onTap: _pickTime,
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _timeController,
                      decoration: _fieldDecoration(
                        'Time',
                        'Select event time',
                        Icons.schedule,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: _fieldDecoration(
                    'Description',
                    'Describe the event goals and activities...',
                    Icons.description,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Media Upload Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Event Images',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 16),
                _buildImageUploadBox(),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Post Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _postEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _isEditMode ? 'Update Event' : 'Post Event',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
