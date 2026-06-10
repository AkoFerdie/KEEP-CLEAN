import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import '../services/supabase_service.dart';
import '../utils/theme_helper.dart';
import 'signin_page.dart';
import 'getting_started_page.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _publicProfile = true;
  bool _anonymousReporting = false;
  bool _hideLocation = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _publicProfile = prefs.getBool('privacy_public_profile') ?? true;
        _anonymousReporting = prefs.getBool('privacy_anonymous_reporting') ?? false;
        _hideLocation = prefs.getBool('privacy_hide_location') ?? false;
      });
    }
  }

  Future<void> _saveToggle(String key, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('Delete Account', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'This will permanently delete your account and all your data including reports, campaigns and activity. This action cannot be undone.',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
        ),
      );

      // Delete everything via a single secure RPC call
      await SupabaseService.client.rpc('delete_user');

      // Sign out
      await SupabaseService.signOut();

      if (!mounted) return;
      Navigator.pop(context); // close loading
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const GettingStartedPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loading
      _showSnack('Failed to delete account: ${e.toString()}');
    }
  }

  void _showDataDownloadInfo() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
      ),
    );

    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('Not signed in');

      // Fetch all user data
      final profile = await SupabaseService.getUserProfile(user.id);
      final wasteRequests = await SupabaseService.client
          .from('waste_requests')
          .select()
          .eq('created_by', user.id);
      final campaigns = await SupabaseService.client
          .from('campaigns')
          .select()
          .eq('created_by', user.id);

      // Build data map
      final data = {
        'exported_at': DateTime.now().toIso8601String(),
        'profile': profile,
        'waste_requests': wasteRequests,
        'campaigns': campaigns,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      if (!mounted) return;
      Navigator.pop(context); // close loading

      if (kIsWeb) {
        // Build professional HTML document
        final profile = data['profile'] as Map<String, dynamic>? ?? {};
        final wasteRequests = data['waste_requests'] as List? ?? [];
        final campaigns = data['campaigns'] as List? ?? [];
        final exportDate = DateTime.now();

        final html = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Keep It Clean - My Data Export</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: Arial, sans-serif; background: #f4faf4; color: #333; }
    .header { background: linear-gradient(135deg, #4CAF50, #2E7D32); color: white; padding: 32px 40px; }
    .header h1 { font-size: 28px; font-weight: bold; }
    .header p { font-size: 13px; opacity: 0.85; margin-top: 4px; }
    .badge { background: rgba(255,255,255,0.2); border-radius: 20px; padding: 4px 14px; font-size: 12px; display: inline-block; margin-top: 8px; }
    .container { max-width: 860px; margin: 30px auto; padding: 0 20px 40px; }
    .section { background: white; border-radius: 14px; box-shadow: 0 2px 10px rgba(0,0,0,0.07); margin-bottom: 24px; overflow: hidden; }
    .section-title { background: #4CAF50; color: white; padding: 14px 20px; font-size: 15px; font-weight: bold; }
    .section-body { padding: 20px; }
    .row { display: flex; padding: 10px 0; border-bottom: 1px solid #f0f0f0; }
    .row:last-child { border-bottom: none; }
    .label { font-weight: 600; color: #555; min-width: 180px; font-size: 13px; }
    .value { color: #333; font-size: 13px; }
    .card { background: #f9f9f9; border-radius: 10px; padding: 14px; margin-bottom: 12px; border-left: 4px solid #4CAF50; }
    .card:last-child { margin-bottom: 0; }
    .card h3 { font-size: 14px; color: #2E7D32; margin-bottom: 6px; }
    .card p { font-size: 12px; color: #666; margin: 2px 0; }
    .empty { color: #aaa; font-size: 13px; text-align: center; padding: 20px; }
    .footer { text-align: center; color: #aaa; font-size: 11px; margin-top: 30px; padding-bottom: 20px; }
    .meta { display: flex; justify-content: space-between; flex-wrap: wrap; gap: 8px; background: white; border-radius: 10px; padding: 14px 20px; margin-bottom: 24px; box-shadow: 0 2px 8px rgba(0,0,0,0.06); font-size: 12px; color: #666; }
    .meta span { background: #f4faf4; padding: 4px 10px; border-radius: 8px; }
  </style>
</head>
<body>
  <div class="header">
    <h1>Keep It Clean</h1>
    <p>Personal Data Export</p>
    <span class="badge">Generated on ${exportDate.day}/${exportDate.month}/${exportDate.year} at ${exportDate.hour.toString().padLeft(2,'0')}:${exportDate.minute.toString().padLeft(2,'0')}</span>
  </div>
  <div class="container">
    <div class="meta">
      <span>Email: ${profile['email'] ?? 'N/A'}</span>
      <span>Username: ${profile['username'] ?? 'N/A'}</span>
      <span>Role: ${profile['role'] ?? 'User'}</span>
      <span>Member since: ${profile['created_at']?.toString().substring(0, 10) ?? 'N/A'}</span>
    </div>

    <div class="section">
      <div class="section-title">Profile Information</div>
      <div class="section-body">
        <div class="row"><span class="label">Username</span><span class="value">${profile['username'] ?? 'N/A'}</span></div>
        <div class="row"><span class="label">Email</span><span class="value">${profile['email'] ?? 'N/A'}</span></div>
        <div class="row"><span class="label">Role</span><span class="value">${profile['role'] ?? 'User'}</span></div>
        <div class="row"><span class="label">Phone</span><span class="value">${profile['phone'] ?? 'N/A'}</span></div>
        <div class="row"><span class="label">Bio</span><span class="value">${profile['bio'] ?? 'N/A'}</span></div>
        <div class="row"><span class="label">Account Created</span><span class="value">${profile['created_at']?.toString().substring(0, 10) ?? 'N/A'}</span></div>
      </div>
    </div>

    <div class="section">
      <div class="section-title">Waste Pickup Requests (${wasteRequests.length})</div>
      <div class="section-body">
        ${wasteRequests.isEmpty ? '<p class="empty">No waste requests found</p>' : wasteRequests.map((r) => '''
        <div class="card">
          <h3>Location: ${r['location'] ?? 'Unknown Location'}</h3>
          <p>Status: ${r['status'] ?? 'N/A'} &nbsp;|&nbsp; Amount: ${r['amount'] ?? '0'} FCFA</p>
          <p>Type: ${r['waste_type'] ?? 'N/A'} &nbsp;|&nbsp; Phone: ${r['phone'] ?? 'N/A'}</p>
          <p>Posted: ${r['created_at']?.toString().substring(0, 10) ?? 'N/A'}</p>
        </div>''').join('')}
      </div>
    </div>

    <div class="section">
      <div class="section-title">Campaigns Created (${campaigns.length})</div>
      <div class="section-body">
        ${campaigns.isEmpty ? '<p class="empty">No campaigns found</p>' : campaigns.map((c) => '''
        <div class="card">
          <h3>Location: ${c['location'] ?? 'Unknown Location'}</h3>
          <p>Date: ${c['date'] ?? 'N/A'} at ${c['time'] ?? 'N/A'}</p>
          <p>Status: ${c['status'] ?? 'N/A'} &nbsp;|&nbsp; Registrations: ${c['registration_count'] ?? 0}</p>
          <p>Description: ${c['description'] ?? 'N/A'}</p>
        </div>''').join('')}
      </div>
    </div>

    <div class="footer">
      This document was generated by Keep It Clean &copy; ${exportDate.year}. All data belongs to you.
    </div>
  </div>
</body>
</html>''';

        final bytes = utf8.encode(html);
        final blob = web.Blob(
          [bytes.toJS].toJS,
          web.BlobPropertyBag(type: 'text/html'),
        );
        final url = web.URL.createObjectURL(blob);
        final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
        anchor.href = url;
        anchor.download = 'keep_it_clean_data_${exportDate.year}${exportDate.month}${exportDate.day}.html';
        anchor.click();
        web.URL.revokeObjectURL(url);
        if (!mounted) return;
        _showSnack('Download started! Open the file in your browser.');
      } else {
        _showDataDialog(jsonString);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack('Failed to fetch data. Please try again.');
    }
  }

  void _showDataDialog(String jsonData) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.download_done_rounded, color: Color(0xFF4CAF50), size: 22),
            SizedBox(width: 8),
            Text('Your Data', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 320,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your data has been fetched. Tap Copy to save it.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      jsonData,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonData));
              Navigator.pop(ctx);
              _showSnack('Data copied to clipboard!');
            },
            icon: const Icon(Icons.copy, size: 16, color: Colors.white),
            label: const Text('Copy', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Privacy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Profile Privacy ──
          _sectionLabel('Profile Privacy'),
          _buildCard([
            _buildToggleTile(
              Icons.person_outline,
              'Public Profile',
              _publicProfile ? 'Your profile is visible to everyone' : 'Your profile is private',
              _publicProfile,
              (val) {
                setState(() => _publicProfile = val);
                _saveToggle('privacy_public_profile', val);
                _showSnack(val ? 'Profile set to public' : 'Profile set to private');
              },
              iconColor: Colors.blue,
            ),
            Divider(height: 1, indent: 56, color: ThemeHelper.getBorderColor(context)),
            _buildToggleTile(
              Icons.location_off_outlined,
              'Hide Exact Location',
              _hideLocation ? 'Showing area only on reports' : 'Exact location shown on reports',
              _hideLocation,
              (val) {
                setState(() => _hideLocation = val);
                _saveToggle('privacy_hide_location', val);
                _showSnack(val ? 'Location hidden on reports' : 'Exact location enabled');
              },
              iconColor: Colors.orange,
            ),
          ]),

          const SizedBox(height: 20),

          // ── Reporting Privacy ──
          _sectionLabel('Reporting Privacy'),
          _buildCard([
            _buildToggleTile(
              Icons.visibility_off_outlined,
              'Anonymous Reporting',
              _anonymousReporting ? 'Your name is hidden on posts' : 'Your name is shown on posts',
              _anonymousReporting,
              (val) {
                setState(() => _anonymousReporting = val);
                _saveToggle('privacy_anonymous_reporting', val);
                _showSnack(val ? 'Anonymous reporting enabled' : 'Anonymous reporting disabled');
              },
              iconColor: Colors.purple,
            ),
          ]),

          const SizedBox(height: 20),

          // ── Data & Account ──
          _sectionLabel('Data & Account'),
          _buildCard([
            _buildArrowTile(
              Icons.download_outlined,
              'Download My Data',
              'Get a copy of your reports & activity',
              _showDataDownloadInfo,
              iconColor: Colors.teal,
            ),
            Divider(height: 1, indent: 56, color: ThemeHelper.getBorderColor(context)),
            _buildArrowTile(
              Icons.delete_forever_outlined,
              'Delete Account',
              'Permanently remove your account',
              _showDeleteAccountDialog,
              isDestructive: true,
            ),
          ]),

          const SizedBox(height: 30),

          // Info note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.2)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xFF4CAF50), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your privacy matters. We never sell your data to third parties. All data is stored securely on our servers.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32), height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: ThemeHelper.getSecondaryTextColor(context),
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Material(
      color: ThemeHelper.getCardColor(context),
      borderRadius: BorderRadius.circular(16),
      shadowColor: Colors.grey.withValues(alpha: 0.15),
      elevation: 2,
      child: Column(children: children),
    );
  }

  Widget _buildToggleTile(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged, {Color? iconColor}) {
    final color = iconColor ?? const Color(0xFF4CAF50);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ThemeHelper.getTextColor(context))),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: ThemeHelper.getSecondaryTextColor(context))),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: color,
      ),
    );
  }

  Widget _buildArrowTile(IconData icon, String title, String subtitle, VoidCallback onTap, {bool isDestructive = false, Color? iconColor}) {
    final color = isDestructive ? Colors.red : (iconColor ?? const Color(0xFF4CAF50));
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDestructive ? Colors.red : ThemeHelper.getTextColor(context))),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: ThemeHelper.getSecondaryTextColor(context))),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: ThemeHelper.getSecondaryTextColor(context).withValues(alpha: 0.7)),
    );
  }
}
