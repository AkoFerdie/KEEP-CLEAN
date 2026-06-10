// File: lib/post_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Waste Pickup',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          tabs: const [
            Tab(text: 'Browse Pickups'),
            Tab(text: 'Schedule Pickup'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _BrowsePickupsTab(),
          _SchedulePickupTab(onPostSuccess: () {
            _tabController.animateTo(0);
          }),
        ],
      ),
    );
  }
}

// ============ BROWSE PICKUPS TAB ============
class _BrowsePickupsTab extends StatefulWidget {
  const _BrowsePickupsTab();

  @override
  State<_BrowsePickupsTab> createState() => _BrowsePickupsTabState();
}

class _BrowsePickupsTabState extends State<_BrowsePickupsTab> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.getWasteRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.green));
        }

        final pickups = snapshot.data ?? [];

        if (pickups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('No scheduled pickups yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text('Be the first to schedule a pickup!', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pickups.length,
          itemBuilder: (context, index) {
            return _PickupCard(key: ValueKey(pickups[index]['id']), data: pickups[index]);
          },
        );
      },
    );
  }
}

class _PickupCard extends StatefulWidget {
  final Map<String, dynamic> data;

  const _PickupCard({super.key, required this.data});

  @override
  State<_PickupCard> createState() => _PickupCardState();
}

