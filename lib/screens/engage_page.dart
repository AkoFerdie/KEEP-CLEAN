// File: lib/src/screens/engage_page.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';
import '../utils/theme_helper.dart';

class EngagePage extends StatefulWidget {
  const EngagePage({super.key});

  @override
  State<EngagePage> createState() => _EngagePageState();
}

class _EngagePageState extends State<EngagePage> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  List<File> _selectedFiles = []; // for mobile
  List<Uint8List> _webImages = []; // for web
  List<String> _fileNames = [];
  bool _isLoading = false;

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

  /// Pick multiple images from gallery (Web + Mobile)
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

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _dateController.text = "${picked.year}-${picked.month}-${picked.day}";
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      _timeController.text = picked.format(context);
    }
  }

  Future<void> _postCampaign() async {
    if (_locationController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please fill all required fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception("User not signed in");

      // Upload media files to Supabase Storage
      List<String> mediaUrls = [];
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

      // Create campaign using Supabase
      await SupabaseService.createCampaign(
        location: _locationController.text.trim(),
        date: _dateController.text.trim(),
        time: _timeController.text.trim(),
        description: _descriptionController.text.trim(),
        mediaUrls: mediaUrls,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Event posted successfully!")),
      );

      // Clear fields after posting
      _locationController.clear();
      _dateController.clear();
      _timeController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedFiles.clear();
        _webImages.clear();
        _fileNames.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildPreviewImages() {
    List<Widget> previews = [];
    if (kIsWeb && _webImages.isNotEmpty) {
      for (int i = 0; i < _webImages.length; i++) {
        previews.add(Column(
          children: [
            Image.memory(_webImages[i], width: 100, height: 100, fit: BoxFit.cover),
            Text(_fileNames[i], style: TextStyle(fontSize: 12, color: ThemeHelper.getTextColor(context))),
          ],
        ));
      }
    } else if (!kIsWeb && _selectedFiles.isNotEmpty) {
      for (int i = 0; i < _selectedFiles.length; i++) {
        previews.add(Column(
          children: [
            Image.file(_selectedFiles[i], width: 100, height: 100, fit: BoxFit.cover),
            Text(_fileNames[i], style: TextStyle(fontSize: 12, color: ThemeHelper.getTextColor(context))),
          ],
        ));
      }
    }
    return previews.isEmpty
        ? const SizedBox.shrink()
        : Wrap(
            spacing: 8,
            runSpacing: 8,
            children: previews,
          );
  }

  InputDecoration _fieldDecoration(String label, String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: ThemeHelper.getSecondaryTextColor(context), fontSize: 13),
      labelStyle: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w500),
      prefixIcon: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF4CAF50), size: 18),
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: ThemeHelper.getCardColor(context),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ThemeHelper.getBorderColor(context), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBrowseEventsTab(),
          _buildCreateEventTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _tabController.animateTo(1); // Switch to Create Event tab
        },
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBrowseEventsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.getCampaignsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('No events available', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text('Check back later for cleanup events', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final data = snapshot.data![index];
            final eventId = data['id'] as String;
            return _buildPublicEventCard(eventId, data);
          },
        );
      },
    );
  }

  Widget _buildCreateEventTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            "Event Details",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThemeHelper.getTextColor(context)),
          ),
          const SizedBox(height: 4),
          Text(
            "Fill in the details to post a cleanup event.",
            style: TextStyle(fontSize: 13, color: ThemeHelper.getSecondaryTextColor(context)),
          ),
          const SizedBox(height: 24),

          // Campaign Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ThemeHelper.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                ThemeHelper.getCardShadow(context),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Event Details",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF4CAF50)),
                ),
                const SizedBox(height: 14),

                // Location
                TextField(
                  controller: _locationController,
                  decoration: _fieldDecoration("Location", "e.g. Central Park, Lagos", Icons.location_on),
                ),
                const SizedBox(height: 14),

                // Date
                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _dateController,
                      decoration: _fieldDecoration(
                        "Date",
                        "Select event date",
                        Icons.calendar_month,
                        suffix: const Icon(Icons.arrow_drop_down, color: Color(0xFF4CAF50)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Time
                GestureDetector(
                  onTap: _pickTime,
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _timeController,
                      decoration: _fieldDecoration(
                        "Time",
                        "Select event time",
                        Icons.schedule,
                        suffix: const Icon(Icons.arrow_drop_down, color: Color(0xFF4CAF50)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Description
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: _fieldDecoration(
                    "Description",
                    "Describe the event goals and activities...",
                    Icons.description_outlined,
                  ).copyWith(
                    alignLabelWithHint: true,
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
              color: ThemeHelper.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                ThemeHelper.getCardShadow(context),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Media",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF4CAF50)),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickMedia,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: ThemeHelper.getSurfaceColor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF4CAF50).withOpacity(0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.cloud_upload_outlined, color: Color(0xFF4CAF50), size: 30),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Tap to upload images",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: ThemeHelper.getTextColor(context)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Share visuals of the cleanup area",
                          style: TextStyle(fontSize: 12, color: ThemeHelper.getSecondaryTextColor(context)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildPreviewImages(),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Post Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _postCampaign,
              icon: _isLoading
                  ? const SizedBox.shrink()
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              label: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      "Post Event",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicEventCard(String eventId, Map<String, dynamic> data) {
    final currentUserId = SupabaseService.currentUser?.id ?? '';
    final registrations = data['registrations'] as List? ?? [];
    final isRegistered = registrations.contains(currentUserId);
    final registrationCount = data['registrationCount'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeHelper.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [ThemeHelper.getCardShadow(context)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.event, color: Color(0xFF4CAF50), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['location'] ?? 'Event Location',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ThemeHelper.getTextColor(context)),
                    ),
                    Text(
                      '${data['date']} at ${data['time']}',
                      style: TextStyle(color: ThemeHelper.getSecondaryTextColor(context), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (data['description'] != null && data['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              data['description'],
              style: TextStyle(color: ThemeHelper.getTextColor(context), fontSize: 14),
            ),
          ],

          // Event Images
          if (data['mediaUrls'] != null && (data['mediaUrls'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: (data['mediaUrls'] as List).length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 120,
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
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 16),
          
          // Registration Info and Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$registrationCount people registered',
                    style: TextStyle(color: Colors.grey[800], fontSize: 13),
                  ),
                  Text(
                    'Join the cleanup effort',
                    style: TextStyle(color: Colors.grey[800], fontSize: 11),
                  ),
                ],
              ),
              SizedBox(
                width: 100,
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: () => _showRegistrationDialog(eventId, isRegistered, data),
                  icon: Icon(
                    isRegistered ? Icons.check_circle : Icons.person_add,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: Text(
                    isRegistered ? 'Registered' : 'Register',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRegistered ? Colors.green : const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleRegistration(String eventId, bool isCurrentlyRegistered) async {
    final currentUserId = SupabaseService.currentUser?.id;
    if (currentUserId == null) return;

    try {
      if (isCurrentlyRegistered) {
        await SupabaseService.unregisterFromCampaign(eventId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Unregistered from event')),
          );
        }
      } else {
        await SupabaseService.registerForCampaign(eventId, {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎉 Successfully registered for event!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showRegistrationDialog(String eventId, bool isRegistered, Map<String, dynamic> eventData) {
    if (isRegistered) {
      // Show unregister confirmation
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unregister from Event'),
          content: Text('Are you sure you want to unregister from "${eventData['location']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _toggleRegistration(eventId, isRegistered);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Unregister', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      // Show registration form
      _showRegistrationForm(eventId, eventData);
    }
  }

  void _showRegistrationForm(String eventId, Map<String, dynamic> eventData) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    String selectedTShirtSize = 'M';
    String selectedExperience = 'First time';
    bool hasTransport = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Register for ${eventData['location']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Phone
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                
                // Email
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                
                // T-Shirt Size
                DropdownButtonFormField<String>(
                  value: selectedTShirtSize,
                  decoration: const InputDecoration(
                    labelText: 'T-Shirt Size *',
                    border: OutlineInputBorder(),
                  ),
                  items: ['XS', 'S', 'M', 'L', 'XL', 'XXL'].map((size) {
                    return DropdownMenuItem(value: size, child: Text(size));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedTShirtSize = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                
                // Experience Level
                DropdownButtonFormField<String>(
                  value: selectedExperience,
                  decoration: const InputDecoration(
                    labelText: 'Cleanup Experience',
                    border: OutlineInputBorder(),
                  ),
                  items: ['First time', 'Beginner', 'Experienced', 'Expert'].map((exp) {
                    return DropdownMenuItem(value: exp, child: Text(exp));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedExperience = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                
                // Transportation
                CheckboxListTile(
                  title: const Text('I have my own transportation'),
                  value: hasTransport,
                  onChanged: (value) {
                    setState(() {
                      hasTransport = value!;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            SizedBox(
              width: 120,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  if (nameController.text.isEmpty || phoneController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill required fields')),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  _registerWithDetails(eventId, {
                    'name': nameController.text,
                    'phone': phoneController.text,
                    'email': emailController.text,
                    'tshirtSize': selectedTShirtSize,
                    'experience': selectedExperience,
                    'hasTransport': hasTransport,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Register', 
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _registerWithDetails(String eventId, Map<String, dynamic> userDetails) async {
    final currentUserId = SupabaseService.currentUser?.id;
    if (currentUserId == null) return;

    try {
      await SupabaseService.registerForCampaign(eventId, userDetails);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Successfully registered for event!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: ${e.toString()}')),
        );
      }
    }
  }
}