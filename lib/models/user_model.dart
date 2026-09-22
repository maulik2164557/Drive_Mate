import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String mobileNumber;
  final String role; // "admin" | "regular"
  final String kycStatus; // "Pending" | "Verified"
  final String? aadharDocumentUrl;
  final String? drivingLicenceUrl;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.mobileNumber,
    required this.role,
    required this.kycStatus,
    this.aadharDocumentUrl,
    this.drivingLicenceUrl,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      mobileNumber: map['mobileNumber'] ?? '',
      role: map['role'] ?? 'regular',
      kycStatus: map['kycStatus'] ?? 'Pending',
      aadharDocumentUrl: map['aadharDocumentUrl'],
      drivingLicenceUrl: map['drivingLicenceUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'mobileNumber': mobileNumber,
      'role': role,
      'kycStatus': kycStatus,
      'aadharDocumentUrl': aadharDocumentUrl,
      'drivingLicenceUrl': drivingLicenceUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
