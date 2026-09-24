import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/car_model.dart';
import '../models/booking_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Cars
  Stream<List<CarModel>> getCars() {
    return _db.collection('cars').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => CarModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> addCar(CarModel car) {
    return _db.collection('cars').add(car.toMap());
  }

  Future<void> updateCar(CarModel car) {
    return _db.collection('cars').doc(car.carId).update(car.toMap());
  }

  Future<void> deleteCar(String carId) {
    return _db.collection('cars').doc(carId).delete();
  }

  // Bookings
  Future<void> addBooking(BookingModel booking) {
    return _db.collection('bookings').add(booking.toMap());
  }

  Stream<List<BookingModel>> getAllBookings() {
    return _db.collection('bookings').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => BookingModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<BookingModel>> getUserBookings(String userId) {
    return _db.collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => BookingModel.fromMap(doc.data(), doc.id)).toList());
  }

  // Users
  Stream<List<UserModel>> getUsers() {
    return _db.collection('users').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }

  Future<UserModel?> getUserById(String uid) async {
    try {
      var doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
    } catch (e) {
      // Return null if user fetch fails
    }
    return null;
  }

  Future<CarModel?> getCarById(String carId) async {
    var doc = await _db.collection('cars').doc(carId).get();
    if (doc.exists) {
      return CarModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<void> updateBookingStatus(String bookingId, String status, {String? reason, double? refund}) {
    Map<String, dynamic> data = {'status': status};
    if (reason != null) data['cancellationReason'] = reason;
    if (refund != null) data['refundAmount'] = refund;
    return _db.collection('bookings').doc(bookingId).update(data);
  }

  // Fetch all bookings for inventory check
  Future<List<BookingModel>> getBookingsInRange(DateTime start, DateTime end) async {
    // Note: Firestore doesn't support complex overlap queries easily.
    // We fetch all active bookings and filter in memory for precision or 
    // use a simplified range check.
    var snapshot = await _db.collection('bookings')
        .where('status', isEqualTo: 'Pending Journey')
        .get();
    
    return snapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
        .where((b) {
          // Check for overlap: (StartA <= EndB) and (EndA >= StartB)
          return (b.pickupDateTime.isBefore(end) && b.dropDateTime.isAfter(start));
        })
        .toList();
  }
}
