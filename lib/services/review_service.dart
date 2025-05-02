import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/review.dart';

class ReviewService {
  static const String _reviewsKey = 'reviews';
  static final Uuid _uuid = Uuid();

  // Save list of reviews to SharedPreferences
  static Future<void> saveReviews(List<Review> reviews) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> reviewsJson =
        reviews.map((review) => review.toJson()).toList();
    await prefs.setStringList(_reviewsKey, reviewsJson);
  }

  // Get all reviews from SharedPreferences
  static Future<List<Review>> getReviews() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? reviewsJson = prefs.getStringList(_reviewsKey);

    if (reviewsJson == null) {
      return [];
    }

    return reviewsJson.map((json) => Review.fromJson(json)).toList();
  }

  // Create a new review
  static Future<Review> createReview({
    required String reviewerId,
    required String targetId,
    required double rating,
    required String comment,
  }) async {
    // Validate rating
    if (rating < 1 || rating > 5) {
      throw Exception('Rating must be between 1 and 5');
    }

    // Check if reviewer has already reviewed this target
    final reviews = await getReviews();
    final existingReview =
        reviews
            .where(
              (review) =>
                  review.reviewerId == reviewerId &&
                  review.targetId == targetId,
            )
            .toList();

    // If a review already exists, update it instead
    if (existingReview.isNotEmpty) {
      final updated = existingReview.first.copyWith(
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      );

      await updateReview(updated);
      return updated;
    }

    // Create new review
    final review = Review(
      id: _uuid.v4(),
      reviewerId: reviewerId,
      targetId: targetId,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    // Save to storage
    reviews.add(review);
    await saveReviews(reviews);

    return review;
  }

  // Update an existing review
  static Future<Review> updateReview(Review updatedReview) async {
    final reviews = await getReviews();
    final index = reviews.indexWhere((review) => review.id == updatedReview.id);

    if (index >= 0) {
      reviews[index] = updatedReview;
      await saveReviews(reviews);
      return updatedReview;
    } else {
      throw Exception('Review not found');
    }
  }

  // Delete a review
  static Future<void> deleteReview(String reviewId) async {
    final reviews = await getReviews();
    final filtered = reviews.where((review) => review.id != reviewId).toList();

    if (filtered.length < reviews.length) {
      await saveReviews(filtered);
    } else {
      throw Exception('Review not found');
    }
  }

  // Get reviews for a specific user
  static Future<List<Review>> getReviewsForUser(String userId) async {
    final reviews = await getReviews();
    return reviews.where((review) => review.targetId == userId).toList();
  }

  // Get average rating for a user
  static Future<double> getAverageRating(String userId) async {
    final reviews = await getReviewsForUser(userId);

    if (reviews.isEmpty) {
      return 0.0;
    }

    final totalRating = reviews.fold(0.0, (sum, review) => sum + review.rating);
    return totalRating / reviews.length;
  }

  // Get reviews given by a user
  static Future<List<Review>> getReviewsByReviewer(String reviewerId) async {
    final reviews = await getReviews();
    return reviews.where((review) => review.reviewerId == reviewerId).toList();
  }
}
