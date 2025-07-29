import 'package:bstock_app/api/api_service.dart';
import 'package:bstock_app/models/models.dart';
import 'package:flutter/foundation.dart';

class HistoryProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<ChangeHistory> _history = [];
  List<ChangeHistory> _unpaidSales = [];
  List<ChangeHistory> _salesHistory = [];
  
  bool _isHistoryLoading = false;
  bool _isUnpaidLoading = false;
  bool _isSalesLoading = false;
  String? _historyError;
  String? _unpaidError;
  String? _salesError;

  List<ChangeHistory> get history => _history;
  List<ChangeHistory> get unpaidSales => _unpaidSales;
  List<ChangeHistory> get salesHistory => _salesHistory;
  
  bool get isHistoryLoading => _isHistoryLoading;
  bool get isUnpaidLoading => _isUnpaidLoading;
  bool get isSalesLoading => _isSalesLoading;
  String? get historyError => _historyError;
  String? get unpaidError => _unpaidError;
  String? get salesError => _salesError;

  HistoryProvider();

  Future<void> fetchHistory() async {
    _isHistoryLoading = true;
    _historyError = null;
    notifyListeners();
    try {
      _history = await _apiService.getHistory();
    } catch (e) {
      _historyError = e.toString();
    } finally {
      _isHistoryLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUnpaidSales() async {
    _isUnpaidLoading = true;
    _unpaidError = null;
    notifyListeners();
    try {
      _unpaidSales = await _apiService.getUnpaidSales();
    } catch (e) {
      _unpaidError = e.toString();
    } finally {
      _isUnpaidLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSalesHistory() async {
    _isSalesLoading = true;
    _salesError = null;
    notifyListeners();
    try {
      _salesHistory = await _apiService.getSalesHistory();
    } catch (e) {
      _salesError = e.toString();
    } finally {
      _isSalesLoading = false;
      notifyListeners();
    }
  }
} 