import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/supabase_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();

  List<Map<String, dynamic>> _wasteRequests = [];
  List<Map<String, dynamic>> _patrols = [];
  List<Map<String, dynamic>> _events = [];

  final LatLng _center = const LatLng(3.8480, 11.5021); // Yaoundé
  LatLng? _userLocation;
  bool _loading = true;

  // Filter toggles
  bool _showWaste = true;
  bool _showPatrols = true;
  bool _showEvents = true;

  Map<String, dynamic>? _selectedMarker;

  // Approximate lat/lng for known Yaoundé areas
  static const Map<String, LatLng> _locationCoords = {
    'bastos': LatLng(3.8750, 11.5167),
    'nlongkak': LatLng(3.8700, 11.5100),
    'melen': LatLng(3.8550, 11.5200),
    'mvog-mbi': LatLng(3.8400, 11.5050),
    'biyem-assi': LatLng(3.8200, 11.4900),
    'mendong': LatLng(3.8100, 11.4800),
    'nkol-eton': LatLng(3.8600, 11.5300),
    'essos': LatLng(3.8650, 11.5250),
    'omnisport': LatLng(3.8830, 11.5060),
    'centre ville': LatLng(3.8667, 11.5167),
    'center': LatLng(3.8667, 11.5167),
    'ekounou': LatLng(3.8300, 11.5100),
    'obili': LatLng(3.8580, 11.4950),
    'ngousso': LatLng(3.8750, 11.5300),
    'nkolbisson': LatLng(3.9000, 11.4700),
    'mfandena': LatLng(3.8720, 11.5180),
    'mvog ada': LatLng(3.8450, 11.5150),
  };

  LatLng _resolveLocation(String? location) {
    if (location == null || location.isEmpty) return _center;
    final lower = location.toLowerCase();
    for (final entry in _locationCoords.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    // Add slight random offset so markers don't stack
    final offset = (_wasteRequests.length + _patrols.length + _events.length) * 0.001;
    return LatLng(_center.latitude + offset, _center.longitude + offset);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    // Don't request GPS on init - only load data
  }

  Future<void> _getUserLocation() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
        _mapController.move(_userLocation!, 13);
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      SupabaseService.client.from('waste_requests').select('location, status, amount, posted_by, description').limit(30),
      SupabaseService.client.from('patrol_schedules').select('location, date, time').limit(30),
      SupabaseService.client.from('campaigns').select('location, date, status, description').limit(30),
    ]);

    if (mounted) {
      setState(() {
        _wasteRequests = List<Map<String, dynamic>>.from(results[0]);
        _patrols = List<Map<String, dynamic>>.from(results[1]);
        _events = List<Map<String, dynamic>>.from(results[2]);
        _loading = false;
      });
    }
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    if (_showWaste) {
      for (final r in _wasteRequests) {
        final pos = _resolveLocation(r['location']);
        final color = r['status'] == 'open'
            ? const Color(0xFF1E88E5)
            : r['status'] == 'taken'
                ? Colors.orange
                : Colors.green;
        markers.add(_buildMarker(pos, color, Icons.delete_outline, r, 'waste'));
      }
    }

    if (_showPatrols) {
      for (final p in _patrols) {
        final pos = _resolveLocation(p['location']);
        markers.add(_buildMarker(pos, const Color(0xFF4CAF50), Icons.local_shipping_outlined, p, 'patrol'));
      }
    }

    if (_showEvents) {
      for (final e in _events) {
        final pos = _resolveLocation(e['location']);
        markers.add(_buildMarker(pos, Colors.orange, Icons.campaign_outlined, e, 'event'));
      }
    }

    if (_userLocation != null) {
      markers.add(Marker(
        point: _userLocation!,
        width: 40, height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.4), blurRadius: 8)],
          ),
          child: const Icon(Icons.my_location, color: Colors.white, size: 20),
        ),
      ));
    }

    return markers;
  }

  Marker _buildMarker(LatLng pos, Color color, IconData icon, Map<String, dynamic> data, String type) {
    return Marker(
      point: pos,
      width: 42, height: 42,
      child: GestureDetector(
        onTap: () => setState(() => _selectedMarker = {...data, '_type': type}),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.white),
            onPressed: () {
              if (_userLocation != null) {
                _mapController.move(_userLocation!, 14);
              } else {
                _getUserLocation();
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : Stack(
              children: [
                // ── Map ──
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 12,
                    onTap: (_, _) => setState(() => _selectedMarker = null),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.keep_it_clean.app',
                    ),
                    MarkerLayer(markers: _buildMarkers()),
                  ],
                ),

                // ── Filter chips ──
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      _filterChip('🗑️ Waste', _showWaste, const Color(0xFF1E88E5), () => setState(() => _showWaste = !_showWaste)),
                      const SizedBox(width: 6),
                      _filterChip('🚛 Patrols', _showPatrols, const Color(0xFF4CAF50), () => setState(() => _showPatrols = !_showPatrols)),
                      const SizedBox(width: 6),
                      _filterChip('📍 Events', _showEvents, Colors.orange, () => setState(() => _showEvents = !_showEvents)),
                    ],
                  ),
                ),

                // ── Legend ──
                Positioned(
                  bottom: _selectedMarker != null ? 180 : 20,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _legendItem(Colors.blue, '🔵 Waste (Open)'),
                        _legendItem(Colors.orange, '🟠 Waste (Taken)'),
                        _legendItem(Colors.green, '🟢 Patrol'),
                        _legendItem(Colors.deepOrange, '📍 Event'),
                      ],
                    ),
                  ),
                ),

                // ── Selected marker info card ──
                if (_selectedMarker != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: _buildInfoCard(_selectedMarker!),
                  ),
              ],
            ),
    );
  }

  Widget _filterChip(String label, bool active, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4)],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87)),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> data) {
    final type = data['_type'];
    Color color;
    IconData icon;
    String title;
    String subtitle;

    if (type == 'waste') {
      color = data['status'] == 'open' ? const Color(0xFF1E88E5) : Colors.orange;
      icon = Icons.delete_outline;
      title = data['location'] ?? 'Unknown';
      subtitle = '${(data['status'] ?? 'open').toString().toUpperCase()} · ${data['amount'] ?? '0'} FCFA · by ${data['posted_by'] ?? 'Anonymous'}';
    } else if (type == 'patrol') {
      color = const Color(0xFF4CAF50);
      icon = Icons.local_shipping_outlined;
      title = data['location'] ?? 'Unknown';
      subtitle = '${data['date'] ?? ''} at ${data['time'] ?? ''}';
    } else {
      color = Colors.orange;
      icon = Icons.campaign_outlined;
      title = data['location'] ?? 'Unknown';
      subtitle = data['date'] ?? '';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
                if ((data['description'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(data['description'], style: const TextStyle(fontSize: 11, color: Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
            onPressed: () => setState(() => _selectedMarker = null),
          ),
        ],
      ),
    );
  }
}
