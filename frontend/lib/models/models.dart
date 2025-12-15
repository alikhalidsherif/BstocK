// Used to represent user roles from the backend
enum UserRole { clerk, admin, supervisor }

class User {
  final int id;
  final String username;
  final UserRole role;
  final bool isMaster;

  const User({
    required this.id,
    required this.username,
    required this.role,
    this.isMaster = false,
  });

  factory User.deletedPlaceholder() {
    return const User(id: -1, username: 'Deleted user', role: UserRole.clerk);
  }

  factory User.fromJson(dynamic json) {
    if (json == null) {
      return User.deletedPlaceholder();
    }
    return User(
      id: json['id'] ?? -1,
      username: json['username'] ?? 'Deleted user',
      role: _parseRole(json['role']),
      isMaster: json['is_master'] ?? false,
    );
  }

  static UserRole _parseRole(dynamic raw) {
    if (raw == null) return UserRole.clerk;
    final String value = raw.toString();
    // Accept backend enum values like 'clerk', 'admin', 'supervisor'
    switch (value) {
      case 'clerk':
        return UserRole.clerk;
      case 'admin':
        return UserRole.admin;
      case 'supervisor':
        return UserRole.supervisor;
      default:
        // Also accept prefixed names like 'UserRole.admin'
        if (value.endsWith('.admin')) return UserRole.admin;
        if (value.endsWith('.supervisor')) return UserRole.supervisor;
        return UserRole.clerk;
      }
  }
}

class Product {
  final int id;
  final String barcode;
  final String name;
  final double price;
  final int quantity;
  final String category;
  final bool isArchived;

  Product({
    required this.id,
    required this.barcode,
    required this.name,
    required this.price,
    required this.quantity,
    required this.category,
    this.isArchived = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      barcode: json['barcode'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'],
      category: json['category'] ?? 'Uncategorized',
      isArchived: json['is_archived'] ?? false,
    );
  }
}

// Enums for Change Requests
enum ChangeRequestAction { add, update, sell, create, archive, restore, delete, mark_paid }

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
  final User reviewer;
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
    required this.reviewer,
    required this.timestamp,
    this.buyerName,
    this.paymentStatus,
  });

  factory ChangeHistory.fromJson(Map<String, dynamic> json) {
    final requesterJson = json['requester'];
    final reviewerJson = json['reviewer'];
    return ChangeHistory(
      id: json['id'],
      product: json['product'] != null ? Product.fromJson(json['product']) : null,
      quantityChange: json['quantity_change'],
      action: ChangeRequestAction.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => ChangeRequestAction.add,
      ),
      status: ChangeRequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ChangeRequestStatus.pending,
      ),
      requester: User.fromJson(requesterJson),
      reviewer: reviewerJson != null ? User.fromJson(reviewerJson) : User.deletedPlaceholder(),
      timestamp: DateTime.parse(json['timestamp']),
      buyerName: json['buyer_name'],
      paymentStatus: json['payment_status'],
    );
  }
}

// More models for Sales and ChangeRequests can be added here later. 