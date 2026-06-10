// File: lib/profile_page.dart
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'notifications_page.dart';
import 'settings_page.dart';
import 'dashboard_screen.dart';
import 'hysacam_dashboard.dart';
import 'volunteer_dashboard.dart';
import 'signin_page.dart';
import 'edit_profile_page.dart';
import '../utils/theme_helper.dart';

class ProfilePage extends StatefulWidget {
  final String fullName;
  final String email;

  const ProfilePage({super.key, required this.fullName, required this.email});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _profileImage;
  Uint8List? _webImage;
  bool _hasNewImage = false;
  bool _isUploading = false;
  String? _currentProfileImageUrl;
  String _username = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = SupabaseService.currentUser;
    if (user != null) {
      try {
        final data = await SupabaseService.getUserProfile(user.id);
        if (data != null && mounted) {
          setState(() {
            _username = data['username'] ?? user.userMetadata?['username'] ?? '';
            _currentProfileImageUrl = data['profile_image_url'] ?? '';
            _email = data['email'] ?? user.email ?? '';
          });
        } else {
          final emailToSave = user.email ?? '';
          await SupabaseService.upsertUserProfile(user.id, {
            'username': user.userMetadata?['username'] ?? 'User',
            'email': emailToSave,
            'role': 'User',
          });
          if (mounted) {
            setState(() {
              _username = user.userMetadata?['username'] ?? '';
              _email = emailToSave;
            });
          }
        }
      } catch (e) {
        debugPrint('Error loading profile: $e');
      }
    }
  }

  Future<bool> _requestPermissions() async {
    if (kIsWeb) return true;
    final cameraStatus = await Permission.camera.status;
    final storageStatus = await Permission.photos.status;
    if (!cameraStatus.isGranted) await Permission.camera.request();
    if (!storageStatus.isGranted) await Permission.photos.request();
    return await Permission.camera.isGranted && await Permission.photos.isGranted;
  }

  Future<void> _pickImage(ImageSource source) async {
    if (await _requestPermissions()) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          if (mounted) {
            setState(() {
              _webImage = bytes;
              _profileImage = null;
              _hasNewImage = true;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _profileImage = File(pickedFile.path);
              _webImage = null;
              _hasNewImage = true;
            });
          }
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Permissions are required to select an image")),
      );
    }
  }

  Future<void> _uploadImageAndSaveUrl() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    if (_profileImage == null && _webImage == null) return;

    if (mounted) {
      setState(() {
        _isUploading = true;
      });
    }

    try {
      final imageData = kIsWeb && _webImage != null ? _webImage! : await _profileImage!.readAsBytes();
      
      final downloadUrl = await SupabaseService.uploadImage(
        imageData: imageData,
        bucket: 'profile_pictures',
        fileName: '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await SupabaseService.updateUserProfile(user.id, {'profile_image_url': downloadUrl});

      if (mounted) {
        setState(() {
          _currentProfileImageUrl = downloadUrl;
          _hasNewImage = false;
          _profileImage = null;
          _webImage = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile picture updated successfully!")),
        );
      }
    } catch (e) {
      debugPrint("Error uploading image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update profile picture: $e")),
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

  void _openFullScreenImage() {
    ImageProvider imageProvider;
    if (_webImage != null) {
      imageProvider = MemoryImage(_webImage!);
    } else if (_profileImage != null) {
      imageProvider = FileImage(_profileImage!);
    } else if (_currentProfileImageUrl != null &&
        _currentProfileImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_currentProfileImageUrl!);
    } else {
      imageProvider = const AssetImage("assets/front_logo.png");
    }

    showDialog(
      context: context,
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Center(
                child: Image(
                  image: imageProvider,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveChanges() {
    _uploadImageAndSaveUrl();
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Choose from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Take a Photo"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userFullName = (_username.isNotEmpty) ? _username : 'User';
    final userEmail = _email.isNotEmpty ? _email : (widget.email.isNotEmpty ? widget.email : 'No email');

    ImageProvider profileImageProvider;
    if (_webImage != null) {
      profileImageProvider = MemoryImage(_webImage!);
    } else if (_profileImage != null) {
      profileImageProvider = FileImage(_profileImage!);
    } else if (_currentProfileImageUrl != null &&
        _currentProfileImageUrl!.isNotEmpty) {
      // Handle Google profile images with error fallback
      profileImageProvider = NetworkImage(_currentProfileImageUrl!);
    } else {
      profileImageProvider = const AssetImage("assets/front_logo.png");
    }

    return Scaffold(
      backgroundColor: ThemeHelper.getSurfaceColor(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          MediaQuery.of(context).size.width * 0.05,
          MediaQuery.of(context).size.height * 0.04,
          MediaQuery.of(context).size.width * 0.05,
          30,
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: _openFullScreenImage,
                  child: CircleAvatar(
                    radius: MediaQuery.of(context).size.width * 0.13,
                    backgroundColor: Colors.grey.shade200,
                    child: _webImage != null || _profileImage != null || 
                           (_currentProfileImageUrl != null && _currentProfileImageUrl!.isNotEmpty)
                        ? ClipOval(
                            child: Image(
                              image: profileImageProvider,
                              fit: BoxFit.cover,
                              width: MediaQuery.of(context).size.width * 0.26,
                              height: MediaQuery.of(context).size.width * 0.26,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback to logo on error (e.g., 429 rate limit)
                                return Image.asset(
                                  'assets/front_logo.png',
                                  fit: BoxFit.cover,
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: const Color(0xFF4CAF50),
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                            ),
                          )
                        : Image.asset('assets/front_logo.png', fit: BoxFit.cover),
                  ),
                ),
                GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              userFullName.isEmpty ? "User" : userFullName,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.05,
                fontWeight: FontWeight.bold,
                color: ThemeHelper.getTextColor(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              userEmail,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.033,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Active Citizen",
                style: TextStyle(fontSize: 12, color: Color(0xFF4CAF50), fontWeight: FontWeight.w500),
              ),
            ),

            const SizedBox(height: 24),

            // ── Stats Row ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: SupabaseService.getUserWasteRequestsStream(SupabaseService.currentUser?.id ?? ''),
                builder: (context, snapshot) {
                  final reportCount = snapshot.hasData ? snapshot.data!.length : 0;
                  return Row(
                    children: [
                      _buildStatCard("Campaigns", "0", Icons.campaign_outlined),
                      const SizedBox(width: 12),
                      _buildStatCard("Reports", '$reportCount', Icons.report_outlined),
                      const SizedBox(width: 12),
                      _buildStatCard("Points", "0", Icons.star_outline_rounded),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // ── Menu Section ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Account",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  _buildMenuCard([
                    _buildMenuItem(Icons.dashboard_outlined, "Dashboard", "View your activity", () async {
                      final userProfile = await SupabaseService.getUserProfile(SupabaseService.currentUser?.id ?? '');
                      final role = userProfile?['role'] ?? '';
                      
                      if (!mounted) return;
                      if (role == 'Government Company (Hysacam)') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HysacamDashboard()));
                      } else if (role == 'Organization / Volunteer') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const VolunteerDashboard()));
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
                      }
                    }),
                    _buildMenuItem(Icons.person_outline, "Edit Profile", "Update your information", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditProfilePage()),
                      );
                    }),
                  ]),

                  const SizedBox(height: 20),

                  Text(
                    "Preferences",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  _buildMenuCard([
                    _buildMenuItem(Icons.notifications_outlined, "Notifications", "Manage alerts", () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
                    }),
                    _buildMenuItem(Icons.settings_outlined, "Settings", "App preferences", () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                    }),
                    _buildMenuItem(Icons.help_outline_rounded, "Help & Support", "Get assistance", () {}),
                  ]),

                  const SizedBox(height: 20),

                  // Save photo button (only shown when new image picked)
                  if (_hasNewImage)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _saveChanges,
                        icon: _isUploading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.cloud_upload_outlined, color: Colors.white),
                        label: Text(_isUploading ? "Uploading..." : "Save Profile Photo",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),

                  if (_hasNewImage) const SizedBox(height: 12),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await SupabaseService.signOut();
                        if (!mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const SignInPage()),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                      label: const Text("Log Out",
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 15)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Material(
        color: ThemeHelper.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        shadowColor: Colors.grey.withValues(alpha: 0.15),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF4CAF50), size: 22),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThemeHelper.getTextColor(context))),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> items) {
    return Material(
      color: ThemeHelper.getCardColor(context),
      borderRadius: BorderRadius.circular(16),
      shadowColor: Colors.grey.withValues(alpha: 0.15),
      elevation: 2,
      child: Column(children: items),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
      ),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ThemeHelper.getTextColor(context))),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded, 
        size: 14, 
        color: ThemeHelper.getSecondaryTextColor(context).withValues(alpha: 0.7),
      ),
    );
  }
}