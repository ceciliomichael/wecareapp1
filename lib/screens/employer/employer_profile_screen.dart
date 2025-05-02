import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/image_service.dart';

class EmployerProfileScreen extends StatefulWidget {
  final User employer;

  const EmployerProfileScreen({Key? key, required this.employer})
    : super(key: key);

  @override
  State<EmployerProfileScreen> createState() => _EmployerProfileScreenState();
}

class _EmployerProfileScreenState extends State<EmployerProfileScreen> {
  late User _employer;
  bool _isEditing = false;
  bool _isLoading = false;

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _employer = widget.employer;
    _initControllers();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: _employer.name);
    _emailController = TextEditingController(text: _employer.email);
    _phoneController = TextEditingController(text: _employer.phone);
    _addressController = TextEditingController(text: _employer.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final imageBase64 = await ImageService.pickImageAsBase64();

      if (imageBase64 != null) {
        // Update user with new photo
        final updatedUser = _employer.copyWith(photoUrl: imageBase64);
        await AuthService.updateProfile(updatedUser);

        setState(() {
          _employer = updatedUser;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final updatedUser = _employer.copyWith(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        address:
            _addressController.text.isNotEmpty ? _addressController.text : null,
      );

      await AuthService.updateProfile(updatedUser);

      setState(() {
        _employer = updatedUser;
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isEditing ? _buildEditProfile() : _buildViewProfile();
  }

  Widget _buildViewProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile image
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.2),
                child:
                    _employer.photoUrl != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: Image.memory(
                            base64Decode(_employer.photoUrl!),
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        )
                        : Icon(
                          Icons.person,
                          size: 60,
                          color: Theme.of(context).colorScheme.primary,
                        ),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: IconButton(
                  icon: const Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: Colors.white,
                  ),
                  onPressed: _isLoading ? null : _pickProfileImage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Name
          Text(
            _employer.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Employer',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),

          // Information cards
          _buildInfoCard(
            title: 'Contact Information',
            children: [
              _buildInfoRow(Icons.email, 'Email', _employer.email),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.phone, 'Phone', _employer.phone),
            ],
          ),
          const SizedBox(height: 16),

          // Address card (if available)
          if (_employer.address != null && _employer.address!.isNotEmpty)
            _buildInfoCard(
              title: 'Address',
              children: [
                _buildInfoRow(Icons.location_on, 'Address', _employer.address!),
              ],
            ),

          const SizedBox(height: 32),

          // Edit profile button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await AuthService.logout();
                if (mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.2),
                  child:
                      _employer.photoUrl != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: Image.memory(
                              base64Decode(_employer.photoUrl!),
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          )
                          : Icon(
                            Icons.person,
                            size: 60,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                ),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: IconButton(
                    icon: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                    onPressed: _isLoading ? null : _pickProfileImage,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Form fields
          const Text(
            'Personal Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Name field
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),

          // Email field
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          // Phone field
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          // Address field
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 32),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () {
                            setState(() {
                              _isEditing = false;
                              _initControllers();
                            });
                          },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            Text(value, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ],
    );
  }
}
