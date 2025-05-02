import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/image_service.dart';

class HelperProfileScreen extends StatefulWidget {
  final User helper;

  const HelperProfileScreen({Key? key, required this.helper}) : super(key: key);

  @override
  State<HelperProfileScreen> createState() => _HelperProfileScreenState();
}

class _HelperProfileScreenState extends State<HelperProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _experienceController;
  List<String> _skills = [];
  String _newSkill = '';
  bool _isEditing = false;
  bool _isSaving = false;
  String? _photoUrl;
  String? _nbiClearance;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.helper.name);
    _emailController = TextEditingController(text: widget.helper.email);
    _phoneController = TextEditingController(text: widget.helper.phone);
    _experienceController = TextEditingController(
      text: widget.helper.experience ?? '',
    );
    _skills = List<String>.from(widget.helper.skills ?? []);
    _photoUrl = widget.helper.photoUrl;
    _nbiClearance = widget.helper.nbiClearance;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final updatedHelper = User(
        id: widget.helper.id,
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        userType: widget.helper.userType,
        photoUrl: _photoUrl,
        nbiClearance: _nbiClearance,
        skills: _skills,
        experience: _experienceController.text,
        password: widget.helper.password,
      );

      await AuthService.updateProfile(updatedHelper);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final base64Image = await ImageService.pickImageAsBase64();
      if (base64Image != null) {
        setState(() {
          _photoUrl = base64Image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _pickNBIClearance() async {
    try {
      final base64Image = await ImageService.pickImageAsBase64();
      if (base64Image != null) {
        setState(() {
          _nbiClearance = base64Image;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'NBI Clearance updated. Save your profile to apply changes.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking NBI clearance: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isSaving
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _isEditing ? _pickImage : null,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage:
                                      _photoUrl != null
                                          ? MemoryImage(
                                            base64Decode(_photoUrl!),
                                          )
                                          : null,
                                  child:
                                      _photoUrl == null
                                          ? const Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Colors.grey,
                                          )
                                          : null,
                                ),
                                if (_isEditing)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.helper.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Helper',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Personal Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (!_isEditing)
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = true;
                                      });
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Name',
                              controller: _nameController,
                              enabled: _isEditing,
                              icon: Icons.person,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Email',
                              controller: _emailController,
                              enabled: _isEditing,
                              icon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              label: 'Phone',
                              controller: _phoneController,
                              enabled: _isEditing,
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Skills',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  _skills.map((skill) {
                                    return Chip(
                                      label: Text(skill),
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.1),
                                      deleteIcon:
                                          _isEditing
                                              ? const Icon(
                                                Icons.close,
                                                size: 18,
                                              )
                                              : null,
                                      onDeleted:
                                          _isEditing
                                              ? () {
                                                setState(() {
                                                  _skills.remove(skill);
                                                });
                                              }
                                              : null,
                                    );
                                  }).toList(),
                            ),
                            if (_isEditing) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        hintText: 'Add a skill',
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (value) {
                                        _newSkill = value;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (_newSkill.isNotEmpty &&
                                          !_skills.contains(_newSkill)) {
                                        setState(() {
                                          _skills.add(_newSkill);
                                          _newSkill = '';
                                        });
                                      }
                                    },
                                    child: const Text('Add'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Experience',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _experienceController,
                              maxLines: 5,
                              enabled: _isEditing,
                              decoration: InputDecoration(
                                hintText:
                                    'Describe your previous work experience',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'NBI Clearance',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_nbiClearance != null)
                              Column(
                                children: [
                                  Container(
                                    height: 200,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: DecorationImage(
                                        image: MemoryImage(
                                          base64Decode(_nbiClearance!),
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  if (_isEditing) ...[
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: _pickNBIClearance,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Update NBI Clearance'),
                                    ),
                                  ],
                                ],
                              )
                            else
                              Center(
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.description_outlined,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'No NBI Clearance Uploaded',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    if (_isEditing) ...[
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: _pickNBIClearance,
                                        icon: const Icon(Icons.upload),
                                        label: const Text(
                                          'Upload NBI Clearance',
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_isEditing)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _isEditing = false;
                                  // Reset to original values
                                  _nameController.text = widget.helper.name;
                                  _emailController.text = widget.helper.email;
                                  _phoneController.text = widget.helper.phone;
                                  _experienceController.text =
                                      widget.helper.experience ?? '';
                                  _skills = List<String>.from(
                                    widget.helper.skills ?? [],
                                  );
                                  _photoUrl = widget.helper.photoUrl;
                                  _nbiClearance = widget.helper.nbiClearance;
                                });
                              },
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveProfile,
                              child: const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
