import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _userModel;
  bool _isLoading = false;

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _init();
  }

  void _init() async {
    _isLoading = true;
    notifyListeners();
    _userModel = await _authService.getCurrentUserModel();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String mobileNumber,
    required String role,
  }) async {
    _isLoading = true;
    notifyListeners();
    _userModel = await _authService.signUp(
      email: email,
      password: password,
      fullName: fullName,
      mobileNumber: mobileNumber,
      role: role,
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signIn({
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    notifyListeners();
    _userModel = await _authService.signIn(email: email, password: password, role: role);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    _userModel = await _authService.getCurrentUserModel();
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _userModel = null;
    notifyListeners();
  }
}
