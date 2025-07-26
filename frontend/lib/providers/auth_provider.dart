import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import '../models/models.dart';

enum AuthStatus { Uninitialized, Authenticated, Unauthenticated }

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  AuthStatus _status = AuthStatus.Uninitialized;
  String? _token;
  User? _user;

  AuthStatus get status => _status;
  String? get token => _token;
  User? get user => _user;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');

    if (_token != null) {
      try {
        // Fetch user details if token exists
        _user = await _apiService.getCurrentUser();
        _status = AuthStatus.Authenticated;
      } catch (e) {
        // Token is invalid or expired
        _token = null;
        _user = null;
        _status = AuthStatus.Unauthenticated;
      }
    } else {
      _status = AuthStatus.Unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await _apiService.login(username, password);
      _token = response['access_token'];
      // After login, fetch user details
      _user = await _apiService.getCurrentUser();
      _status = AuthStatus.Authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.Unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _status = AuthStatus.Unauthenticated;
    await _apiService.logout();
    notifyListeners();
  }
} 