class _PickupCardState extends State<_PickupCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final List imageUrls = widget.data['image_urls'] ?? [];
    final String status = widget.data['status'] ?? 'open';
    final String postedBy = widget.data['posted_by'] ?? 'Anonymous';
    final String? profileImageUrl = widget.data['profile_image_url'];
    final String description = widget.data['description'] ?? '';
    final bool isLong = description.length > 80;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview at the top
          if (imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imageUrls[0],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                ),
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : Container(
                        height: 200,
                        color: Colors.grey[100],
                        child: const Center(child: CircularProgressIndicator(color: Colors.green)),
                      ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: avatar + name + status
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.green.withValues(alpha: 0.1),
                      backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : null,
                      child: profileImageUrl == null || profileImageUrl.isEmpty
                          ? const Icon(Icons.person, size: 18, color: Colors.green)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(postedBy,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(widget.data['location'] ?? 'Unknown location',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showDetailSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: status == 'open'
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status[0].toUpperCase() + status.substring(1),
                          style: TextStyle(
                            color: status == 'open' ? Colors.green : Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description with "... view more"
                if (description.isNotEmpty)
                  _expanded || !isLong
                      ? Text(description,
                          style: TextStyle(color: Colors.grey[800], fontSize: 14, height: 1.4))
                      : RichText(
                          text: TextSpan(
                            style: TextStyle(color: Colors.grey[800], fontSize: 14, height: 1.4),
                            children: [
                              TextSpan(text: description.substring(0, 80)),
                              const TextSpan(text: '... '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () => setState(() => _expanded = true),
                                  child: const Text(
                                    'view more',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                if (_expanded && isLong) ...
                  [
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: () => setState(() => _expanded = false),
                      child: const Text('view less',
                          style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],

                const SizedBox(height: 12),

                // Tags row
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _tag(Icons.access_time_outlined,
                        widget.data['pickup_time'] != null ? 'Scheduled' : 'Flexible', Colors.teal),
                    if (widget.data['phone'] != null)
                      _tag(Icons.phone_outlined, widget.data['phone'], Colors.blue),
                    if (widget.data['amount'] != null)
                      _tag(Icons.account_balance_wallet_outlined,
                          '${widget.data['amount']}frs FCFA', Colors.orange),
                  ],
                ),

                const SizedBox(height: 12),

                // Waiting / accepted bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: status == 'open'
                        ? const Color(0xFFFFF8E1)
                        : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        status == 'open'
                            ? '⏳ Waiting for someone to accept...'
                            : '✅ Accepted',
                        style: TextStyle(
                          color: status == 'open' ? Colors.orange[800] : Colors.green[800],
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // View all images button — only if images exist
                if (imageUrls.isNotEmpty) ...
                  [
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _showImagesSheet(context, imageUrls),
                      child: Row(
                        children: [
                          const Icon(Icons.photo_library_outlined, color: Colors.green, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            imageUrls.length > 1 
                                ? 'View all ${imageUrls.length} photos' 
                                : 'View photo',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios, color: Colors.green, size: 12),
                        ],
                      ),
                    ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showDetailSheet(BuildContext context) {
    final List imageUrls = widget.data['image_urls'] ?? [];
    final String status = widget.data['status'] ?? 'open';
    final String postedBy = widget.data['posted_by'] ?? 'Anonymous';
    final String? profileImageUrl = widget.data['profile_image_url'];
    final String description = widget.data['description'] ?? '';
    int current = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Images carousel
                        if (imageUrls.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              height: 220,
                              child: PageView.builder(
                                itemCount: imageUrls.length,
                                onPageChanged: (i) => setModalState(() => current = i),
                                itemBuilder: (context, index) => InteractiveViewer(
                                  child: Image.network(
                                    imageUrls[index],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, _, _) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                    ),
                                    loadingBuilder: (context, child, progress) => progress == null
                                        ? child
                                        : Container(
                                            color: Colors.grey[100],
                                            child: const Center(child: CircularProgressIndicator(color: Colors.green)),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (imageUrls.length > 1) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                imageUrls.length,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: current == i ? 16 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: current == i ? Colors.green : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                        ],

                        // Poster info
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.green.withValues(alpha: 0.1),
                              backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                                  ? NetworkImage(profileImageUrl) : null,
                              child: profileImageUrl == null || profileImageUrl.isEmpty
                                  ? const Icon(Icons.person, size: 22, color: Colors.green) : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(postedBy, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(widget.data['location'] ?? 'Unknown location',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: status == 'open' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status[0].toUpperCase() + status.substring(1),
                                style: TextStyle(
                                  color: status == 'open' ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.bold, fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),

                        // Description
                        if (description.isNotEmpty) ...[
                          const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 6),
                          Text(description, style: TextStyle(color: Colors.grey[800], fontSize: 14, height: 1.5)),
                          const SizedBox(height: 16),
                        ],

                        // Details
                        const Text('Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 10),
                        if (widget.data['waste_type'] != null)
                          _detailRow(Icons.delete_outline, 'Waste Type', widget.data['waste_type']),
                        if (widget.data['phone'] != null)
                          _detailRow(Icons.phone_outlined, 'Contact', widget.data['phone']),
                        if (widget.data['amount'] != null)
                          _detailRow(Icons.account_balance_wallet_outlined, 'Amount', '${widget.data['amount']} FCFA'),
                        _detailRow(Icons.access_time_outlined, 'Pickup Time',
                            widget.data['pickup_time'] != null ? 'Scheduled' : 'Flexible'),

                        const SizedBox(height: 24),

                        // Accept button
                        if (status == 'open')
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('✅ You accepted this pickup!')),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Accept Pickup',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.green),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Expanded(child: Text(value, style: TextStyle(color: Colors.grey[700], fontSize: 13))),
        ],
      ),
    );
  }

  void _showImagesSheet(BuildContext context, List imageUrls) {
    int current = 0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle + header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white38,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${current + 1} / ${imageUrls.length}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              // Image pager
              Expanded(
                child: PageView.builder(
                  itemCount: imageUrls.length,
                  onPageChanged: (i) => setModalState(() => current = i),
                  itemBuilder: (context, index) => InteractiveViewer(
                    child: Image.network(
                      imageUrls[index],
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(Icons.broken_image, color: Colors.white54, size: 60),
                      ),
                      loadingBuilder: (context, child, progress) => progress == null
                          ? child
                          : const Center(child: CircularProgressIndicator(color: Colors.white)),
                    ),
                  ),
                ),
              ),
              // Dot indicators
              if (imageUrls.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      imageUrls.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: current == i ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: current == i ? Colors.white : Colors.white38,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ SCHEDULE PICKUP TAB ============
class _SchedulePickupTab extends StatefulWidget {
  final VoidCallback onPostSuccess;
  const _SchedulePickupTab({required this.onPostSuccess});

  @override
  State<_SchedulePickupTab> createState() => _SchedulePickupTabState();
}

class _SchedulePickupTabState extends State<_SchedulePickupTab> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  bool _isUploading = false;

  // Waste type dropdown options
  final List<String> _wasteTypes = [
    "Organic",
    "Inorganic",
    "Electronic",
    "Hazardous"
  ];
  String? _selectedWasteType;

  @override
  void dispose() {
    _locationController.dispose();
    _typeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> picked = await _picker.pickMultiImage();
      setState(() {
        _selectedImages.addAll(picked);
        if (_selectedImages.length > 3) {
          _selectedImages = _selectedImages.sublist(0, 3);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to pick images: $e")),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<List<String>> _uploadImages() async {
    List<String> downloadUrls = [];

    for (int i = 0; i < _selectedImages.length; i++) {
      final XFile image = _selectedImages[i];

      try {
        final String url = await SupabaseService.uploadImage(
          imageData: image,
          bucket: 'waste-images',
          folder: 'reports',
        );
        downloadUrls.add(url);
        print('DEBUG: Uploaded image URL: $url');
      } catch (e) {
        print('DEBUG: Upload error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Upload failed: $e")),
          );
        }
      }
    }
    return downloadUrls;
  }

  Future<void> _submitReport() async {
  final location = _locationController.text.trim();
  final type = _typeController.text.trim().isNotEmpty
      ? _typeController.text.trim()
      : _selectedWasteType ?? "";

  final description = _descriptionController.text.trim();

  if (location.isEmpty || type.isEmpty || description.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please fill in all fields")),
    );
    return;
  }

  if (_selectedImages.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please upload at least one photo")),
    );
    return;
  }

  setState(() {
    _isUploading = true;
  });

  try {
    final user = SupabaseService.currentUser;

    if (user == null) {
      throw Exception("User not authenticated");
    }

    // FETCH USER PROFILE
    final profile = await SupabaseService.client
        .from('users')
        .select()
        .eq('id', user.id)
        .single();

    final String username =
        profile['username'] ??
        user.email?.split('@')[0] ??
        'Anonymous';

    final String profileImageUrl =
        profile['profile_image_url'] ?? '';

    // UPLOAD IMAGES
    final List<String> imageUrls = await _uploadImages();

    if (imageUrls.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No images uploaded")),
        );
      }
      return;
    }

    // CREATE REPORT
    await SupabaseService.client.from('waste_requests').insert({
      'location': location,
      'phone': 'Contact via app',
      'pickup_time': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
      'description': description,
      'waste_type': type,
      'image_urls': imageUrls,
      'created_by': user.id,
      'posted_by': username,
      'profile_image_url': profileImageUrl,
      'status': 'open',
      'created_at': DateTime.now().toIso8601String(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Pickup scheduled successfully!"),
      ),
    );

    _locationController.clear();
    _typeController.clear();
    _descriptionController.clear();

    setState(() {
      _selectedWasteType = null;
      _selectedImages.clear();
    });

    // Switch to Browse Pickups tab immediately
    widget.onPostSuccess();
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Submission failed: $e")),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isUploading = false;
      });
    }
  }
}

  // ✅ Open Google Maps with current location
  Future<void> _openMap() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location services are disabled.")),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permissions are denied.")),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Location permissions are permanently denied.")),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      String googleMapsUrl =
          "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";

      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(Uri.parse(googleMapsUrl),
            mode: LaunchMode.externalApplication);
        if (mounted) {
          _locationController.text =
              "${position.latitude}, ${position.longitude}";
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open Google Maps.")),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching location: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isUploading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 16),
                  Text("Uploading your report..."),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location
                  const Text(
                    'Location',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'Enter address or use current location',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Use Map button
                  ElevatedButton(
                    onPressed: _openMap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8F5E8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Use Map",
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.location_on, color: Colors.green),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Type of Waste
                  const Text(
                    'Type of Waste',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _typeController,
                    decoration: InputDecoration(
                      hintText: 'Enter type of waste',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      suffixIcon: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedWasteType,
                          hint: const Text("Select"),
                          items: _wasteTypes
                              .map((type) => DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedWasteType = value;
                              _typeController.text = value ?? "";
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Describe the situation...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Upload Photos
                  const Text(
                    'Upload Photos',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.photo_library_outlined,
                        color: Colors.black54),
                    label: const Text('Choose Photos',
                        style: TextStyle(color: Colors.black54)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8F5E8),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_selectedImages.isNotEmpty)
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_selectedImages[index].path),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const Icon(Icons.broken_image),
                                ),
                              ),
                              Positioned(
                                top: -6,
                                right: -6,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () => _removeImage(index),
                                  icon: const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.red,
                                    child: Icon(Icons.close,
                                        size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 30),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Schedule Pickup',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
  }
}
