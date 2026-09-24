import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../models/car_model.dart';
import '../services/database_service.dart';
import '../core/utils/calculation_utils.dart';

class BookingProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<BookingModel> _userBookings = [];
  List<CarModel> _availableCars = [];
  bool _isLoading = false;

  List<BookingModel> get userBookings => _userBookings;
  List<CarModel> get availableCars => _availableCars;
  bool get isLoading => _isLoading;

  void fetchUserBookings(String userId) {
    _dbService.getUserBookings(userId).listen((data) {
      _userBookings = data;
      notifyListeners();
    });
  }

  Future<void> searchCars({
    required DateTime pickup,
    required DateTime drop,
    required String category,
  }) async {
    _isLoading = true;
    notifyListeners();

    // 1. Get all cars
    // 2. Get bookings in range
    // 3. Filter
    var allCarsSnapshot = await _dbService.getCars().first;
    var bookingsInRange = await _dbService.getBookingsInRange(pickup, drop);

    _availableCars = allCarsSnapshot.where((car) {
      if (category != 'All' && car.category != category) return false;
      
      int bookedUnits = bookingsInRange.where((b) => b.carId == car.carId).length;
      return (car.totalUnits - bookedUnits) > 0;
    }).toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createBooking(BookingModel booking) async {
    await _dbService.addBooking(booking);
  }

  Future<void> cancelBooking(String bookingId, DateTime pickupTime, double totalAmount) async {
    var result = CalculationUtils.calculateCancellationRefund(totalAmount, pickupTime);
    await _dbService.updateBookingStatus(
      bookingId, 
      'Cancelled', 
      refund: result['refund']
    );
  }
}
