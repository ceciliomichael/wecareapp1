import 'dart:convert';

class Review {
  final String id;
  final String reviewerId; // ID of the user giving the review
  final String targetId; // ID of the user being reviewed
  final double rating; // Rating from 1 to 5
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.reviewerId,
    required this.targetId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  // Create a copy of the review with some fields updated
  Review copyWith({
    String? id,
    String? reviewerId,
    String? targetId,
    double? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return Review(
      id: id ?? this.id,
      reviewerId: reviewerId ?? this.reviewerId,
      targetId: targetId ?? this.targetId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Convert Review to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reviewerId': reviewerId,
      'targetId': targetId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create Review from Map
  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'],
      reviewerId: map['reviewerId'],
      targetId: map['targetId'],
      rating: map['rating'],
      comment: map['comment'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // Convert Review to JSON
  String toJson() => json.encode(toMap());

  // Create Review from JSON
  factory Review.fromJson(String source) => Review.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Review(id: $id, reviewerId: $reviewerId, targetId: $targetId, rating: $rating, comment: $comment, createdAt: $createdAt)';
  }
}
