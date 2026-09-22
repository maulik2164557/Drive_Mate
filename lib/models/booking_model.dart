import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String bookingId;
  final String userId;
  final String carId;
  final String pickupLocation;
  final DateTime pickupDateTime;
  final String dropLocation;
  final DateTime dropDateTime;
  final double totalPrice;
  final String status; // "Pending Journey", "Completed Journey", "Cancelled"
  final String? cancellationReason;
  final double? refundAmount;
  final DateTime? actualReturnDateTime;
  final double? delayCharges;
  final DateTime createdAt;

  BookingModel({
    required this.bookingId,
    required this.userId,
    required this.carId,
    required this.pickupLocation,
    required this.pickupDateTime,
    required this.dropLocation,
    required this.dropDateTime,
    required this.totalPrice,
    required this.status,
    this.cancellationReason,
    this.refundAmount,
    this.actualReturnDateTime,
    this.delayCharges,
    required this.createdAt,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingModel(
      bookingId: id,
      userId: map['userId'] ?? '',
      carId: map['carId'] ?? '',
      pickupLocation: map['pickupLocation'] ?? '',
      pickupDateTime: (map['pickupDateTime'] as Timestamp).toDate(),
      dropLocation: map['dropLocation'] ?? '',
      dropDateTime: (map['dropDateTime'] as Timestamp).toDate(),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      status: map['status'] ?? 'Pending Journey',
      cancellationReason: map['cancellationReason'],
      refundAmount: (map['refundAmount'] ?? 0).toDouble(),
      actualReturnDateTime: map['actualReturnDateTime'] != null
          ? (map['actualReturnDateTime'] as Timestamp).toDate()
          : null,
      delayCharges: (map['delayCharges'] ?? 0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'carId': carId,
      'pickupLocation': pickupLocation,
      'pickupDateTime': Timestamp.fromDate(pickupDateTime),
      'dropLocation': dropLocation,
      'dropDateTime': Timestamp.fromDate(dropDateTime),
      'totalPrice': totalPrice,
      'status': status,
      'cancellationReason': cancellationReason,
      'refundAmount': refundAmount,
      'actualReturnDateTime': actualReturnDateTime != null
          ? Timestamp.fromDate(actualReturnDateTime!)
          : null,
      'delayCharges': delayCharges,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
