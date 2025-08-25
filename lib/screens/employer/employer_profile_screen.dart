import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/image_service.dart';
import '../../components/activity_status_indicator.dart';
import '../../components/review/detailed_rating_breakdown.dart';
import '../../components/review/review_card.dart';
import '../../components/review/review_form.dart';
import '../../models/review.dart';
import '../../services/review_service.dart';

class EmployerProfileScreen extends StatefulWidget {
  final User employer;
  final bool isCurrentUser;

  const EmployerProfileScreen({
    super.key,
    required this.employer,
    this.isCurrentUser = false,
  });

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

  // Add new state variables for reviews
  List<Review> _reviews = [];
  bool _loadingReviews = true;
  bool _showReviewForm = false;
  double _averageRating = 0;
  Map<String, double> _categoryAverages = {};

  // Current user ID for reviews
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _employer = widget.employer;
    _initControllers();
    _loadReviews();
    _loadCurrentUserId();
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

  Future<void> _pickBarangayImage() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final imageBase64 = await ImageService.pickImageAsBase64();

      if (imageBase64 != null) {
        // Update Barangay clearance
        final updatedUser = await AuthService.updateBarangayClearance(
          _employer.id,
          imageBase64,
        );

        setState(() {
          _employer = updatedUser;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Barangay Clearance updated successfully'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating Barangay clearance: $e')),
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

  Future<void> _toggleActiveStatus() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Toggle status
      final updatedUser = await AuthService.updateActiveStatus(
        _employer.id,
        !_employer.isActive,
      );

      setState(() {
        _employer = updatedUser;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account is now ${_employer.isActive ? 'active' : 'inactive'}',
            ),
            backgroundColor: _employer.isActive ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
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

  Future<void> _loadReviews() async {
    setState(() {
      _loadingReviews = true;
    });

    try {
      final reviews = await ReviewService.getReviewsForUser(widget.employer.id);
      final avgRating = await ReviewService.getAverageRating(
        widget.employer.id,
      );
      final categoryAvgs = await ReviewService.getCategoryAverages(
        widget.employer.id,
      );

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _averageRating = avgRating;
          _categoryAverages = categoryAvgs;
          _loadingReviews = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading reviews: $e');
      if (mounted) {
        setState(() {
          _loadingReviews = false;
        });
      }
    }
  }

  void _toggleReviewForm() {
    setState(() {
      _showReviewForm = !_showReviewForm;
    });
  }

  void _handleReviewComplete(bool success) {
    if (success) {
      // Reload reviews
      _loadReviews();
    }
    setState(() {
      _showReviewForm = false;
    });
  }

  // Load current user ID
  Future<void> _loadCurrentUserId() async {
    final userId = await AuthService.getCurrentUserId();
    if (mounted) {
      setState(() {
        _currentUserId = userId;
      });
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
          // Status indicator at top - simplified to just show status, not control it
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                _employer.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _employer.isActive ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              ActivityStatusIndicator(
                isActive: _employer.isActive,
                showText: false,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Profile image
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.2),
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
              // Status indicator on profile image
              Positioned(
                top: 0,
                right: 0,
                child: ActivityStatusIndicator(
                  isActive: _employer.isActive,
                  size: 14,
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
          const SizedBox(height: 16),

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

          // NBI Clearance Card
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
                      Text(
                        'Barangay Clearance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.upload_file),
                        onPressed: _isLoading ? null : _pickBarangayImage,
                        tooltip: 'Update Barangay Clearance',
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_employer.barangayClearance != null)
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(_employer.barangayClearance!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No Barangay Clearance uploaded',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Account Status Settings - KEPT SINGLE CONTROL HERE
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
                  Text(
                    'Account Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active Status'),
                    subtitle: Text(
                      _employer.isActive
                          ? 'Your profile is visible to helpers'
                          : 'Your profile is hidden from helpers',
                    ),
                    value: _employer.isActive,
                    onChanged: _isLoading ? null : (_) => _toggleActiveStatus(),
                    activeColor: Colors.green,
                    activeTrackColor: Colors.green.shade100,
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey.shade300,
                    secondary: Icon(
                      _employer.isActive
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: _employer.isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      'Last active: ${_formatDate(_employer.lastActive)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Reviews section
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
                      Text(
                        'Reviews & Ratings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      if (!_showReviewForm && !widget.isCurrentUser)
                        TextButton.icon(
                          onPressed: _toggleReviewForm,
                          icon: const Icon(Icons.rate_review),
                          label: const Text('Write a Review'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_loadingReviews)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_reviews.isEmpty && !_showReviewForm)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.star_border,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No reviews yet',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                            if (!widget.isCurrentUser) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _toggleReviewForm,
                                icon: const Icon(Icons.rate_review),
                                label: const Text('Be the first to review'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  else if (_reviews.isNotEmpty) ...[
                    DetailedRatingBreakdown(
                      overallRating: _averageRating,
                      categoryRatings: _categoryAverages,
                      reviewCount: _reviews.length,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Recent Reviews',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _reviews.length > 3 ? 3 : _reviews.length,
                      itemBuilder: (context, index) {
                        return ReviewCard(
                          review: _reviews[index],
                          showCategoryRatings: true,
                        );
                      },
                    ),
                    if (_reviews.length > 3)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            // Navigate to full reviews page (to be implemented)
                          },
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('See all reviews'),
                        ),
                      ),
                  ],
                  if (_showReviewForm) ...[
                    const Divider(height: 32),
                    const Text(
                      'Write a Review',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ReviewForm(
                      reviewerId: _currentUserId ?? 'anonymous',
                      targetId: widget.employer.id,
                      onComplete: _handleReviewComplete,
                    ),
                  ],
                ],
              ),
            ),
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
                  ).colorScheme.primary.withValues(alpha: 0.2),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
