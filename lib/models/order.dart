import 'package:longtea_mobile/models/cart_item.dart';

class Order {
  final String id;
  final String userId;
  final String storeId;
  final String? storeName;
  final String? storeLocation;
  final double total;
  final String status;
  final DateTime pickupTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<OrderItem> items;
  final String? paymentId;
  final String? paymentStatus;
  final double? paymentAmount;
  final int? paymentRetryCount;

  const Order({
    required this.id,
    required this.userId,
    required this.storeId,
    this.storeName,
    this.storeLocation,
    required this.total,
    required this.status,
    required this.pickupTime,
    this.createdAt,
    this.updatedAt,
    this.items = const [],
    this.paymentId,
    this.paymentStatus,
    this.paymentAmount,
    this.paymentRetryCount,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final store = json['store'];

    final userId = _extractId(user) ?? json['userId']?.toString() ?? '';
    final storeId = _extractId(store) ?? json['storeId']?.toString() ?? '';
    String? storeName;
    String? storeLocation;
    if (store is Map) {
      storeName = store['name']?.toString();
      storeLocation = store['location']?.toString();
    }

    final itemsJson = (json['items'] as List?) ?? [];

    final paymentMap = json['payment'] ?? json['paymentId'];
    String? paymentId = _extractId(paymentMap);
    String? paymentStatus;
    double? paymentAmount;
    int? paymentRetryCount;
    if (paymentMap is Map) {
      paymentStatus =
          paymentMap['Paymentstatus']?.toString() ??
          paymentMap['status']?.toString();
      paymentAmount = _asDouble(paymentMap['amount']);
      paymentRetryCount = paymentMap['retryCount'] is num
          ? (paymentMap['retryCount'] as num).toInt()
          : int.tryParse(paymentMap['retryCount']?.toString() ?? '');
    }

    return Order(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: userId,
      storeId: storeId,
      storeName: storeName,
      storeLocation: storeLocation,
      total: _asDouble(json['total']),
      status: json['status']?.toString() ?? 'pending',
      pickupTime: _parseDate(json['pickupTime']) ?? DateTime.now(),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      items: itemsJson
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      paymentId: paymentId,
      paymentStatus: paymentStatus,
      paymentAmount: paymentAmount,
      paymentRetryCount: paymentRetryCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'storeId': storeId,
      'storeName': storeName,
      'storeLocation': storeLocation,
      'total': total,
      'status': status,
      'pickupTime': pickupTime.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'paymentId': paymentId,
      'paymentStatus': paymentStatus,
      'paymentAmount': paymentAmount,
      'paymentRetryCount': paymentRetryCount,
    };
  }

  Order copyWith({
    String? id,
    String? userId,
    String? storeId,
    String? storeName,
    String? storeLocation,
    double? total,
    String? status,
    DateTime? pickupTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<OrderItem>? items,
    String? paymentId,
    String? paymentStatus,
    double? paymentAmount,
    int? paymentRetryCount,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      storeLocation: storeLocation ?? this.storeLocation,
      total: total ?? this.total,
      status: status ?? this.status,
      pickupTime: pickupTime ?? this.pickupTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      paymentId: paymentId ?? this.paymentId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      paymentRetryCount: paymentRetryCount ?? this.paymentRetryCount,
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
  final String? productName;
  final String? productImage;
  final int quantity;
  final String size;
  final List<String> toppings;
  final List<String> allergyCheck;
  final String? unit;
  final double itemPrice;
  final double totalPrice;

  const OrderItem({
    required this.productId,
    this.productName,
    this.productImage,
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
    String? productName;
    String? productImage;
    if (product is Map) {
      productName = product['name']?.toString();
      final image = product['image'];
      if (image is List && image.isNotEmpty) {
        productImage = image.first['url']?.toString();
      } else if (image is Map) {
        productImage = image['url']?.toString();
      }
    }

    final basePrice = Order._asDouble(json['itemPrice']);
    final total = json['totalPrice'] != null
        ? Order._asDouble(json['totalPrice'])
        : 0.0;
    final quantity = json['quantity'] is num
        ? (json['quantity'] as num).toInt()
        : int.tryParse(json['quantity']?.toString() ?? '') ?? 1;

    return OrderItem(
      productId: productId,
      productName: productName,
      productImage: productImage,
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
      'productName': productName,
      'productImage': productImage,
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
      productName: productName ?? name,
      productImage: productImage ?? image,
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
