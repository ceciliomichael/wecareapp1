import 'package:flutter/material.dart';

class DetailedRatingBreakdown extends StatelessWidget {
  final double overallRating;
  final Map<String, double> categoryRatings;
  final int reviewCount;

  const DetailedRatingBreakdown({
    super.key,
    required this.overallRating,
    required this.categoryRatings,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall rating display
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              overallRating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'out of 5',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ),
            const Spacer(),
            Text(
              '$reviewCount ${reviewCount == 1 ? 'review' : 'reviews'}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Star display
        Row(
          children: List.generate(5, (index) {
            if (index < overallRating.floor()) {
              return const Icon(Icons.star, color: Colors.amber, size: 24);
            } else if (index < overallRating.ceil() &&
                overallRating.floor() != overallRating.ceil()) {
              return const Icon(Icons.star_half, color: Colors.amber, size: 24);
            } else {
              return const Icon(
                Icons.star_border,
                color: Colors.amber,
                size: 24,
              );
            }
          }),
        ),
        const SizedBox(height: 24),
        // Category breakdowns
        ...categoryRatings.entries.map(
          (entry) => _buildCategoryRating(context, entry.key, entry.value),
        ),
      ],
    );
  }

  Widget _buildCategoryRating(
    BuildContext context,
    String category,
    double rating,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rating / 5,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getRatingColor(rating),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 4.0) return Colors.lightGreen;
    if (rating >= 3.0) return Colors.amber;
    if (rating >= 2.0) return Colors.orange;
    return Colors.red;
  }
}
