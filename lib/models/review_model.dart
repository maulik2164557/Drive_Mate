import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String reviewId;
  final String bookingId;
  final String userId;
  final String userName;
  final String carId;
  final String carName;
  final double carRating; // 1.0 - 5.0
  final String carReviewComment;
  final double managementRating; // 1.0 - 5.0
  final String managementReviewComment;
  final DateTime createdAt;

  ReviewModel({
    required this.reviewId,
    required this.bookingId,
    required this.userId,
    required this.userName,
    required this.carId,
    required this.carName,
    required this.carRating,
    required this.carReviewComment,
    required this.managementRating,
    required this.managementReviewComment,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      reviewId: id,
      bookingId: map['bookingId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Anonymous Customer',
      carId: map['carId'] ?? '',
      carName: map['carName'] ?? 'Vehicle',
      carRating: (map['carRating'] ?? 5.0).toDouble(),
      carReviewComment: map['carReviewComment'] ?? '',
      managementRating: (map['managementRating'] ?? 5.0).toDouble(),
      managementReviewComment: map['managementReviewComment'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'userId': userId,
      'userName': userName,
      'carId': carId,
      'carName': carName,
      'carRating': carRating,
      'carReviewComment': carReviewComment,
      'managementRating': managementRating,
      'managementReviewComment': managementReviewComment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
