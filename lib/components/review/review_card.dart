import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/review.dart';
import '../../models/user.dart';
import '../../services/storage_service.dart';

class ReviewCard extends StatefulWidget {
  final Review review;
  final bool isCompact;

  const ReviewCard({Key? key, required this.review, this.isCompact = false})
    : super(key: key);

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  User? _reviewer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviewer();
  }

  Future<void> _loadReviewer() async {
    try {
      final users = await StorageService.getUsers();
      _reviewer = users.firstWhere(
        (user) => user.id == widget.review.reviewerId,
        orElse: () => throw Exception('Reviewer not found'),
      );
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
            if (_reviewer?.photoUrl != null) ...[
              CircleAvatar(
                backgroundImage: MemoryImage(
                  Uri.parse(_reviewer!.photoUrl!).data!.contentAsBytes(),
                ),
                radius: 20,
              ),
              const SizedBox(width: 12),
            ] else ...[
              CircleAvatar(
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
              ),
              const SizedBox(width: 12),
            ],
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
        ],
      ],
    );
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
