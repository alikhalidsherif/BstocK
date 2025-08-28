import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import '../models/models.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated }

class AuthResult {
  final bool success;
  final String? errorMessage;
  
  AuthResult({required this.success, this.errorMessage});
}

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  AuthStatus _status = AuthStatus.uninitialized;
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
        _status = AuthStatus.authenticated;
      } catch (e) {
        // Token is invalid or expired
        _token = null;
        _user = null;
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<AuthResult> login(String username, String password) async {
    try {
      final response = await _apiService.login(username, password);
      _token = response['access_token'];
      // After login, fetch user details
      _user = await _apiService.getCurrentUser();
      _status = AuthStatus.authenticated;
      notifyListeners();
      return AuthResult(success: true);
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return AuthResult(success: false, errorMessage: e.toString());
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _status = AuthStatus.unauthenticated;
    await _apiService.logout();
    notifyListeners();
  }
} 