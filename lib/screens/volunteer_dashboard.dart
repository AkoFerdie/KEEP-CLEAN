import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/theme_helper.dart';

class VolunteerDashboard extends StatefulWidget {
  const VolunteerDashboard({super.key});

  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  // Add these variables for edit mode
  bool _isEditMode = false;
  String? _editingEventId;
  
  // Event creation form controllers
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedFiles = [];
  List<Uint8List> _webImages = [];
  List<String> _fileNames = [];
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
            Text('Volunteer Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
            Text('Cleanup Organizations Hub', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
        padding: const EdgeInsets.only(right: 16, bottom: 16),
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
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('campaigns').where('createdBy', isEqualTo: userId).snapshots(),
      builder: (context, snapshot) {
        int activeEvents = 0, totalLikes = 0, totalComments = 0;
        
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['status'] == 'active' || data['status'] == 'pending') activeEvents++;
            totalLikes += (data['likes'] as int?) ?? 0;
            totalComments += ((data['comments'] as List?)?.length ?? 0);
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
            _buildStatCard('Active Events', '$activeEvents', Icons.event, Colors.blue),
            _buildStatCard('Total Likes', '$totalLikes', Icons.favorite, Colors.red),
            _buildStatCard('Total Comments', '$totalComments', Icons.comment, Colors.orange),
            _buildStatCard('Events Posted', '${snapshot.data?.docs.length ?? 0}', Icons.post_add, Colors.purple),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
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
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.trending_up, color: color, size: 16),
              ),
            ],
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Upcoming Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('campaigns')
              .where('createdBy', isEqualTo: userId)
              .where('status', whereIn: ['pending', 'active'])
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final event = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                return _buildOverviewEventCard(event);
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
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.event, color: Color(0xFF4CAF50)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event['location'] ?? 'Event Location', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('${event['date']} at ${event['time']}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text('${event['likes'] ?? 0} likes • ${(event['comments'] as List?)?.length ?? 0} comments', 
                     style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(event['status'] ?? 'Pending', style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
        const SizedBox(height: 12),
        _buildActivityItem('New volunteer joined Limbe Beach Cleanup', '2 hours ago', Icons.person_add, Colors.green),
        _buildActivityItem('Campaign "Clean Douala Streets" completed', '1 day ago', Icons.check_circle, Colors.blue),
        _buildActivityItem('50kg waste collected at Bonanjo Market', '2 days ago', Icons.recycling, Colors.orange),
      ],
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                Text(time, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignsTab() {
    if (_showCreateForm) {
      return _buildCreateEventForm();
    }
    
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('campaigns').where('createdBy', isEqualTo: userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('No events yet', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text('Create your first event to get started', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final event = snapshot.data!.docs[index];
            final data = event.data() as Map<String, dynamic>;
            return _buildDetailedEventCard(event.id, data);
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
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              _buildStatusChip(data['status'] ?? 'pending'),
            ],
          ),
          const SizedBox(height: 8),
          if (data['description'] != null && data['description'].toString().isNotEmpty)
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
          if (data['mediaUrls'] != null && (data['mediaUrls'] as List).isNotEmpty)
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
                                child: const Icon(Icons.image_not_supported, color: Colors.grey),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
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
                    child: const Text('Edit', style: TextStyle(color: Color(0xFF4CAF50))),
                  ),
                  TextButton(
                    onPressed: () => _deleteEvent(id),
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
    Color color = status == 'active' ? Colors.green : status == 'completed' ? Colors.blue : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildVolunteersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('volunteers').where('organizerId', isEqualTo: userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('No volunteers yet', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text('Volunteers will appear here when they join your campaigns', style: TextStyle(fontSize: 14, color: Colors.grey[500]), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // Add sample volunteer for demo
                    _addSampleVolunteer();
                  },
                  icon: const Icon(Icons.person_add, color: Colors.white, size: 18),
                  label: const Text('Add Sample Volunteer', style: TextStyle(color: Colors.white, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final volunteer = snapshot.data!.docs[index].data() as Map<String, dynamic>;
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
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF4CAF50),
            child: Text((volunteer['name'] ?? 'V')[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(volunteer['name'] ?? 'Volunteer', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(volunteer['email'] ?? 'No email', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text('${volunteer['campaignsJoined'] ?? 0} campaigns • ${volunteer['hoursContributed'] ?? 0} hours', 
                     style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ],
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.message, color: Color(0xFF4CAF50))),
        ],
      ),
    );
  }


  void _showCreateCampaignDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final locationController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Campaign Title')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
            TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => _createCampaign(titleController.text, descController.text, locationController.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _addSampleVolunteer() async {
    await _firestore.collection('volunteers').add({
      'name': 'John Doe',
      'email': 'john.doe@example.com',
      'organizerId': userId,
      'campaignsJoined': 3,
      'hoursContributed': 24,
      'joinedAt': FieldValue.serverTimestamp(),
    });
  }

  void _createCampaign(String title, String description, String location) async {
    if (title.isEmpty) return;
    
    await _firestore.collection('campaigns').add({
      'title': title,
      'description': description,
      'location': location,
      'organizerId': userId,
      'status': 'upcoming',
      'volunteers': [],
      'wasteCollected': 0,
      'date': DateTime.now().add(const Duration(days: 7)).toString().split(' ')[0],
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    Navigator.pop(context);
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
    await _firestore.collection('campaigns').doc(id).delete();
  }

  String _getTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'recently';
    
    DateTime eventTime;
    if (timestamp is Timestamp) {
      eventTime = timestamp.toDate();
    } else {
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
          color: const Color(0xFF4CAF50).withOpacity(0.1),
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
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
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
      _dateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
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
    if (kIsWeb) {
      final List<XFile>? files = await _picker.pickMultiImage();
      if (files != null && files.isNotEmpty) {
        List<Uint8List> images = [];
        List<String> names = [];
        for (var file in files) {
          final bytes = await file.readAsBytes();
          images.add(bytes);
          names.add(file.name);
        }
        setState(() {
          _webImages = images;
          _fileNames = names;
          _selectedFiles.clear();
        });
      }
    } else {
      final List<XFile>? files = await _picker.pickMultiImage();
      if (files != null && files.isNotEmpty) {
        List<File> mobileFiles = files.map((f) => File(f.path)).toList();
        List<String> names = files.map((f) => f.name).toList();
        setState(() {
          _selectedFiles = mobileFiles;
          _fileNames = names;
          _webImages.clear();
        });
      }
    }
  }

  Widget _buildPreviewImages() {
    List<Widget> previews = [];
    if (kIsWeb && _webImages.isNotEmpty) {
      for (int i = 0; i < _webImages.length; i++) {
        previews.add(Container(
          margin: const EdgeInsets.only(right: 8),
          child: Image.memory(_webImages[i], width: 80, height: 80, fit: BoxFit.cover),
        ));
      }
    } else if (!kIsWeb && _selectedFiles.isNotEmpty) {
      for (int i = 0; i < _selectedFiles.length; i++) {
        previews.add(Container(
          margin: const EdgeInsets.only(right: 8),
          child: Image.file(_selectedFiles[i], width: 80, height: 80, fit: BoxFit.cover),
        ));
      }
    }
    return previews.isEmpty
        ? const SizedBox.shrink()
        : SizedBox(
            height: 80,
            child: ListView(scrollDirection: Axis.horizontal, children: previews),
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not signed in');

      // Upload media files
      List<String> mediaUrls = [];
      if (kIsWeb) {
        for (int i = 0; i < _webImages.length; i++) {
          final ref = FirebaseStorage.instance
              .ref()
              .child('campaigns/${DateTime.now().millisecondsSinceEpoch}_${_fileNames[i]}');
          await ref.putData(_webImages[i]);
          String url = await ref.getDownloadURL();
          mediaUrls.add(url);
        }
      } else {
        for (int i = 0; i < _selectedFiles.length; i++) {
          final ref = FirebaseStorage.instance
              .ref()
              .child('campaigns/${DateTime.now().millisecondsSinceEpoch}_${_fileNames[i]}');
          await ref.putFile(_selectedFiles[i]);
          String url = await ref.getDownloadURL();
          mediaUrls.add(url);
        }
      }

      Map<String, dynamic> eventData = {
        'location': _locationController.text.trim(),
        'date': _dateController.text.trim(),
        'time': _timeController.text.trim(),
        'description': _descriptionController.text.trim(),
        'status': 'active',
      };

      if (_isEditMode && _editingEventId != null) {
        // Update existing event
        if (mediaUrls.isNotEmpty) {
          eventData['mediaUrls'] = mediaUrls;
        }
        eventData['updatedAt'] = FieldValue.serverTimestamp();
        
        await _firestore.collection('campaigns').doc(_editingEventId).update(eventData);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Event updated successfully!')),
        );
      } else {
        // Create new event
        eventData.addAll({
          'mediaUrls': mediaUrls,
          'createdBy': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'likes': 0,
          'comments': [],
          'registrations': [],
          'registrationCount': 0,
        });
        
        await _firestore.collection('campaigns').add(eventData);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Event posted successfully!')),
        );
      }

      // Clear form and reset state
      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
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
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
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
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Event Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
                ),
                const SizedBox(height: 16),
                
                // Location
                TextField(
                  controller: _locationController,
                  decoration: _fieldDecoration('Location', 'e.g. Central Park, Lagos', Icons.location_on),
                ),
                const SizedBox(height: 16),
                
                // Date
                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _dateController,
                      decoration: _fieldDecoration('Date', 'Select event date', Icons.calendar_month),
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
                      decoration: _fieldDecoration('Time', 'Select event time', Icons.schedule),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Description
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: _fieldDecoration('Description', 'Describe the event goals and activities...', Icons.description),
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
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Event Images',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickMedia,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.cloud_upload, color: Color(0xFF4CAF50), size: 40),
                        SizedBox(height: 8),
                        Text('Tap to upload images', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildPreviewImages(),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_isEditMode ? 'Update Event' : 'Post Event', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}