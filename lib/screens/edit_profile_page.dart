import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  String? _selectedRole;
  final List<String> _roles = [
    "User",
    "Organization / Volunteer",
    "Government Company (Hysacam)",
  ];

  bool _isLoading = true;
  bool _isSaving = false;

  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    try {
      final data = await SupabaseService.getUserProfile(user.id);
      
      if (data != null) {
        _usernameController.text = data['username'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _bioController.text = data['bio'] ?? '';
        _selectedRole = data['role'];
        _email = data['email'] ?? user.email ?? '';
      }
    } catch (e) {
      _showSnack('Failed to load profile data');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = SupabaseService.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      await SupabaseService.updateUserProfile(user.id, {
        'username': _usernameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
        'role': _selectedRole,
      });

      if (mounted) {
        _showSnack('Profile updated successfully!');
        Navigator.pop(context, true); // return true so profile page can refresh
      }
    } catch (e) {
      _showSnack('Failed to save: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 4,
        shadowColor: Colors.green.withOpacity(0.4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                    // ── Section: Personal Info ──
                    _sectionLabel('Personal Information'),
                    _buildCard([
                      _buildField(
                        controller: _usernameController,
                        label: 'Username',
                        icon: Icons.person_outline,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Username is required' : null,
                      ),
                      _divider(),
                      _buildReadOnlyField(
                        label: 'Email',
                        value: _email,
                        icon: Icons.email_outlined,
                      ),
                      _divider(),
                      _buildField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // ── Section: Role ──
                    _sectionLabel('Role'),
                    _buildCard([
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: DropdownButtonFormField<String>(
                          value: _selectedRole,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          decoration: InputDecoration(
                            labelText: 'Select Role',
                            labelStyle: const TextStyle(
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.w500),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(10),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF4CAF50).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.account_circle,
                                  color: Color(0xFF4CAF50), size: 18),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          items: _roles
                              .map((r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(r,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14)),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedRole = v),
                          validator: (v) =>
                              v == null ? 'Please select a role' : null,
                        ),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // ── Section: Bio ──
                    _sectionLabel('About You'),
                    _buildCard([
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: TextFormField(
                          controller: _bioController,
                          maxLines: 4,
                          maxLength: 200,
                          decoration: InputDecoration(
                            labelText: 'Bio',
                            labelStyle: const TextStyle(
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.w500),
                            hintText:
                                'Tell others a little about yourself...',
                            hintStyle: const TextStyle(
                                color: Colors.black38, fontSize: 13),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(10),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF4CAF50).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.edit_note_outlined,
                                  color: Color(0xFF4CAF50), size: 18),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 28),

                    // ── Save Button ──
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                      ),
                    ),

                    const SizedBox(height: 30),
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

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black45),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.green.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, indent: 56, endIndent: 16);

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
              color: Color(0xFF4CAF50), fontWeight: FontWeight.w500),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF4CAF50), size: 18),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: UnderlineInputBorder(
            borderSide:
                const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
              color: Colors.black38, fontWeight: FontWeight.w500),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.grey, size: 18),
          ),
          suffixIcon: const Tooltip(
            message: 'Email cannot be changed here',
            child: Icon(Icons.lock_outline, size: 16, color: Colors.black26),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        style: const TextStyle(color: Colors.black45),
      ),
    );
  }
}
