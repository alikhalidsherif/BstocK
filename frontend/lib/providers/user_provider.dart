import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/models.dart';

class UserProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String _searchQuery = '';

  List<User> _allUsers = [];

  List<User> get users {
    if (_searchQuery.isEmpty) {
      return _allUsers;
    } else {
      return _allUsers
          .where((u) => u.username.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
  }

  bool get isLoading => _isLoading;

  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allUsers = await _apiService.getUsers();
    } catch (e) {
      // Handle error appropriately
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchUsers(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> updateUserRole(int userId, UserRole role) async {
    try {
      final updatedUser = await _apiService.updateUser(userId, role: role.toString().split('.').last);
      final index = _allUsers.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _allUsers[index] = updatedUser;
        notifyListeners();
      }
    } catch (e) {
      // Optionally re-throw or show a message to the user
    }
  }

  Future<void> deleteUser(int userId) async {
    try {
      await _apiService.deleteUser(userId);
      _allUsers.removeWhere((user) => user.id == userId);
      notifyListeners();
    } catch (e) {
      // Optionally re-throw or show a message to the user
    }
  }

  Future<void> createUser({
    required String username,
    required String password,
    required UserRole role,
  }) async {
    try {
      final newUser = await _apiService.createUser(
        username: username,
        password: password,
        role: role.name,
      );
      _allUsers.add(newUser);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
} 