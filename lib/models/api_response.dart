import 'product.dart';
import 'pagination.dart';
import 'store.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Pagination? pagination;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.pagination,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(List<dynamic>) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
      data: json["data"] != null ? fromJsonT(json["data"]) : null,
      pagination: json["pagination"] != null
          ? Pagination.fromJson(json["pagination"])
          : null,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return {
      "success": success,
      "message": message,
      "data": data != null ? toJsonT(data as T) : null,
      "pagination": pagination?.toJson(),
    };
  }
}

class ProductListResponse {
  final List<Product> products;
  final Pagination pagination;

  ProductListResponse({required this.products, required this.pagination});

  factory ProductListResponse.fromJson(Map<String, dynamic> json) {
    return ProductListResponse(
      products: (json["data"] as List? ?? [])
          .map((item) => Product.fromJson(item))
          .toList(),
      pagination: Pagination.fromJson(json["pagination"] ?? {}),
    );
  }
}

class ProductWithStoresResponse {
  final Product product;
  final List<Store> availableStores;

  ProductWithStoresResponse({
    required this.product,
    required this.availableStores,
  });

  factory ProductWithStoresResponse.fromJson(Map<String, dynamic> json) {
    // The API response structure has product fields directly in data
    // and stores as a separate array within data
    final data = json["data"];

    // Create a copy of data for product parsing (excluding stores)
    final productData = Map<String, dynamic>.from(data);
    productData.remove('stores'); // Remove stores array from product data

    return ProductWithStoresResponse(
      product: Product.fromJson(productData),
      availableStores: (data["stores"] as List? ?? [])
          .map((storeItem) => Store.fromJson(storeItem))
          .toList(),
    );
  }
}
