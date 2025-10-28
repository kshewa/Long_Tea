import 'package:longtea_mobile/models/cart_item.dart';

class Order {
  final String id;
  final String userId;
  final String storeId;
  final double total;
  final String status;
  final DateTime pickupTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<OrderItem> items;
  final String? paymentId;

  const Order({
    required this.id,
    required this.userId,
    required this.storeId,
    required this.total,
    required this.status,
    required this.pickupTime,
    this.createdAt,
    this.updatedAt,
    this.items = const [],
    this.paymentId,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final store = json['store'];

    final userId = _extractId(user) ?? json['userId']?.toString() ?? '';
    final storeId = _extractId(store) ?? json['storeId']?.toString() ?? '';

    final itemsJson = (json['items'] as List?) ?? [];

    return Order(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: userId,
      storeId: storeId,
      total: _asDouble(json['total']),
      status: json['status']?.toString() ?? 'pending',
      pickupTime: _parseDate(json['pickupTime']) ?? DateTime.now(),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      items: itemsJson
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      paymentId: _extractId(json['paymentId']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'storeId': storeId,
      'total': total,
      'status': status,
      'pickupTime': pickupTime.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'paymentId': paymentId,
    };
  }

  Order copyWith({
    String? id,
    String? userId,
    String? storeId,
    double? total,
    String? status,
    DateTime? pickupTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<OrderItem>? items,
    String? paymentId,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      storeId: storeId ?? this.storeId,
      total: total ?? this.total,
      status: status ?? this.status,
      pickupTime: pickupTime ?? this.pickupTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      paymentId: paymentId ?? this.paymentId,
    );
  }

  static String? _extractId(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) {
      return value['id']?.toString() ??
          value['_id']?.toString() ??
          value[r'$oid']?.toString();
    }
    return value.toString();
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static double _asDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

class OrderItem {
  final String productId;
  final int quantity;
  final String size;
  final List<String> toppings;
  final List<String> allergyCheck;
  final String? unit;
  final double itemPrice;
  final double totalPrice;

  const OrderItem({
    required this.productId,
    required this.quantity,
    required this.size,
    this.toppings = const [],
    this.allergyCheck = const [],
    this.unit,
    this.itemPrice = 0,
    this.totalPrice = 0,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] ?? json['productId'];
    final productId = Order._extractId(product) ?? '';

    final basePrice = Order._asDouble(json['itemPrice']);
    final total = json['totalPrice'] != null
        ? Order._asDouble(json['totalPrice'])
        : 0.0;
    final quantity = json['quantity'] is num
        ? (json['quantity'] as num).toInt()
        : int.tryParse(json['quantity']?.toString() ?? '') ?? 1;

    return OrderItem(
      productId: productId,
      quantity: quantity,
      size: json['size']?.toString() ?? '',
      toppings: List<String>.from(json['toppings'] ?? const []),
      allergyCheck: List<String>.from(json['allergyCheck'] ?? const []),
      unit: json['unit']?.toString(),
      itemPrice: basePrice,
      totalPrice: total != 0 ? total : basePrice * quantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'size': size,
      'toppings': toppings,
      'allergyCheck': allergyCheck,
      'unit': unit,
      'itemPrice': itemPrice,
      'totalPrice': totalPrice,
    };
  }

  CartItem toCartItem({required String name, String? image}) {
    return CartItem(
      itemId: productId,
      productId: productId,
      productName: name,
      productImage: image,
      quantity: quantity,
      size: size,
      toppings: toppings,
      allergyCheck: allergyCheck,
      unit: unit,
      itemPrice: itemPrice,
      totalPrice: totalPrice,
    );
  }
}
