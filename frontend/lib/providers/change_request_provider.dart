import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';

class ChangeRequestProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<ChangeRequest> _requests = [];
  bool _isLoading = false;

  List<ChangeRequest> get requests => _requests;
  bool get isLoading => _isLoading;

  Future<void> fetchPendingRequests() async {
    _isLoading = true;
    notifyListeners();
    try {
      _requests = await _apiService.getPendingRequests();
    } catch (e) {
      print(e); // Handle error appropriately
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveRequest(int requestId) async {
    try {
      await _apiService.approveRequest(requestId);
      _requests.removeWhere((req) => req.id == requestId);
      notifyListeners();
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> rejectRequest(int requestId) async {
    try {
      await _apiService.rejectRequest(requestId);
      _requests.removeWhere((req) => req.id == requestId);
      notifyListeners();
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> submitRequest({
    String? barcode,
    required ChangeRequestAction action,
    int? quantity,
    String? buyerName,
    String? paymentStatus,
  }) async {
    try {
      await _apiService.submitChangeRequest(
        barcode: barcode,
        action: action.name,
        quantity: quantity,
        buyerName: buyerName,
        paymentStatus: paymentStatus,
      );
      // Refresh the pending requests list so the UI updates.
      await fetchPendingRequests();
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }
} 