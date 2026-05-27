import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';
import '../utils/theme_helper.dart';

class ReportWasteForm extends StatefulWidget {
  const ReportWasteForm({super.key});

  @override
  State<ReportWasteForm> createState() => _ReportWasteFormState();
}

class _ReportWasteFormState extends State<ReportWasteForm> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedLocation;
  final List<String> _locations = [
    'Mile 17',
    'OIC',
    'Bokwaongo Market',
    'Before John Chi',
    'Molyko',
    'Great Soppo',
  ];
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  File? _selectedFile;
  Uint8List? _webImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file == null) return;
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      setState(() { _webImage = bytes; _selectedFile = null; });
    } else {
      setState(() { _selectedFile = File(file.path); _webImage = null; });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      _showSnackBar("Please select a location");
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      _showSnackBar("Please select pickup date and time");
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> imageUrls = [];
      if (_selectedFile != null || _webImage != null) {
        final url = await SupabaseService.uploadImage(
          imageData: kIsWeb ? _webImage! : _selectedFile!,
          bucket: 'waste-images',
          folder: 'reports',
        );
        imageUrls = [url];
      }

      final user = SupabaseService.currentUser;
      final profile = user != null
          ? await SupabaseService.getUserProfile(user.id)
          : null;
      final username = profile?['username'] ?? user?.email ?? 'Anonymous';

      await SupabaseService.client.from('hysacam_reports').insert({
        'location': _selectedLocation!,
        'phone': _phoneController.text.trim(),
        'pickup_time': DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        ).toIso8601String(),
        'description': _descriptionController.text.trim(),
        'image_urls': imageUrls,
        'reported_by': username,
        'created_by': user?.id ?? '',
        'status': 'open',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context);
        _showSnackBar("Waste report submitted successfully!");
      }
    } catch (e) {
      _showSnackBar("Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF4CAF50)),
          ),
          child: child!,
        );
      },
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF4CAF50)),
          ),
          child: child!,
        );
      },
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeHelper.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        title: const Text("Report Waste", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 20,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
            Text(
              "Fill in the details below",
              style: TextStyle(fontSize: 14, color: ThemeHelper.getSecondaryTextColor(context)),
            ),
            const SizedBox(height: 20),

            // Location Dropdown
            DropdownButtonFormField<String>(
              value: _selectedLocation,
              isExpanded: true,
              dropdownColor: ThemeHelper.getCardColor(context),
              validator: (v) => v == null ? "Location is required" : null,
              items: _locations
                  .map((loc) => DropdownMenuItem(
                        value: loc,
                        child: Text(loc, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedLocation = value),
              decoration: _inputDecoration(
                label: "Location",
                icon: Icons.location_on,
                hint: "Select waste location",
              ),
            ),
            const SizedBox(height: 14),

            // Phone
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: (v) => v == null || v.trim().isEmpty ? "Phone number is required" : null,
              decoration: _inputDecoration(
                label: "Phone Number",
                icon: Icons.phone,
                hint: "Your contact number",
              ),
            ),
            const SizedBox(height: 14),

            // Pickup Date & Time
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: _inputDecoration(
                          label: _selectedDate == null
                              ? "Pickup Date"
                              : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                          icon: Icons.calendar_today,
                          hint: "Select date",
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickTime,
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: _inputDecoration(
                          label: _selectedTime == null
                              ? "Pickup Time"
                              : _selectedTime!.format(context),
                          icon: Icons.access_time,
                          hint: "Select time",
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: _inputDecoration(
                label: "Description",
                icon: Icons.description,
                hint: "Additional details about the waste...",
              ),
            ),
            const SizedBox(height: 20),

            // Image Upload
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ThemeHelper.getSurfaceColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ThemeHelper.getBorderColor(context), width: 2),
                ),
                child: _selectedFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_selectedFile!, height: 150, width: double.infinity, fit: BoxFit.cover),
                      )
                    : _webImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(_webImage!, height: 150, width: double.infinity, fit: BoxFit.cover),
                          )
                        : Column(
                            children: [
                              Icon(Icons.cloud_upload_outlined, size: 48, color: ThemeHelper.getSecondaryTextColor(context)),
                              const SizedBox(height: 8),
                              Text(
                                "Upload Image",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ThemeHelper.getTextColor(context)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Tap to select a photo",
                                style: TextStyle(fontSize: 12, color: ThemeHelper.getSecondaryTextColor(context)),
                              ),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        "Report Waste",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
              ),
            ),
          ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w500),
      hintStyle: TextStyle(color: ThemeHelper.getSecondaryTextColor(context), fontSize: 13),
      prefixIcon: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF4CAF50), size: 18),
      ),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }
}
