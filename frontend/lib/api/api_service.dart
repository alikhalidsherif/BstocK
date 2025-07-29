import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class ApiService {
  String get _baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    } else {
      return 'http://10.0.2.2:8000/api';
    }
  }
  String get baseUrl => _baseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': username, 'password': password},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['access_token']);
      return data;
    } else {
      throw Exception('Failed to login. Status code: ${response.statusCode}');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<List<Product>> getProducts() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/products/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<Product> products = body.map((dynamic item) => Product.fromJson(item)).toList();
      return products;
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/products/$barcode'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      return null; // Explicitly return null when product is not found
    } else {
      throw Exception('Failed to load product');
    }
  }

  Future<void> submitChangeRequest({
    String? barcode,
    required String action,
    int? quantity,
    String? buyerName,
    String? paymentStatus,
    String? newProductName,
    String? newProductBarcode,
    double? newProductPrice,
    int? newProductQuantity,
    String? newProductCategory,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/inventory/request'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'barcode': barcode,
        'action': action,
        'quantity_change': quantity,
        'buyer_name': buyerName,
        'payment_status': paymentStatus,
        'new_product_name': newProductName,
        'new_product_barcode': newProductBarcode,
        'new_product_price': newProductPrice,
        'new_product_quantity': newProductQuantity,
        'new_product_category': newProductCategory,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit change request.');
    }
  }

  Future<Product> createProduct(Product product) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/products/'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'barcode': product.barcode,
        'name': product.name,
        'price': product.price,
        'quantity': product.quantity,
        'category': product.category,
      }),
    );

    if (response.statusCode == 201) {
      final List<dynamic> body = jsonDecode(response.body);
      if (body.isNotEmpty) {
        return Product.fromJson(body.first);
      } else {
        throw Exception('Failed to create product: Empty response from server.');
      }
    } else if (response.statusCode == 409) {
      throw Exception('Product with this barcode already exists.');
    } else {
      throw Exception('Failed to create product: ${response.body}');
    }
  }

  Future<User> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/me/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get current user.');
    }
  }

  Future<List<ChangeRequest>> getPendingRequests() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/inventory/requests/pending'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<ChangeRequest> requests = body.map((dynamic item) => ChangeRequest.fromJson(item)).toList();
      return requests;
    } else {
      throw Exception('Failed to load pending requests');
    }
  }

  Future<ChangeHistory> approveRequest(int requestId) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/inventory/requests/$requestId/approve'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      // The backend now returns the ChangeHistory object
      return ChangeHistory.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to approve request: ${response.body}');
    }
  }

  Future<ChangeHistory> rejectRequest(int requestId) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/inventory/requests/$requestId/reject'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      // The backend now returns the ChangeHistory object
      return ChangeHistory.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to reject request: ${response.body}');
    }
  }

  Future<List<ChangeHistory>> getHistory() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/history/'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => ChangeHistory.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load history');
    }
  }

  Future<List<ChangeHistory>> getSalesHistory() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/history/sales'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => ChangeHistory.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load sales history');
    }
  }

  Future<List<ChangeHistory>> getUnpaidSales() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/history/unpaid'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => ChangeHistory.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load unpaid sales');
    }
  }

  Future<Map<String, dynamic>> importProductsFromExcel(String filePath) async {
    var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/products/import'));
    request.headers.addAll(await _getHeaders());
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    
    var response = await request.send();
    final responseData = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      return jsonDecode(responseData);
    } else {
      throw Exception('Failed to import Excel file: $responseData');
    }
  }

  Future<Product> updateProduct(int productId, Product product) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/products/$productId'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'barcode': product.barcode,
        'name': product.name,
        'price': product.price,
        'quantity': product.quantity,
        'category': product.category,
      }),
    );
    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update product: ${response.body}');
    }
  }

  Future<void> deleteProduct(int productId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/products/$productId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete product');
    }
  }

  Future<List<String>> getCategories() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/products/categories'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<String>();
    } else {
      throw Exception('Failed to load categories');
    }
  }
  
  // User Management
  Future<List<User>> getUsers() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get users');
    }
  }

  Future<User> updateUser(int userId, {String? role, bool? isActive}) async {
    final body = <String, dynamic>{};
    if (role != null) body['role'] = role;
    if (isActive != null) body['is_active'] = isActive;

    final response = await http.put(
      Uri.parse('$_baseUrl/users/$userId'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update user');
    }
  }

  Future<void> deleteUser(int userId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/users/$userId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }

  Future<User> createUser({
    required String username,
    required String password,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'username': username,
        'password': password,
        'role': role,
      }),
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create user: ${response.body}');
    }
  }
} 