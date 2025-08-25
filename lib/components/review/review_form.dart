import 'package:flutter/material.dart';
import '../../services/review_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';

class ReviewForm extends StatefulWidget {
  final String reviewerId;
  final String targetId;
  final Function(bool) onComplete;

  const ReviewForm({
    super.key,
    required this.reviewerId,
    required this.targetId,
    required this.onComplete,
  });

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  final TextEditingController _commentController = TextEditingController();
  double _overallRating = 0;
  bool _isSubmitting = false;
  final Map<String, double> _categoryRatings = {};
  final List<String> _categories = ReviewService.defaultCategories;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    // Initialize category ratings to 0
    for (final category in _categories) {
      _categoryRatings[category] = 0;
    }
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final userId = await AuthService.getCurrentUserId();
    if (mounted) {
      setState(() {
        _currentUserId = userId;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Calculate the overall rating from the category ratings
  void _updateOverallRating() {
    if (_categoryRatings.isEmpty) return;

    final total = _categoryRatings.values.fold(
      0.0,
      (sum, rating) => sum + rating,
    );
    final average = total / _categoryRatings.length;

    setState(() {
      _overallRating = average;
    });
  }

  Future<void> _submitReview() async {
    // Check if we have the current user ID
    if (_currentUserId == null) {
      _showErrorDialog('You must be logged in to leave a review.');
      return;
    }

    // Verify the current user exists in storage
    try {
      final users = await StorageService.getUsers();
      final currentUser = users.firstWhere(
        (user) => user.id == _currentUserId,
        orElse: () => throw Exception('User not found'),
      );

      // Use the verified user ID
      _currentUserId = currentUser.id;
    } catch (e) {
      _showErrorDialog('Error finding your user account: $e');
      return;
    }

    // Verify user is not reviewing themselves
    if (_currentUserId == widget.targetId) {
      _showErrorDialog('You cannot review yourself.');
      return;
    }

    if (_overallRating == 0) {
      _showErrorDialog('Please provide an overall rating.');
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      _showErrorDialog('Please provide review comments.');
      return;
    }

    // Ensure all categories have ratings
    final unratedCategories =
        _categoryRatings.entries
            .where((entry) => entry.value == 0)
            .map((entry) => entry.key)
            .toList();

    if (unratedCategories.isNotEmpty) {
      _showErrorDialog(
        'Please rate all categories: ${unratedCategories.join(", ")}',
      );
      return;
    }

      setState(() {
        _isSubmitting = true;
      });

      try {
        await ReviewService.createReview(
        reviewerId: _currentUserId!,
          targetId: widget.targetId,
        rating: _overallRating,
        comment: _commentController.text.trim(),
        categoryRatings: _categoryRatings,
      );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
            content: Text('Review submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        widget.onComplete(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
            content: Text('Error submitting review: $e'),
              backgroundColor: Colors.red,
            ),
          );
        widget.onComplete(false);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          // Category ratings
          ...List.generate(_categories.length, (index) {
            final category = _categories[index];
            return _buildCategoryRatingSelector(category);
          }),

          const Divider(height: 32),

          // Overall rating display
          Center(
            child: Column(
            children: [
              const Text(
                  'Overall Rating',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
                const SizedBox(height: 8),
                Text(
                  _overallRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    if (index < _overallRating.floor()) {
                      return const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 32,
                      );
                    } else if (index < _overallRating.ceil() &&
                        _overallRating.floor() != _overallRating.ceil()) {
                      return const Icon(
                        Icons.star_half,
                        color: Colors.amber,
                        size: 32,
                      );
                    } else {
                      return const Icon(
                        Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      );
                    }
                  }),
                    ),
                ],
              ),
          ),

              const SizedBox(height: 16),

          // Comment field
          TextField(
                controller: _commentController,
            maxLines: 4,
                decoration: const InputDecoration(
              labelText: 'Write your review',
              hintText:
                  'What did you like or dislike? What should others know?',
                  border: OutlineInputBorder(),
                ),
              ),

          const SizedBox(height: 24),

          // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child:
                      _isSubmitting
                      ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Submitting...'),
                        ],
                      )
                      : const Text('Submit Review'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRatingSelector(String category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                            ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(5, (index) {
                  final rating = index + 1.0;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _categoryRatings[category] = rating;
                        _updateOverallRating();
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        _categoryRatings[category]! >= rating
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 28,
                      ),
                    ),
                  );
                }),
              ),
              Text(
                _categoryRatings[category]!.toStringAsFixed(1),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
