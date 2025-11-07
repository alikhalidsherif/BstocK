// User roles matching the backend
enum UserRole { owner, cashier }

class User {
  final int id;
  final String username;
  final UserRole role;
  final int? organizationId;
  final bool isActive;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.role,
    this.organizationId,
    required this.isActive,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      role: _parseRole(json['role']),
      organizationId: json['organization_id'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static UserRole _parseRole(dynamic raw) {
    if (raw == null) return UserRole.cashier;
    final String value = raw.toString();
    switch (value) {
      case 'owner':
        return UserRole.owner;
      case 'cashier':
        return UserRole.cashier;
      default:
        if (value.endsWith('.owner')) return UserRole.owner;
        return UserRole.cashier;
    }
  }
}

class Variant {
  final int id;
  final int productId;
  final String sku;
  final String? barcode;
  final Map<String, dynamic>? attributes;
  final double purchasePrice;
  final double salePrice;
  final int quantity;
  final int minStockLevel;
  final String unitType;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Variant({
    required this.id,
    required this.productId,
    required this.sku,
    this.barcode,
    this.attributes,
    required this.purchasePrice,
    required this.salePrice,
    required this.quantity,
    required this.minStockLevel,
    required this.unitType,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      id: json['id'],
      productId: json['product_id'],
      sku: json['sku'],
      barcode: json['barcode'],
      attributes: json['attributes'] != null 
          ? Map<String, dynamic>.from(json['attributes'])
          : null,
      purchasePrice: _parseDecimal(json['purchase_price']),
      salePrice: _parseDecimal(json['sale_price']),
      quantity: json['quantity'],
      minStockLevel: json['min_stock_level'] ?? 0,
      unitType: json['unit_type'] ?? 'pcs',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  static double _parseDecimal(dynamic value) {
    if (value is String) {
      return double.parse(value);
    }
    return (value as num).toDouble();
  }
}

class Product {
  final int id;
  final String name;
  final String? description;
  final String? category;
  final int organizationId;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<Variant> variants;

  Product({
    required this.id,
    required this.name,
    this.description,
    this.category,
    required this.organizationId,
    required this.isArchived,
    required this.createdAt,
    this.updatedAt,
    required this.variants,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      organizationId: json['organization_id'],
      isArchived: json['is_archived'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      variants: (json['variants'] as List<dynamic>?)
              ?.map((v) => Variant.fromJson(v))
              .toList() ??
          [],
    );
  }
}

class Customer {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final int organizationId;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    required this.organizationId,
    required this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      organizationId: json['organization_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Vendor {
  final int id;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final int organizationId;
  final DateTime createdAt;

  Vendor({
    required this.id,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    required this.organizationId,
    required this.createdAt,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'],
      name: json['name'],
      contactPerson: json['contact_person'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      organizationId: json['organization_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

enum PaymentMethod { cash, card, mobile, bank_transfer }

class SaleItem {
  final int id;
  final int saleId;
  final int variantId;
  final int quantity;
  final double priceAtSale;
  final double purchasePriceAtSale;
  final Variant? variant;

  SaleItem({
    required this.id,
    required this.saleId,
    required this.variantId,
    required this.quantity,
    required this.priceAtSale,
    required this.purchasePriceAtSale,
    this.variant,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['id'],
      saleId: json['sale_id'],
      variantId: json['variant_id'],
      quantity: json['quantity'],
      priceAtSale: _parseDecimal(json['price_at_sale']),
      purchasePriceAtSale: _parseDecimal(json['purchase_price_at_sale']),
      variant: json['variant'] != null ? Variant.fromJson(json['variant']) : null,
    );
  }

  static double _parseDecimal(dynamic value) {
    if (value is String) {
      return double.parse(value);
    }
    return (value as num).toDouble();
  }
}

class Sale {
  final int id;
  final int organizationId;
  final int cashierId;
  final int? customerId;
  final double subtotal;
  final double tax;
  final double discount;
  final double totalAmount;
  final double profit;
  final PaymentMethod paymentMethod;
  final String? paymentProofUrl;
  final String? notes;
  final bool synced;
  final DateTime createdAt;
  final List<SaleItem> items;
  final User? cashier;
  final Customer? customer;

  Sale({
    required this.id,
    required this.organizationId,
    required this.cashierId,
    this.customerId,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.totalAmount,
    required this.profit,
    required this.paymentMethod,
    this.paymentProofUrl,
    this.notes,
    required this.synced,
    required this.createdAt,
    required this.items,
    this.cashier,
    this.customer,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'],
      organizationId: json['organization_id'],
      cashierId: json['cashier_id'],
      customerId: json['customer_id'],
      subtotal: _parseDecimal(json['subtotal']),
      tax: _parseDecimal(json['tax']),
      discount: _parseDecimal(json['discount']),
      totalAmount: _parseDecimal(json['total_amount']),
      profit: _parseDecimal(json['profit']),
      paymentMethod: _parsePaymentMethod(json['payment_method']),
      paymentProofUrl: json['payment_proof_url'],
      notes: json['notes'],
      synced: json['synced'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => SaleItem.fromJson(item))
              .toList() ??
          [],
      cashier: json['cashier'] != null ? User.fromJson(json['cashier']) : null,
      customer: json['customer'] != null ? Customer.fromJson(json['customer']) : null,
    );
  }

  static double _parseDecimal(dynamic value) {
    if (value is String) {
      return double.parse(value);
    }
    return (value as num).toDouble();
  }

  static PaymentMethod _parsePaymentMethod(dynamic value) {
    final str = value.toString();
    switch (str) {
      case 'cash':
        return PaymentMethod.cash;
      case 'card':
        return PaymentMethod.card;
      case 'mobile':
        return PaymentMethod.mobile;
      case 'bank_transfer':
        return PaymentMethod.bank_transfer;
      default:
        return PaymentMethod.cash;
    }
  }
}

class BestSellingVariant {
  final int variantId;
  final String sku;
  final String productName;
  final int totalQuantitySold;
  final double totalRevenue;

  BestSellingVariant({
    required this.variantId,
    required this.sku,
    required this.productName,
    required this.totalQuantitySold,
    required this.totalRevenue,
  });

  factory BestSellingVariant.fromJson(Map<String, dynamic> json) {
    return BestSellingVariant(
      variantId: json['variant_id'],
      sku: json['sku'],
      productName: json['product_name'],
      totalQuantitySold: json['total_quantity_sold'],
      totalRevenue: _parseDecimal(json['total_revenue']),
    );
  }

  static double _parseDecimal(dynamic value) {
    if (value is String) {
      return double.parse(value);
    }
    return (value as num).toDouble();
  }
}

class AnalyticsSummary {
  final double totalRevenue;
  final double totalProfit;
  final int totalSalesCount;
  final List<BestSellingVariant> bestSellingVariants;

  AnalyticsSummary({
    required this.totalRevenue,
    required this.totalProfit,
    required this.totalSalesCount,
    required this.bestSellingVariants,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      totalRevenue: _parseDecimal(json['total_revenue']),
      totalProfit: _parseDecimal(json['total_profit']),
      totalSalesCount: json['total_sales_count'],
      bestSellingVariants: (json['best_selling_variants'] as List<dynamic>)
          .map((item) => BestSellingVariant.fromJson(item))
          .toList(),
    );
  }

  static double _parseDecimal(dynamic value) {
    if (value is String) {
      return double.parse(value);
    }
    return (value as num).toDouble();
  }
}
