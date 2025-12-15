import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

// Custom exception classes for better error handling
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
  static const String _primaryBackend = 'https://bstockapi.ashreef.com';
  static const String _secondaryBackend = 'https://bstock-bv2k.onrender.com';

  // Web builds can override the backend via --dart-define FLUTTER_WEB_API_URL=<url>
  static const String webApiBase = String.fromEnvironment(
    'FLUTTER_WEB_API_URL',
    defaultValue: _primaryBackend,
  );

  // Mobile/desktop builds can override via --dart-define FLUTTER_DEVICE_API_URL=<url>
  static const String deviceApiBase = String.fromEnvironment(
    'FLUTTER_DEVICE_API_URL',
    defaultValue: _primaryBackend,
  );

  static String? overrideBaseUrl;

  String get _baseUrl {
    if (overrideBaseUrl != null) return overrideBaseUrl!;
    final raw = kIsWeb ? webApiBase : deviceApiBase;
    final sanitized = (raw.isEmpty ? _secondaryBackend : raw).replaceAll(RegExp(r'/+$'), '');
    return '$sanitized/api';
  }
  String get baseUrl => _baseUrl;

  WebSocketChannel? _channel;
  void connectRealtime(void Function(Map<String, dynamic>) onMessage) {
    // Build WS URL from API base URL to always target the backend
    final api = Uri.parse(_baseUrl);
    final scheme = api.scheme == 'https' ? 'wss' : 'ws';
    final wsBasePath = api.path.replaceAll(RegExp(r'/+$'), '').replaceFirst(RegExp(r'/api$'), '');
    // Attach token from storage to authorize the websocket
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
      }, onError: (_) {
        // ignore for now
      });
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
        Uri.parse('$_baseUrl/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': username, 'password': password},
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['access_token']);
        return data;
      } else if (response.statusCode == 401) {
        // Invalid credentials
        throw AuthException('Invalid username or password. Please check your credentials and try again.');
      } else if (response.statusCode == 422) {
        // Validation error (malformed request)
        throw AuthException('Invalid login format. Please check your input.');
      } else if (response.statusCode >= 500) {
        // Server error
        throw ServerException('Server error occurred. Please try again later or contact support.');
      } else {
        // Other HTTP errors
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
        rethrow; // Re-throw our custom exceptions
      }
      // Unknown error
      throw NetworkException('An unexpected error occurred. Please check your internet connection and try again.');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
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

  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/products/$barcode'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        return Product.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        return null; // Explicitly return null when product is not found
      } else {
        throw Exception('Failed to load product');
      }
    } on TimeoutException catch (_) {
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      throw Exception('Failed to load product: $e');
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
    try {
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
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode != 200) {
        throw Exception('Failed to submit change request: ${response.body}');
      }
    } on TimeoutException catch (_) {
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      throw Exception('Failed to submit change request: $e');
    }
  }

  Future<ChangeHistory> submitAutoChangeRequest({
    String? barcode,
    required String action,
    int? quantity,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/inventory/request/auto'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'barcode': barcode,
        'action': action,
        'quantity_change': quantity,
      }),
    );
    if (response.statusCode == 200) {
      return ChangeHistory.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to auto-submit request: ${response.body}');
    }
  }

  Future<Product> createProduct(Product product) async {
    try {
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
      ).timeout(const Duration(seconds: 90));

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
    } on TimeoutException catch (_) {
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      rethrow; // Re-throw to preserve specific error messages
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/me/'),
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

  Future<List<ChangeRequest>> getPendingRequests() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/inventory/requests/pending'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<ChangeRequest> requests = body.map((dynamic item) => ChangeRequest.fromJson(item)).toList();
        return requests;
      } else {
        throw Exception('Failed to load pending requests');
      }
    } on TimeoutException catch (_) {
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      throw Exception('Failed to load pending requests: $e');
    }
  }

  Future<ChangeHistory> approveRequest(int requestId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/inventory/requests/$requestId/approve'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 90));
      
      if (response.statusCode == 200) {
        // The backend now returns the ChangeHistory object
        return ChangeHistory.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to approve request: ${response.body}');
      }
    } on TimeoutException catch (_) {
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      throw Exception('Failed to approve request: $e');
    }
  }

  Future<ChangeHistory> rejectRequest(int requestId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/inventory/requests/$requestId/reject'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 90));
      
      if (response.statusCode == 200) {
        // The backend now returns the ChangeHistory object
        return ChangeHistory.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to reject request: ${response.body}');
      }
    } on TimeoutException catch (_) {
      throw Exception('Server took too long to respond. Please try again.');
    } catch (e) {
      throw Exception('Failed to reject request: $e');
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

  Future<Map<String, dynamic>> importProductsFromExcel({
    String? filePath, 
    Uint8List? fileBytes, 
    String? fileName
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/products/import'));
    request.headers.addAll(await _getHeaders());
    
    if (kIsWeb) {
      // For web platform, use bytes
      if (fileBytes == null || fileName == null) {
        throw Exception('File bytes and filename are required for web platform');
      }
      request.files.add(http.MultipartFile.fromBytes(
        'file', 
        fileBytes,
        filename: fileName,
      ));
    } else {
      // For mobile platforms, use file path
      if (filePath == null) {
        throw Exception('File path is required for mobile platform');
      }
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
    }
    
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

  Future<Product> archiveProduct(int productId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/products/$productId/archive'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to archive product: ${response.body}');
    }
  }

  Future<Product> unarchiveProduct(int productId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/products/$productId/unarchive'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to unarchive product: ${response.body}');
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
      String message = 'Failed to delete user';
      try {
        final dynamic data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['detail'] != null) {
          message = data['detail'].toString();
        } else if (response.body.isNotEmpty) {
          message = response.body;
        }
      } catch (_) {
        if (response.body.isNotEmpty) {
          message = response.body;
        }
      }
      throw ServerException(message);
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
    if (response.statusCode == 200 || response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create user: ${response.body}');
    }
  }
} 