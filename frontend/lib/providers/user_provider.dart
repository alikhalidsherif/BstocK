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
      final targetIndex = _allUsers.indexWhere((u) => u.id == userId);
      if (targetIndex != -1 && _allUsers[targetIndex].isMaster) {
        throw Exception('Master account cannot be edited.');
      }
      final updatedUser = await _apiService.updateUser(userId, role: role.toString().split('.').last);
      final replaceIndex = _allUsers.indexWhere((u) => u.id == userId);
      if (replaceIndex != -1) {
        _allUsers[replaceIndex] = updatedUser;
        notifyListeners();
      }
    } catch (e) {
      // Optionally re-throw or show a message to the user
    }
  }

  Future<void> deleteUser(int userId) async {
    try {
      final index = _allUsers.indexWhere((user) => user.id == userId);
      if (index != -1 && _allUsers[index].isMaster) {
        throw Exception('Master account cannot be deleted.');
      }
      await _apiService.deleteUser(userId);
      _allUsers.removeWhere((user) => user.id == userId);
      notifyListeners();
    } catch (e) {
      rethrow;
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