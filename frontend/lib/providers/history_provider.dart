import 'package:bstock_app/api/api_service.dart';
import 'package:bstock_app/models/models.dart';
import 'package:flutter/foundation.dart';

class HistoryProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<ChangeHistory> _history = [];
  bool _isLoading = false;

  List<ChangeHistory> get history => _history;
  bool get isLoading => _isLoading;

  HistoryProvider() {
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    _isLoading = true;
    notifyListeners();
    try {
      _history = await _apiService.getHistory();
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 