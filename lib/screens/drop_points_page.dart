import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';

class DropPointsPage extends StatefulWidget {
  const DropPointsPage({super.key});

  @override
  State<DropPointsPage> createState() => _DropPointsPageState();
}

class _DropPointsPageState extends State<DropPointsPage> {
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  final _searchCtrl = TextEditingController();
  String _selectedType = 'all';

  final _types = ['all', 'bin', 'collection_center', 'skip', 'other'];
  final _typeLabels = {
    'all': 'All',
    'bin': '🗑️ Bin',
    'collection_center': '🏭 Center',
    'skip': '📦 Skip',
    'other': '📍 Other',
  };

  @override
  void initState() {
    super.initState();
    SupabaseService.getDropPointsStream().listen((data) {
      if (mounted) {
        setState(() {
          _all = data;
          _applyFilters();
        });
      }
    });
    _searchCtrl.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilters() {
    var result = List<Map<String, dynamic>>.from(_all);
    if (_selectedType != 'all') {
      result = result.where((d) => d['type'] == _selectedType).toList();
    }
    final q = _searchCtrl.text.toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((d) {
        return (d['name'] ?? '').toString().toLowerCase().contains(q) ||
            (d['area'] ?? '').toString().toLowerCase().contains(q) ||
            (d['address'] ?? '').toString().toLowerCase().contains(q);
      }).toList();
    }
    setState(() => _filtered = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Waste Drop Points',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white),
            onPressed: () => _showAddDialog(context),
            tooltip: 'Add drop point',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search + filter bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by name, area or address...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF4CAF50)),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => _searchCtrl.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _types.map((t) {
                      final selected = _selectedType == t;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedType = t;
                          _applyFilters();
                        }),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF4CAF50)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _typeLabels[t] ?? t,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : Colors.grey[700],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off_outlined,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('No drop points found',
                            style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 15,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text('Be the first to add one!',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 13)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showAddDialog(context),
                          icon: const Icon(Icons.add_location_alt_outlined,
                              color: Colors.white, size: 18),
                          label: const Text('Add Drop Point',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _DropPointCard(data: _filtered[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: _filtered.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showAddDialog(context),
              backgroundColor: const Color(0xFF4CAF50),
              icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white),
              label: const Text('Add Point',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddDropPointSheet(),
    );
  }
}

// ─────────────────────────────────────────────
// Drop Point Card
// ─────────────────────────────────────────────
class _DropPointCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DropPointCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final type = data['type'] ?? 'bin';
    final isVerified = data['is_verified'] == true;
    final isOwner = SupabaseService.currentUser?.id == data['added_by'];

    final typeIcon = type == 'collection_center'
        ? Icons.factory_outlined
        : type == 'skip'
            ? Icons.inbox_outlined
            : Icons.delete_outline;

    final typeColor = type == 'collection_center'
        ? const Color(0xFF1E88E5)
        : type == 'skip'
            ? const Color(0xFFFF9800)
            : const Color(0xFF4CAF50);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(typeIcon, color: typeColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['name'] ?? 'Unknown',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                      if (isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('✅ Official',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                      if (isOwner) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _showEditSheet(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.edit_outlined,
                                color: Color(0xFF4CAF50), size: 16),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 13, color: Colors.grey[500]),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${data['area'] ?? ''} · ${data['address'] ?? ''}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if ((data['description'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      data['description'],
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if ((data['photo_url'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        data['photo_url'],
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          type == 'collection_center'
                              ? '🏭 Collection Center'
                              : type == 'skip'
                                  ? '📦 Skip'
                                  : type == 'bin'
                                      ? '🗑️ Bin'
                                      : '📍 Other',
                          style: TextStyle(
                              fontSize: 11,
                              color: typeColor,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Added by ${data['added_by_name'] ?? 'Anonymous'}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditDropPointSheet(data: data),
    );
  }
}

// ─────────────────────────────────────────────
// Add Drop Point Bottom Sheet
// ─────────────────────────────────────────────
class _AddDropPointSheet extends StatefulWidget {
  const _AddDropPointSheet();

  @override
  State<_AddDropPointSheet> createState() => _AddDropPointSheetState();
}

class _AddDropPointSheetState extends State<_AddDropPointSheet> {
  final _nameCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'bin';
  bool _loading = false;
  File? _selectedFile;
  Uint8List? _webImage;

  final _typeOptions = [
    {'value': 'bin', 'label': '🗑️ Waste Bin'},
    {'value': 'collection_center', 'label': '🏭 Collection Center'},
    {'value': 'skip', 'label': '📦 Skip / Dumpster'},
    {'value': 'other', 'label': '📍 Other'},
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _areaCtrl.dispose();
    _addressCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file == null) return;
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      setState(() { _webImage = bytes; _selectedFile = null; });
    } else {
      setState(() { _selectedFile = File(file.path); _webImage = null; });
    }
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _areaCtrl.text.trim().isEmpty ||
        _addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please fill name, area and address.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      String? photoUrl;
      if (_selectedFile != null || _webImage != null) {
        photoUrl = await SupabaseService.uploadImage(
          imageData: kIsWeb ? _webImage! : _selectedFile!,
          bucket: 'waste-images',
          folder: 'drop_points',
        );
      }
      await SupabaseService.addDropPoint(
        name: _nameCtrl.text.trim(),
        area: _areaCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        type: _type,
        description: _descCtrl.text.trim(),
        photoUrl: photoUrl,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Drop point added! Thank you.'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Add Waste Drop Point',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50))),
              const SizedBox(height: 4),
              Text('Help others find where to dispose their waste.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 16),

              _field(_nameCtrl, 'Location Name', 'e.g. Bastos Bin near Total station', Icons.location_on_outlined),
              const SizedBox(height: 12),
              _field(_areaCtrl, 'Area / Neighborhood', 'e.g. Bastos, Yaoundé', Icons.map_outlined),
              const SizedBox(height: 12),
              _field(_addressCtrl, 'Street / Landmark', 'e.g. Opposite Shell filling station', Icons.signpost_outlined),
              const SizedBox(height: 12),

              // Type selector
              const Text('Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4CAF50))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _typeOptions.map((opt) {
                  final selected = _type == opt['value'];
                  return GestureDetector(
                    onTap: () => setState(() => _type = opt['value']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF4CAF50)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF4CAF50)
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        opt['label']!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              _field(_descCtrl, 'Description (optional)',
                  'Any extra info, opening hours, etc.', Icons.info_outline,
                  maxLines: 2),
              const SizedBox(height: 16),

              // Photo upload (optional)
              const Text('Photo (optional)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4CAF50))),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: _webImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_webImage!, fit: BoxFit.cover, width: double.infinity),
                        )
                      : _selectedFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_selectedFile!, fit: BoxFit.cover, width: double.infinity),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add_a_photo_outlined,
                                      color: Color(0xFF4CAF50), size: 28),
                                ),
                                const SizedBox(height: 8),
                                const Text('Tap to add a photo',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
                                const SizedBox(height: 2),
                                Text('Helps users identify the location',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                              ],
                            ),
                ),
              ),
              if (_webImage != null || _selectedFile != null) ...[  
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => setState(() { _webImage = null; _selectedFile = null; }),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, size: 14, color: Colors.redAccent),
                      SizedBox(width: 4),
                      Text('Remove photo', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.add_location_alt_outlined, color: Colors.white, size: 20),
                  label: Text(
                    _loading ? 'Adding...' : 'Add Drop Point',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint,
      IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Colors.black38),
        labelStyle: const TextStyle(color: Color(0xFF4CAF50), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Edit Drop Point Sheet
// ─────────────────────────────────────────────
class _EditDropPointSheet extends StatefulWidget {
  final Map<String, dynamic> data;
  const _EditDropPointSheet({required this.data});

  @override
  State<_EditDropPointSheet> createState() => _EditDropPointSheetState();
}

class _EditDropPointSheetState extends State<_EditDropPointSheet> {
  late final TextEditingController _descCtrl;
  File? _selectedFile;
  Uint8List? _webImage;
  bool _loading = false;
  String? _existingPhotoUrl;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.data['description'] ?? '');
    _existingPhotoUrl = widget.data['photo_url']?.toString();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file == null) return;
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      setState(() { _webImage = bytes; _selectedFile = null; });
    } else {
      setState(() { _selectedFile = File(file.path); _webImage = null; });
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      String? photoUrl = _existingPhotoUrl;
      if (_selectedFile != null || _webImage != null) {
        photoUrl = await SupabaseService.uploadImage(
          imageData: kIsWeb ? _webImage! : _selectedFile!,
          bucket: 'waste-images',
          folder: 'drop_points',
        );
      }
      await SupabaseService.client.from('drop_points').update({
        'description': _descCtrl.text.trim(),
        'photo_url': photoUrl,
      }).eq('id', widget.data['id']);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Drop point updated!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Edit Drop Point',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50))),
              const SizedBox(height: 4),
              Text('Update the photo or description.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 16),

              // Description
              TextField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  labelStyle: const TextStyle(color: Color(0xFF4CAF50), fontSize: 13),
                  prefixIcon: const Icon(Icons.info_outline, color: Color(0xFF4CAF50), size: 20),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),

              // Photo
              const Text('Photo',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4CAF50))),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.35),
                        width: 1.5),
                  ),
                  child: _webImage != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_webImage!, fit: BoxFit.cover, width: double.infinity))
                      : _selectedFile != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_selectedFile!, fit: BoxFit.cover, width: double.infinity))
                          : _existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty
                              ? Stack(
                                  children: [
                                    ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_existingPhotoUrl!, fit: BoxFit.cover, width: double.infinity, height: 140)),
                                    Positioned(
                                      bottom: 8, right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                                        child: const Text('Tap to change', style: TextStyle(color: Colors.white, fontSize: 11)),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.add_a_photo_outlined, color: Color(0xFF4CAF50), size: 28),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text('Tap to add a photo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
                                  ],
                                ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _save,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_outlined, color: Colors.white, size: 20),
                  label: Text(
                    _loading ? 'Saving...' : 'Save Changes',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
