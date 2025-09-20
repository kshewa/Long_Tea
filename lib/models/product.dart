class Product {
  final String id;
  final String name;
  final String description;
  final ProductImage image;
  final int SKU;
  final String unit;
  final String series;
  final List<String> ingredients;
  final List<ProductSize> sizes;
  final bool isFastingFriendly;
  final List<String> toppings;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.SKU,
    required this.unit,
    required this.series,
    required this.ingredients,
    required this.sizes,
    required this.isFastingFriendly,
    required this.toppings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json["id"] ?? json["_id"] ?? "",
      name: json["name"] ?? "",
      description: json["description"] ?? "",
      image: ProductImage.fromJson(json["image"] ?? {}),
      SKU: json["SKU"] ?? 0,
      unit: json["unit"] ?? "",
      series: json["series"] ?? "",
      ingredients: List<String>.from(json["ingredients"] ?? []),
      sizes: (json["sizes"] as List? ?? [])
          .map((e) => ProductSize.fromJson(e))
          .toList(),
      isFastingFriendly: json["isFastingFriendly"] ?? false,
      toppings: List<String>.from(json["toppings"] ?? []),
      createdAt: DateTime.tryParse(json["createdAt"] ?? "") ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json["updatedAt"] ?? "") ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "description": description,
      "image": image.toJson(),
      "SKU": SKU,
      "unit": unit,
      "series": series,
      "ingredients": ingredients,
      "sizes": sizes.map((e) => e.toJson()).toList(),
      "isFastingFriendly": isFastingFriendly,
      "toppings": toppings,
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  double get minPrice {
    if (sizes.isEmpty) return 0.0;
    return sizes.map((size) => size.price).reduce((a, b) => a < b ? a : b);
  }

  double get maxPrice {
    if (sizes.isEmpty) return 0.0;
    return sizes.map((size) => size.price).reduce((a, b) => a > b ? a : b);
  }

  String get priceRange {
    if (sizes.isEmpty) return "N/A";
    if (sizes.length == 1) return "\$${sizes.first.price.toStringAsFixed(2)}";
    return "\$${minPrice.toStringAsFixed(2)} - \$${maxPrice.toStringAsFixed(2)}";
  }
}

class ProductImage {
  final String url;
  final String publicId;

  ProductImage({required this.url, required this.publicId});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      url: json["url"] ?? "",
      publicId: json["public_id"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "url": url,
      "public_id": publicId,
    };
  }
}

class ProductSize {
  final String label;
  final double price;

  ProductSize({required this.label, required this.price});

  factory ProductSize.fromJson(Map<String, dynamic> json) {
    return ProductSize(
      label: json["label"] ?? "",
      price: (json["price"] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "label": label,
      "price": price,
    };
  }
}
