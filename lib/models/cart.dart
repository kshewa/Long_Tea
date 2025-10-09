import 'package:longtea_mobile/models/cart_item.dart';

class Cart {
  final String? id;
  final String userId;
  final String? storeId;
  final String? storeName;
  final List<CartItem> items;
  final double totalprice;
  final int itemCount;
  final int quantityCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Cart({
    this.id,
    required this.userId,
    this.storeId,
    this.storeName,
    required this.items,
    required this.totalprice,
    required this.itemCount,
    required this.quantityCount,
    this.createdAt,
    this.updatedAt,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    final storeData = json['store'];
    String? storeName;
    String? storeId;

    if (storeData is Map) {
      storeName = storeData['name'] as String?;
      storeId = storeData['id'] as String?;
    }

    return Cart(
      id: json['id'] as String?,
      userId: json['userId'] ?? json['user']?['id'] ?? '',
      storeId: storeId ?? json['storeId'] as String?,
      storeName: storeName,
      items:
          (json['items'] as List?)
              ?.map((item) => CartItem.fromJson(item))
              .toList() ??
          [],
      totalprice: (json['totalprice'] as num?)?.toDouble() ?? 0.0,
      itemCount: json['itemCount'] ?? 0,
      quantityCount: json['quantityCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'storeId': storeId,
      'items': items.map((item) => item.toJson()).toList(),
      'totalprice': totalprice,
      'itemCount': itemCount,
      'quantityCount': quantityCount,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Cart copyWith({
    String? id,
    String? userId,
    String? storeId,
    String? storeName,
    List<CartItem>? items,
    double? totalprice,
    int? itemCount,
    int? quantityCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cart(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      items: items ?? this.items,
      totalprice: totalprice ?? this.totalprice,
      itemCount: itemCount ?? this.itemCount,
      quantityCount: quantityCount ?? this.quantityCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
}
