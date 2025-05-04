import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/review.dart';
import '../../models/user.dart';
import '../../models/user_type.dart';
import '../../services/storage_service.dart';

class ReviewCard extends StatefulWidget {
  final Review review;
  final bool isCompact;
  final bool showCategoryRatings;
  final VoidCallback? onTap;

  const ReviewCard({
    Key? key,
    required this.review,
    this.isCompact = false,
    this.showCategoryRatings = false,
    this.onTap,
  }) : super(key: key);

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  User? _reviewer;
  bool _isLoading = true;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadReviewer();
  }

  Future<void> _loadReviewer() async {
    try {
      final users = await StorageService.getUsers();
      try {
      _reviewer = users.firstWhere(
        (user) => user.id == widget.review.reviewerId,
        );
      } catch (e) {
        // Create a placeholder user if reviewer not found
        _reviewer = User(
          id: widget.review.reviewerId,
          name: 'User', // Generic name instead of 'Unknown User'
          email: '',
          phone: '',
          userType: UserType.helper, // Default type
          password: '',
          isActive: false,
          lastActive: DateTime.now(),
        );
        debugPrint('Reviewer not found, using placeholder: $e');
      }
    } catch (e) {
      debugPrint('Error loading reviewer: $e');
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
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap:
            widget.onTap ??
            () {
              if (!widget.isCompact) {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              }
            },
        borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child:
            _isLoading
                ? const Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
                : _buildReviewContent(),
        ),
      ),
    );
  }

  Widget _buildReviewContent() {
    final dateFormat = DateFormat('MMM d, yyyy');
    final formattedDate = dateFormat.format(widget.review.createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildReviewerAvatar(),
              const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _reviewer?.name ?? 'Unknown User',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            _buildRatingStars(widget.review.rating),
          ],
        ),
        if (!widget.isCompact) ...[
          const SizedBox(height: 12),
          Text(widget.review.comment, style: const TextStyle(fontSize: 14)),

          if (widget.showCategoryRatings &&
              widget.review.categoryRatings != null &&
              widget.review.categoryRatings!.isNotEmpty) ...[
            const SizedBox(height: 16),
            if (_isExpanded) ...[
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Category Ratings',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ..._buildCategoryRatings(context),
            ] else ...[
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isExpanded = true;
                  });
                },
                icon: const Icon(Icons.expand_more, size: 16),
                label: const Text('View Category Ratings'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size(0, 32),
                ),
              ),
            ],
          ],
        ],
      ],
    );
  }

  Widget _buildReviewerAvatar() {
    if (_reviewer?.photoUrl != null) {
      return CircleAvatar(
        backgroundImage: MemoryImage(
          Uri.parse(_reviewer!.photoUrl!).data!.contentAsBytes(),
        ),
        radius: 20,
      );
    } else {
      return CircleAvatar(
        backgroundColor: Colors.teal.shade200,
        child: Text(
          _reviewer?.name.isNotEmpty == true
              ? _reviewer!.name[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        radius: 20,
      );
    }
  }

  List<Widget> _buildCategoryRatings(BuildContext context) {
    final categoryRatings = widget.review.categoryRatings!;
    return categoryRatings.entries.map((entry) {
      final category = entry.key;
      final rating = entry.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            Row(
              children: List.generate(5, (index) {
                if (index < rating.floor()) {
                  return const Icon(Icons.star, color: Colors.amber, size: 14);
                } else if (index < rating.ceil() &&
                    rating.floor() != rating.ceil()) {
                  return const Icon(
                    Icons.star_half,
                    color: Colors.amber,
                    size: 14,
                  );
                } else {
                  return const Icon(
                    Icons.star_border,
                    color: Colors.amber,
                    size: 14,
                  );
                }
              }),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 18);
        } else if (index < rating.ceil() && rating.floor() != rating.ceil()) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 18);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 18);
        }
      }),
    );
  }
}
