// Used to represent user roles from the backend
enum UserRole {
  user,
  admin,
  supervisor,
}

class User {
  final int id;
  final String username;
  final UserRole role;

  User({
    required this.id,
    required this.username,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${json['role']}',
        orElse: () => UserRole.user,
      ),
    );
  }
}

class Product {
  final int id;
  final String barcode;
  final String name;
  final double price;
  final int quantity;
  final String category;

  Product({
    required this.id,
    required this.barcode,
    required this.name,
    required this.price,
    required this.quantity,
    required this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      barcode: json['barcode'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'],
      category: json['category'] ?? 'Uncategorized',
    );
  }
}

// Enums for Change Requests
enum ChangeRequestAction { add, update, sell, create, delete, mark_paid }

enum ChangeRequestStatus { pending, approved, rejected }

class ChangeRequest {
  final int id;
  final Product? product;
  final int? quantityChange;
  final ChangeRequestAction action;
  final User requester;
  final String? buyerName;
  final String? paymentStatus;
  final String? newProductName;
  final String? newProductBarcode;
  final double? newProductPrice;
  final int? newProductQuantity;
  final String? newProductCategory;

  ChangeRequest({
    required this.id,
    this.product,
    this.quantityChange,
    required this.action,
    required this.requester,
    this.buyerName,
    this.paymentStatus,
    this.newProductName,
    this.newProductBarcode,
    this.newProductPrice,
    this.newProductQuantity,
    this.newProductCategory,
  });

  factory ChangeRequest.fromJson(Map<String, dynamic> json) {
    return ChangeRequest(
      id: json['id'],
      product:
          json['product'] != null ? Product.fromJson(json['product']) : null,
      quantityChange: json['quantity_change'],
      action: ChangeRequestAction.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => ChangeRequestAction.add,
      ),
      requester: User.fromJson(json['requester']),
      buyerName: json['buyer_name'],
      paymentStatus: json['payment_status'],
      newProductName: json['new_product_name'],
      newProductBarcode: json['new_product_barcode'],
      newProductPrice: json['new_product_price'] != null
          ? (json['new_product_price'] as num).toDouble()
          : null,
      newProductQuantity: json['new_product_quantity'],
      newProductCategory: json['new_product_category'],
    );
  }
}

class ChangeHistory {
  final int id;
  final Product? product;
  final int? quantityChange;
  final ChangeRequestAction action;
  final ChangeRequestStatus status;
  final User requester;
  final User? reviewer;
  final DateTime timestamp;
  final String? buyerName;
  final String? paymentStatus;

  ChangeHistory({
    required this.id,
    this.product,
    this.quantityChange,
    required this.action,
    required this.status,
    required this.requester,
    this.reviewer,
    required this.timestamp,
    this.buyerName,
    this.paymentStatus,
  });

  factory ChangeHistory.fromJson(Map<String, dynamic> json) {
    return ChangeHistory(
      id: json['id'],
      product: json['product'] != null ? Product.fromJson(json['product']) : null,
      quantityChange: json['quantity_change'],
      action: ChangeRequestAction.values.firstWhere((e) => e.name == json['action'], orElse: () => ChangeRequestAction.add),
      status: ChangeRequestStatus.values.firstWhere((e) => e.name == json['status'], orElse: () => ChangeRequestStatus.pending),
      requester: User.fromJson(json['requester']),
      reviewer: json['reviewer'] != null ? User.fromJson(json['reviewer']) : null,
      timestamp: DateTime.parse(json['timestamp']),
      buyerName: json['buyer_name'],
      paymentStatus: json['payment_status'],
    );
  }
}

// More models for Sales and ChangeRequests can be added here later. 