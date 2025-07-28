import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/models.dart';
import 'package:flutter/foundation.dart';

enum SortType {
  none,
  nameAz,
  nameZa,
  quantityLowHigh,
  quantityHighLow,
  barcodeAz,
  barcodeZa,
}

extension SortTypeName on SortType {
  String get name {
    switch (this) {
      case SortType.nameAz:
        return 'Name A-Z';
      case SortType.nameZa:
        return 'Name Z-A';
      case SortType.quantityLowHigh:
        return 'Quantity Low-High';
      case SortType.quantityHighLow:
        return 'Quantity High-Low';
      case SortType.barcodeAz:
        return 'Barcode A-Z';
      case SortType.barcodeZa:
        return 'Barcode Z-A';
      case SortType.none:
        return 'None';
    }
  }
}


class ProductProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Product> _products = [];
  List<Product> _allProducts = [];
  List<String> _categories = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedCategory;
  SortType _sortType = SortType.none;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  SortType get sortType => _sortType;
  List<String> get categories => _categories;

  ProductProvider() {
    fetchProducts();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      _categories = await _apiService.getCategories();
      // Provide default categories if none exist
      if (_categories.isEmpty) {
        _categories = ['Electronics', 'Clothing', 'Books', 'Food', 'Tools', 'Other'];
      }
      notifyListeners();
    } catch (e) {
      // Provide default categories on error
      _categories = ['Electronics', 'Clothing', 'Books', 'Food', 'Tools', 'Other'];
      notifyListeners();
    }
  }

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allProducts = await _apiService.getProducts();
      _applyFiltersAndSort();
    } catch (e) {
      // Handle error, maybe set an error state
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchProducts(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void selectCategory(String? category) {
    _selectedCategory = category;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void sortProducts(SortType sortType) {
    _sortType = sortType;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void _applyFiltersAndSort() {
    List<Product> filtered = List.from(_allProducts);

    // Apply category filter
    if (_selectedCategory != null) {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) =>
      p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.barcode.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Apply sort
    switch (_sortType) {
      case SortType.nameAz:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortType.nameZa:
        filtered.sort((a, b) => b.name.compareTo(a.name));
        break;
      case SortType.quantityLowHigh:
        filtered.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case SortType.quantityHighLow:
        filtered.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
      case SortType.barcodeAz:
        filtered.sort((a, b) => a.barcode.compareTo(b.barcode));
        break;
      case SortType.barcodeZa:
        filtered.sort((a, b) => b.barcode.compareTo(a.barcode));
        break;
      case SortType.none:
        break;
    }


    _products = filtered;
  }

  Future<void> createNewProduct(Product product) async {
    try {
      final newProduct = await _apiService.createProduct(product);
      _allProducts.add(newProduct);
      if (!_categories.contains(newProduct.category)) {
        _categories.add(newProduct.category);
        _categories.sort();
      }
      _applyFiltersAndSort();
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      final updated = await _apiService.updateProduct(product.id, product);
      final index = _allProducts.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _allProducts[index] = updated;
        _applyFiltersAndSort();
        notifyListeners();
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteProduct(int productId) async {
    try {
      await _apiService.deleteProduct(productId);
      _allProducts.removeWhere((p) => p.id == productId);
      _applyFiltersAndSort();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch a single product by barcode. Returns null if not found or on error.
  Future<Product?> fetchProductByBarcode(String barcode) async {
    try {
      return await _apiService.getProductByBarcode(barcode);
    } catch (e) {
      debugPrint('Error fetching product by barcode: $e');
      return null;
    }
  }
} 