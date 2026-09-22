import 'package:flutter/material.dart';
import '../models/car_model.dart';
import '../services/database_service.dart';

class CarProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<CarModel> _cars = [];
  bool _isLoading = false;

  List<CarModel> get cars => _cars;
  bool get isLoading => _isLoading;

  CarProvider() {
    fetchCars();
  }

  void fetchCars() {
    _isLoading = true;
    _dbService.getCars().listen((data) {
      _cars = data;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addCar(CarModel car) async {
    await _dbService.addCar(car);
  }

  Future<void> updateCar(CarModel car) async {
    await _dbService.updateCar(car);
  }

  Future<void> deleteCar(String carId) async {
    await _dbService.deleteCar(carId);
  }
}
