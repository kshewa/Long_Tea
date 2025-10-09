class CartItem {
  final String itemId;
  final String productId;
  final String productName;
  final String? productImage;
  final int quantity;
  final String size;
  final List<String> toppings;
  final List<String> allergyCheck;
  final String? unit;
  final double itemPrice;
  final double totalPrice;

  const CartItem({
    required this.itemId,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.size,
    this.toppings = const [],
    this.allergyCheck = const [],
    this.unit,
    required this.itemPrice,
    required this.totalPrice,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] ?? {};
    final imageData = product['image'];
    String? imageUrl;

    if (imageData is List && imageData.isNotEmpty) {
      imageUrl = imageData[0]['url'] as String?;
    } else if (imageData is Map) {
      imageUrl = imageData['url'] as String?;
    }

    return CartItem(
      itemId: json['itemId'] ?? json['id'] ?? '',
      productId: product['id'] ?? json['productId'] ?? '',
      productName: product['name'] ?? '',
      productImage: imageUrl,
      quantity: json['quantity'] ?? 1,
      size: json['size'] ?? '',
      toppings: List<String>.from(json['toppings'] ?? []),
      allergyCheck: List<String>.from(json['allergyCheck'] ?? []),
      unit: json['unit'],
      itemPrice: (json['itemPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
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

  CartItem copyWith({
    String? itemId,
    String? productId,
    String? productName,
    String? productImage,
    int? quantity,
    String? size,
    List<String>? toppings,
    List<String>? allergyCheck,
    String? unit,
    double? itemPrice,
    double? totalPrice,
  }) {
    return CartItem(
      itemId: itemId ?? this.itemId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      quantity: quantity ?? this.quantity,
      size: size ?? this.size,
      toppings: toppings ?? this.toppings,
      allergyCheck: allergyCheck ?? this.allergyCheck,
      unit: unit ?? this.unit,
      itemPrice: itemPrice ?? this.itemPrice,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}
