import 'package:flutter/material.dart';
import '../utils/theme_helper.dart';

class TrustedDevicesPage extends StatefulWidget {
  const TrustedDevicesPage({super.key});

  @override
  State<TrustedDevicesPage> createState() => _TrustedDevicesPageState();
}

class _TrustedDevicesPageState extends State<TrustedDevicesPage> {
  // Sample trusted devices (in production, load from database)
  final List<Map<String, dynamic>> _trustedDevices = [
    {
      'id': '1',
      'name': '📱 iPhone 13 Pro',
      'lastActive': '2 hours ago',
      'trustedSince': 'Jan 15, 2024',
      'location': 'Cameroon',
      'isCurrent': true,
    },
    {
      'id': '2',
      'name': '💻 MacBook Air',
      'lastActive': 'Yesterday',
      'trustedSince': 'Jan 10, 2024',
      'location': 'Cameroon',
      'isCurrent': false,
    },
    {
      'id': '3',
      'name': '🖥️ Windows PC',
      'lastActive': '3 days ago',
      'trustedSince': 'Jan 5, 2024',
      'location': 'Cameroon',
      'isCurrent': false,
    },
  ];

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
        title: const Text(
          'Trusted Devices',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Color(0xFF4CAF50),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About Trusted Devices',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ThemeHelper.getTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Skip 2FA on devices you use regularly. Trust expires after 30 days.',
                        style: TextStyle(
                          fontSize: 12,
                          color: ThemeHelper.getSecondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Devices List
          Text(
            'Your Devices',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ThemeHelper.getSecondaryTextColor(context),
            ),
          ),
          const SizedBox(height: 12),

          if (_trustedDevices.isEmpty)
            _buildEmptyState()
          else
            ..._trustedDevices.map((device) => _buildDeviceCard(device)),

          const SizedBox(height: 20),

          // Remove All Button
          if (_trustedDevices.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => _removeAllDevices(),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('Remove All Devices'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: ThemeHelper.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.devices_other,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Trusted Devices',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ThemeHelper.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you trust a device, it will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: ThemeHelper.getSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(Map<String, dynamic> device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeHelper.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: device['isCurrent']
            ? Border.all(color: const Color(0xFF4CAF50), width: 2)
            : null,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          device['name'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: ThemeHelper.getTextColor(context),
                          ),
                        ),
                        if (device['isCurrent']) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Current',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last active: ${device['lastActive']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeHelper.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (!device['isCurrent'])
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeDevice(device['id'], device['name']),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: ThemeHelper.getBorderColor(context)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 16,
                color: ThemeHelper.getSecondaryTextColor(context),
              ),
              const SizedBox(width: 6),
              Text(
                'Trusted since: ${device['trustedSince']}',
                style: TextStyle(
                  fontSize: 12,
                  color: ThemeHelper.getSecondaryTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: ThemeHelper.getSecondaryTextColor(context),
              ),
              const SizedBox(width: 6),
              Text(
                device['location'],
                style: TextStyle(
                  fontSize: 12,
                  color: ThemeHelper.getSecondaryTextColor(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _removeDevice(String deviceId, String deviceName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeHelper.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Remove Device?',
          style: TextStyle(color: ThemeHelper.getTextColor(context)),
        ),
        content: Text(
          'You will need to verify with 2FA next time you sign in from $deviceName.',
          style: TextStyle(color: ThemeHelper.getSecondaryTextColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _trustedDevices.removeWhere((d) => d['id'] == deviceId);
              });
              _showSnack('Device removed from trusted list');
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _removeAllDevices() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeHelper.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Remove All Devices?',
          style: TextStyle(color: ThemeHelper.getTextColor(context)),
        ),
        content: Text(
          'You will need to verify with 2FA on all devices next time you sign in.',
          style: TextStyle(color: ThemeHelper.getSecondaryTextColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _trustedDevices.clear();
              });
              _showSnack('All devices removed from trusted list');
            },
            child: const Text(
              'Remove All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }
}
