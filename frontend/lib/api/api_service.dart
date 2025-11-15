import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class ServerException implements Exception {
  final String message;
  ServerException(this.message);
  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override
  String toString() => message;
}

class TimeoutAuthException implements Exception {
  final String message;
  TimeoutAuthException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  static const String apiUrl = String.fromEnvironment(
    'FLUTTER_WEB_API_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  
  static const String defaultDeviceBase = String.fromEnvironment(
    'FLUTTER_WEB_API_URL',
    defaultValue: 'http://10.0.2.2:8000'
  );
  static String? overrideBaseUrl;

  String get _baseUrl {
    if (overrideBaseUrl != null) return overrideBaseUrl!;
    if (kIsWeb) {
      return '${apiUrl}/api';
    } else {
      return '${defaultDeviceBase}/api';
    }
  }
  String get baseUrl => _baseUrl;

  WebSocketChannel? _channel;
  
  void connectRealtime(void Function(Map<String, dynamic>) onMessage) {
    final api = Uri.parse(_baseUrl);
    final scheme = api.scheme == 'https' ? 'wss' : 'ws';
    final wsBasePath = api.path.replaceAll(RegExp(r'/+$'), '').replaceFirst(RegExp(r'/api$'), '');
    final tokenFuture = _getToken();
    tokenFuture.then((token) {
      final wsUrl = Uri(
        scheme: scheme,
        host: api.host,
        port: api.port,
        path: '$wsBasePath/ws/updates',
        queryParameters: token != null ? {'token': token} : null,
      ).toString();
      _channel?.sink.close(ws_status.normalClosure);
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channel!.stream.listen((event) {
        try {
          final Map<String, dynamic> msg = jsonDecode(event);
          onMessage(msg);
        } catch (_) {}
      }, onError: (_) {});
    });
  }

  void disconnectRealtime() {
    _channel?.sink.close(ws_status.normalClosure);
    _channel = null;
  }

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
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': username, 'password': password},
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['access_token']);
        return data;
      } else if (response.statusCode == 401) {
        throw AuthException('Invalid username or password. Please check your credentials and try again.');
      } else if (response.statusCode == 422) {
        throw AuthException('Invalid login format. Please check your input.');
      } else if (response.statusCode >= 500) {
        throw ServerException('Server error occurred. Please try again later or contact support.');
      } else {
        throw AuthException('Login failed. Please try again. (Error: ${response.statusCode})');
      }
    } on TimeoutException catch (_) {
      throw TimeoutAuthException('Server took too long to respond. Please check your internet connection and try again.');
    } on http.ClientException catch (_) {
      throw NetworkException('Unable to connect to the server. Please check your internet connection.');
    } on FormatException catch (_) {
      throw ServerException('Server returned invalid data. Please try again later.');
    } catch (e) {
      if (e is AuthException || e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw NetworkException('An unexpected error occurred. Please check your internet connection and try again.');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<User> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get current user.');
      }
    } on TimeoutException catch (_) {
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      throw Exception('Failed to get current user: $e');
    }
  }

  Future<List<Product>> getProducts({bool includeArchived = false}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/products/?include_archived=${includeArchived ? 'true' : 'false'}'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<Product> products = body.map((dynamic item) => Product.fromJson(item)).toList();
        return products;
      } else {
        throw Exception('Failed to load products');
      }
    } on TimeoutException catch (_) {
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  Future<Product> getProductById(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/products/$productId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        return Product.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Product not found');
      } else {
        throw Exception('Failed to load product');
      }
    } on TimeoutException catch (_) {
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      throw Exception('Failed to load product: $e');
    }
  }

  Future<Variant?> getVariantByBarcode(String barcode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/products/variants/barcode/$barcode'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        return Variant.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load variant');
      }
    } on TimeoutException catch (_) {
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      throw Exception('Failed to load variant: $e');
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/products/categories'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<String>();
      } else {
        throw Exception('Failed to load categories');
      }
    } on TimeoutException catch (_) {
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<List<Variant>> getLowStockVariants() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/products/variants/low-stock'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => Variant.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load low stock variants');
      }
    } on TimeoutException catch (_) {
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      throw Exception('Failed to load low stock variants: $e');
    }
  }

  Future<Product> createProduct(Map<String, dynamic> productData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/products/'),
        headers: await _getHeaders(),
        body: jsonEncode(productData),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 201) {
        return Product.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Failed to create product');
      } else {
        throw Exception('Failed to create product: ${response.body}');
      }
    } on TimeoutException catch (_) {
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      rethrow;
    }
  }

  Future<Product> updateProduct(int productId, Map<String, dynamic> updates) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/products/$productId'),
        headers: await _getHeaders(),
        body: jsonEncode(updates),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        return Product.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update product: ${response.body}');
      }
    } on TimeoutException catch (_) {
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  Future<Variant> updateVariant(int variantId, Map<String, dynamic> updates) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/products/variants/$variantId'),
        headers: await _getHeaders(),
        body: jsonEncode(updates),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        return Variant.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update variant: ${response.body}');
      }
    } on TimeoutException catch (_) {
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      throw Exception('Failed to update variant: $e');
    }
  }

  Future<Sale> createSale({
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    int? customerId,
    double tax = 0,
    double discount = 0,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pos/sales'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'items': items,
          'payment_method': paymentMethod,
          'customer_id': customerId,
          'tax': tax,
          'discount': discount,
          'notes': notes,
        }),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 201) {
        return Sale.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Failed to create sale');
      } else {
        throw Exception('Failed to create sale: ${response.body}');
      }
    } on TimeoutException catch (_) {
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      throw Exception('Failed to create sale: $e');
    }
  }

  Future<List<Sale>> getSales({int skip = 0, int limit = 100}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pos/sales?skip=$skip&limit=$limit'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => Sale.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load sales');
      }
    } on TimeoutException catch (_) {
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      throw Exception('Failed to load sales: $e');
    }
  }

  Future<Sale> getSaleById(int saleId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pos/sales/$saleId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        return Sale.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load sale');
      }
    } on TimeoutException catch (_) {
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      throw Exception('Failed to load sale: $e');
    }
  }

  Future<Uint8List> getSaleReceipt(int saleId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/receipts/$saleId/pdf'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to load receipt');
      }
    } on TimeoutException catch (_) {
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      throw Exception('Failed to load receipt: $e');
    }
  }

  Future<AnalyticsSummary> getAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final uri = Uri.parse('$_baseUrl/analytics/summary').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        return AnalyticsSummary.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load analytics');
      }
    } on TimeoutException catch (_) {
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      throw Exception('Failed to load analytics: $e');
    }
  }

  Future<List<Customer>> getCustomers({int skip = 0, int limit = 100}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/customers/?skip=$skip&limit=$limit'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => Customer.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load customers');
      }
    } on TimeoutException catch (_) {
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      throw Exception('Failed to load customers: $e');
    }
  }

  Future<Customer> createCustomer(Map<String, dynamic> customerData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/customers/'),
        headers: await _getHeaders(),
        body: jsonEncode(customerData),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 201) {
        return Customer.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create customer: ${response.body}');
      }
    } on TimeoutException catch (_) {
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      throw Exception('Failed to create customer: $e');
    }
  }

  Future<List<Vendor>> getVendors({int skip = 0, int limit = 100}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/vendors/?skip=$skip&limit=$limit'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => Vendor.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load vendors');
      }
    } on TimeoutException catch (_) {
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      throw Exception('Failed to load vendors: $e');
    }
  }

  Future<Vendor> createVendor(Map<String, dynamic> vendorData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/vendors/'),
        headers: await _getHeaders(),
        body: jsonEncode(vendorData),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 201) {
        return Vendor.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create vendor: ${response.body}');
      }
    } on TimeoutException catch (_) {
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      throw Exception('Failed to create vendor: $e');
    }
  }

  Future<List<User>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get users');
      }
    } on TimeoutException catch (_) {
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  Future<User> createUser({
    required String username,
    required String password,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'username': username,
          'password': password,
          'role': role,
        }),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create user: ${response.body}');
      }
    } on TimeoutException catch (_) {
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<User> updateUser(int userId, {String? role, bool? isActive}) async {
    try {
      final body = <String, dynamic>{};
      if (role != null) body['role'] = role;
      if (isActive != null) body['is_active'] = isActive;

      final response = await http.patch(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update user');
      }
    } on TimeoutException catch (_) {
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  Future<void> deleteUser(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode != 200) {
        throw Exception('Failed to delete user');
      }
    } on TimeoutException catch (_) {
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }
}
