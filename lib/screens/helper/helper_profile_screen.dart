import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/user.dart';
import '../../models/job.dart';
import '../../services/auth_service.dart';
import '../../services/image_service.dart';
import '../../services/job_service.dart';
import '../../components/activity_status_indicator.dart';
import '../../components/helper_service_card.dart';
import '../../components/review/detailed_rating_breakdown.dart';
import '../../components/review/review_card.dart';
import '../../components/review/review_form.dart';
import '../../models/review.dart';
import '../../services/review_service.dart';

class HelperProfileScreen extends StatefulWidget {
  final User helper;
  final bool isCurrentUser;

  const HelperProfileScreen({
    super.key,
    required this.helper,
    this.isCurrentUser = false,
  });

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
  String? _barangayClearance;
  late bool _isActive;
  List<Job> _postedServices = [];
  bool _loadingServices = true;
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
    _nameController = TextEditingController(text: widget.helper.name);
    _emailController = TextEditingController(text: widget.helper.email);
    _phoneController = TextEditingController(text: widget.helper.phone);
    _experienceController = TextEditingController(
      text: widget.helper.experience ?? '',
    );
    _skills = List<String>.from(widget.helper.skills ?? []);
    _photoUrl = widget.helper.photoUrl;
    _barangayClearance = widget.helper.barangayClearance;
    _isActive = widget.helper.isActive;
    _loadPostedServices();
    _loadReviews();
    _loadCurrentUserId(); // Add this method
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

  Future<void> _loadPostedServices() async {
    setState(() {
      _loadingServices = true;
    });

    try {
      final services = await JobService.getHelperPostedJobs(widget.helper.id);
      if (mounted) {
        setState(() {
          _postedServices = services;
          _loadingServices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingServices = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error loading services: $e')));
        }
      }
    }
  }

  Future<void> _loadReviews() async {
    setState(() {
      _loadingReviews = true;
    });

    try {
      final reviews = await ReviewService.getReviewsForUser(widget.helper.id);
      final avgRating = await ReviewService.getAverageRating(widget.helper.id);
      final categoryAvgs = await ReviewService.getCategoryAverages(
        widget.helper.id,
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
        barangayClearance: _barangayClearance,
        skills: _skills,
        experience: _experienceController.text,
        password: widget.helper.password,
        isActive: _isActive,
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

  Future<void> _toggleActiveStatus() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final updatedUser = await AuthService.updateActiveStatus(
        widget.helper.id,
        !_isActive,
      );

      if (mounted) {
        setState(() {
          _isActive = updatedUser.isActive;
          _isSaving = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isActive
                    ? 'Your profile is now visible to employers'
                    : 'Your profile is now hidden from employers',
              ),
              backgroundColor: _isActive ? Colors.green : Colors.grey,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
        }
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

  Future<void> _pickBarangayClearance() async {
    try {
      final base64Image = await ImageService.pickImageAsBase64();
      if (base64Image != null) {
        setState(() {
          _barangayClearance = base64Image;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Barangay Clearance updated. Save your profile to apply changes.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking Barangay clearance: $e')),
        );
      }
    }
  }

  void _viewServiceDetails(Job service) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    HelperServiceCard(
                      service: service,
                      helper: widget.helper,
                      onTap: () {},
                      isDetailed: true,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Profile',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Active status toggle
                        Row(
                          children: [
                            Text(
                              _isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: _isActive ? Colors.green : Colors.grey,
                              ),
                            ),
                            Switch(
                              value: _isActive,
                              onChanged: (value) => _toggleActiveStatus(),
                              activeColor: Colors.green,
                            ),
                          ],
                        ),
                      ],
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
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: ActivityStatusIndicator(
                                    isActive: _isActive,
                                    size: 16,
                                    showText: false,
                                  ),
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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Helper',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              ActivityStatusIndicator(
                                isActive: _isActive,
                                showText: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // My Services Section
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
                                  'My Services',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    // Navigate to post service screen
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add New'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_loadingServices)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (_postedServices.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.work_outline,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'You haven\'t posted any services yet',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          // Navigate to post service screen
                                        },
                                        icon: const Icon(Icons.add),
                                        label: const Text('Post a Service'),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _postedServices.length,
                                itemBuilder: (context, index) {
                                  final service = _postedServices[index];
                                  return HelperServiceCard(
                                    service: service,
                                    helper: widget.helper,
                                    onTap: () => _viewServiceDetails(service),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Personal Information Section
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
                    // Skills Section
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
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.1),
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
                    // Experience Section
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
                    // Barangay Clearance Section
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
                              'Barangay Clearance',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_barangayClearance != null)
                              Column(
                                children: [
                                  Container(
                                    height: 200,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: DecorationImage(
                                        image: MemoryImage(
                                          base64Decode(_barangayClearance!),
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  if (_isEditing) ...[
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: _pickBarangayClearance,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Update Barangay Clearance'),
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
                                      'No Barangay Clearance Uploaded',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    if (_isEditing) ...[
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: _pickBarangayClearance,
                                        icon: const Icon(Icons.upload),
                                        label: const Text(
                                          'Upload Barangay Clearance',
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
                                  _barangayClearance = widget.helper.barangayClearance;
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
                    // Reviews Section
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Reviews & Ratings',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
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
                                          label: const Text(
                                            'Be the first to review',
                                          ),
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
                                itemCount:
                                    _reviews.length > 3 ? 3 : _reviews.length,
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
                                targetId: widget.helper.id,
                                onComplete: _handleReviewComplete,
                              ),
                            ],
                          ],
                        ),
                      ),
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
