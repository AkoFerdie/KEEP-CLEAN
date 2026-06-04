import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static const String _mobileAuthRedirectUrl =
      'io.supabase.keepitclean://login-callback';

  // ============ AUTHENTICATION ============

  /// Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    required String role,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username, 'role': role},
    );

    // If signup successful, create user profile
    if (response.user != null) {
      await client.from('users').insert({
        'id': response.user!.id,
        'username': username,
        'email': email,
        'role': role,
        'profile_image_url': '',
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    return response;
  }

  /// Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in with Google using Supabase OAuth.
  static Future<bool> signInWithGoogle() async {
    return await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? Uri.base.origin : _mobileAuthRedirectUrl,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
  }

  /// Ensure OAuth users have a matching row in the app's public users table.
  static Future<void> ensureCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return;

    final existingProfile = await getUserProfile(user.id);
    if (existingProfile != null) return;

    final metadata = user.userMetadata ?? {};
    final email = user.email ?? '';
    final username =
        metadata['name'] as String? ??
        metadata['full_name'] as String? ??
        email.split('@').first;
    final avatarUrl =
        metadata['avatar_url'] as String? ??
        metadata['picture'] as String? ??
        '';

    await client.from('users').insert({
      'id': user.id,
      'username': username,
      'email': email,
      'role': 'user',
      'profile_image_url': avatarUrl,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Sign in with username (convert to email first)
  static Future<AuthResponse> signInWithUsername({
    required String username,
    required String password,
  }) async {
    // First, get the email for this username
    final response = await client
        .from('users')
        .select('email')
        .eq('username', username)
        .single();

    final email = response['email'] as String;

    return await signIn(email: email, password: password);
  }

  /// Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Reset password
  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  /// Get current user
  static User? get currentUser => client.auth.currentUser;

  /// Check if user is signed in
  static bool get isSignedIn => currentUser != null;

  // ============ DATABASE OPERATIONS ============

  /// Get user profile
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Update user profile
  static Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await client
        .from('users')
        .update({...data, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', userId);
  }

  /// Create or update user profile
  static Future<void> upsertUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await client.from('users').upsert({
      'id': userId,
      ...data,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ============ CAMPAIGNS ============

  /// Create campaign
  static Future<String> createCampaign({
    required String location,
    required String date,
    required String time,
    required String description,
    List<String> mediaUrls = const [],
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await client
        .from('campaigns')
        .insert({
          'location': location,
          'date': date,
          'time': time,
          'description': description,
          'media_urls': mediaUrls,
          'created_by': user.id,
          'created_at': DateTime.now().toIso8601String(),
          'status': 'active',
          'likes': 0,
          'comments': [],
          'registrations': [],
          'registration_count': 0,
        })
        .select()
        .single();

    return response['id'] as String;
  }

  /// Get campaigns stream
  static Stream<List<Map<String, dynamic>>> getCampaignsStream() {
    return client
        .from('campaigns')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  /// Get campaigns by user
  static Stream<List<Map<String, dynamic>>> getUserCampaignsStream(
    String userId,
  ) {
    return client
        .from('campaigns')
        .stream(primaryKey: ['id'])
        .eq('created_by', userId)
        .order('created_at', ascending: false);
  }

  /// Update campaign
  static Future<void> updateCampaign(
    String campaignId,
    Map<String, dynamic> data,
  ) async {
    await client
        .from('campaigns')
        .update({...data, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', campaignId);
  }

  /// Delete campaign
  static Future<void> deleteCampaign(String campaignId) async {
    await client.from('campaigns').delete().eq('id', campaignId);
  }

  /// Register for campaign
  static Future<void> registerForCampaign(
    String campaignId,
    Map<String, dynamic> userDetails,
  ) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get current campaign data
    final campaign = await client
        .from('campaigns')
        .select()
        .eq('id', campaignId)
        .single();

    List<dynamic> registrations = campaign['registrations'] ?? [];
    Map<String, dynamic> registrationDetails =
        campaign['registration_details'] ?? {};

    // Add user to registrations
    if (!registrations.contains(user.id)) {
      registrations.add(user.id);

      // Add timestamp and event info to registration details
      registrationDetails[user.id] = {
        ...userDetails,
        'registeredAt': DateTime.now().toIso8601String(),
        'eventId': campaignId,
        'eventLocation': campaign['location'] ?? 'Unknown Location',
        'eventDate': campaign['date'] ?? 'Unknown Date',
        'eventTime': campaign['time'] ?? 'Unknown Time',
        'registrationStatus': 'registered',
      };

      await client
          .from('campaigns')
          .update({
            'registrations': registrations,
            'registration_count': registrations.length,
            'registration_details': registrationDetails,
          })
          .eq('id', campaignId);
    }
  }

  /// Unregister from campaign
  static Future<void> unregisterFromCampaign(String campaignId) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get current campaign data
    final campaign = await client
        .from('campaigns')
        .select()
        .eq('id', campaignId)
        .single();

    List<dynamic> registrations = campaign['registrations'] ?? [];
    Map<String, dynamic> registrationDetails =
        campaign['registration_details'] ?? {};

    // Remove user from registrations
    registrations.remove(user.id);
    registrationDetails.remove(user.id);

    await client
        .from('campaigns')
        .update({
          'registrations': registrations,
          'registration_count': registrations.length,
          'registration_details': registrationDetails,
        })
        .eq('id', campaignId);
  }

  // ============ WASTE REQUESTS ============
  ///// Create waste report

  static Future<void> createWasteReport({
    required String location,
    required String phone,
    required DateTime pickupTime,
    required String description,
    List<String> imageUrls = const [],
  }) async {
    final user = currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    String username = 'Anonymous';
    String profileImageUrl = '';

    try {
      // FETCH USER DATA
      final profile = await client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      username =
          profile['username'] ?? user.email?.split('@')[0] ?? 'Anonymous';

      profileImageUrl = profile['profile_image_url'] ?? '';
    } catch (e) {
      username = user.email?.split('@')[0] ?? 'Anonymous';
    }

    await client.from('waste_requests').insert({
      'location': location,

      'phone': phone,

      'pickup_time': pickupTime.toIso8601String(),

      'description': description,

      'image_urls': imageUrls,

      'created_by': user.id,

      // IMPORTANT
      'posted_by': username,

      // IMPORTANT
      'profile_image_url': profileImageUrl,

      'status': 'open',

      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Create waste request
  static Future<void> createWasteRequest({
    required String location,
    required String phone,
    required String amount,
    required String pickupTime,
    required String description,
    String? wasteType,
    List<String> imageUrls = const [],
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    final userProfile = await getUserProfile(user.id);
    final username = userProfile?['username'] ?? user.email ?? 'Anonymous';
    final profileImageUrl = userProfile?['profile_image_url'] ?? '';

    final pickupDateTime = DateTime.now().add(const Duration(hours: 2));

    await client.from('waste_requests').insert({
      'location': location,
      'phone': phone,
      'amount': amount,
      'pickup_time': pickupDateTime.toIso8601String(),
      'description': description,
      'waste_type': wasteType,
      'image_urls': imageUrls,
      'created_by': user.id,
      'posted_by': username,
      'profile_image_url': profileImageUrl,
      'status': 'open',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get waste requests stream
  static Stream<List<Map<String, dynamic>>> getWasteRequestsStream() {
    return client
        .from('waste_requests')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  /// Get user waste requests stream
  static Stream<List<Map<String, dynamic>>> getUserWasteRequestsStream(
    String userId,
  ) {
    return client
        .from('waste_requests')
        .stream(primaryKey: ['id'])
        .eq('created_by', userId)
        .order('created_at', ascending: false);
  }

  /// Update waste request
  static Future<void> updateWasteRequest(
    String requestId,
    Map<String, dynamic> data,
  ) async {
    await client.from('waste_requests').update(data).eq('id', requestId);
  }

  /// Accept waste request
  static Future<void> acceptWasteRequest(
    String requestId,
    String acceptedByName,
  ) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    await client
        .from('waste_requests')
        .update({
          'status': 'taken',
          'accepted_by': user.id,
          'accepted_by_name': acceptedByName,
        })
        .eq('id', requestId);
  }

  // ============ HYSACAM REPORTS ============

  /// Get hysacam reports stream by location
  static Stream<List<Map<String, dynamic>>> getHysacamReportsByLocation(
    String location,
  ) {
    return client
        .from('hysacam_reports')
        .stream(primaryKey: ['id'])
        .eq('location', location)
        .order('created_at', ascending: false);
  }

  /// Mark hysacam report as done
  static Future<void> markHysacamReportAsDone(String reportId) async {
    await client
        .from('hysacam_reports')
        .update({'status': 'done'})
        .eq('id', reportId);
  }

  // ============ PATROL SCHEDULE ============

  /// Create patrol schedule
  static Future<void> createPatrolSchedule({
    required String location,
    required String date,
    required String time,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    await client.from('patrol_schedule').insert({
      'location': location,
      'date': date,
      'time': time,
      'created_by': user.id,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get patrol schedule stream
  static Stream<List<Map<String, dynamic>>> getPatrolScheduleStream() {
    return client
        .from('patrol_schedule')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  /// Delete patrol schedule
  static Future<void> deletePatrolSchedule(String scheduleId) async {
    await client.from('patrol_schedule').delete().eq('id', scheduleId);
  }

  // ============ FILE STORAGE ============

  /// Upload image to Supabase Storage
  static Future<String> uploadImage({
    required dynamic imageData, // Can be File, Uint8List, or XFile
    required String bucket,
    String? folder,
    String? fileName,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    Uint8List bytes;
    String fileExt = 'jpg';

    if (imageData is XFile) {
      bytes = await imageData.readAsBytes();
      fileExt = imageData.path.split('.').last;
    } else if (imageData is File) {
      bytes = await imageData.readAsBytes();
      fileExt = imageData.path.split('.').last;
    } else if (imageData is Uint8List) {
      bytes = imageData;
    } else {
      throw Exception('Unsupported image data type');
    }

    final finalFileName =
        fileName ?? '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = folder != null ? '$folder/$finalFileName' : finalFileName;

    await client.storage
        .from(bucket)
        .uploadBinary(
          filePath,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$fileExt', upsert: true),
        );

    // Get public URL
    final publicUrl = client.storage.from(bucket).getPublicUrl(filePath);
    return publicUrl;
  }

  /// Upload multiple images
  static Future<List<String>> uploadMultipleImages({
    required List<dynamic> imageDataList,
    required String bucket,
    String? folder,
  }) async {
    final List<String> urls = [];

    for (final imageData in imageDataList) {
      final url = await uploadImage(
        imageData: imageData,
        bucket: bucket,
        folder: folder,
      );
      urls.add(url);
    }

    return urls;
  }

  /// Delete image from storage
  static Future<void> deleteImage({
    required String bucket,
    required String filePath,
  }) async {
    await client.storage.from(bucket).remove([filePath]);
  }

  // ============ SCHEDULED POSTS ============

  /// Schedule a post
  static Future<void> schedulePost({
    required String location,
    required String wasteType,
    required String description,
    required List<String> imageUrls,
    required DateTime scheduledTime,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    await client.from('scheduled_posts').insert({
      'user_id': user.id,
      'location': location,
      'waste_type': wasteType,
      'description': description,
      'image_urls': imageUrls,
      'scheduled_time': scheduledTime.toIso8601String(),
      'status': 'pending',
    });
  }

  /// Get user's scheduled posts
  static Stream<List<Map<String, dynamic>>> getScheduledPostsStream() {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    return client
        .from('scheduled_posts')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('scheduled_time', ascending: true);
  }

  /// Cancel scheduled post
  static Future<void> cancelScheduledPost(String postId) async {
    await client
        .from('scheduled_posts')
        .update({'status': 'cancelled'})
        .eq('id', postId);
  }

  /// Delete scheduled post
  static Future<void> deleteScheduledPost(String postId) async {
    await client.from('scheduled_posts').delete().eq('id', postId);
  }
}
