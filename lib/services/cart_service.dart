import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:longtea_mobile/models/cart.dart';
import 'package:longtea_mobile/models/cart_item.dart';
import 'package:longtea_mobile/services/http_client.dart';
import 'package:longtea_mobile/constants/api_url.dart';

class CartService {
  CartService._();
  static final CartService instance = CartService._();

  static const Duration timeout = Duration(seconds: 30);

  final ValueNotifier<Cart?> cartNotifier = ValueNotifier<Cart?>(null);

  Cart? get cart => cartNotifier.value;
  List<CartItem> get items => cartNotifier.value?.items ?? [];
  int get totalItems => cartNotifier.value?.quantityCount ?? 0;
  double get subtotal => cartNotifier.value?.totalprice ?? 0.0;
  bool get isEmpty => cartNotifier.value?.isEmpty ?? true;
  bool get isNotEmpty => !isEmpty;

  /// Add item to cart
  Future<Cart> addToCart({
    required String productId,
    required String storeId,
    required int quantity,
    required String size,
    List<String>? toppings,
    List<String>? allergyCheck,
  }) async {
    try {
      final uri = Uri.parse("${ApiUrl.baseUrl}/cart");
      final body = {
        'productId': productId,
        'storeId': storeId,
        'quantity': quantity,
        'size': size,
        if (toppings != null && toppings.isNotEmpty) 'toppings': toppings,
        if (allergyCheck != null && allergyCheck.isNotEmpty)
          'allergyCheck': allergyCheck,
      };

      final response = await authHttpClient
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          final cart = Cart.fromJson(jsonResponse['data']);
          cartNotifier.value = cart;
          return cart;
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to add to cart');
        }
      } else {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(
          jsonResponse['message'] ?? 'HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Network error: ${e.message}');
      } else {
        rethrow;
      }
    }
  }

  /// Get user's cart
  Future<Cart> getCart() async {
    try {
      final uri = Uri.parse("${ApiUrl.baseUrl}/cart");
      final response = await authHttpClient.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          final cart = Cart.fromJson(jsonResponse['data']);
          cartNotifier.value = cart;
          return cart;
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to fetch cart');
        }
      } else {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(
          jsonResponse['message'] ?? 'HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Network error: ${e.message}');
      } else {
        rethrow;
      }
    }
  }

  /// Update cart item quantity
  Future<Cart> updateCartItem({
    required String itemId,
    required int quantity,
  }) async {
    try {
      final uri = Uri.parse("${ApiUrl.baseUrl}/cart/$itemId");
      final body = {'quantity': quantity};

      final response = await authHttpClient
          .patch(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          final cart = Cart.fromJson(jsonResponse['data']);
          cartNotifier.value = cart;
          return cart;
        } else {
          throw Exception(
            jsonResponse['message'] ?? 'Failed to update cart item',
          );
        }
      } else {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(
          jsonResponse['message'] ?? 'HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Network error: ${e.message}');
      } else {
        rethrow;
      }
    }
  }

  /// Remove item from cart
  Future<Cart> removeCartItem(String itemId) async {
    try {
      final uri = Uri.parse("${ApiUrl.baseUrl}/cart/$itemId");
      final response = await authHttpClient.delete(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          final cart = Cart.fromJson(jsonResponse['data']);
          cartNotifier.value = cart;
          return cart;
        } else {
          throw Exception(
            jsonResponse['message'] ?? 'Failed to remove cart item',
          );
        }
      } else {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(
          jsonResponse['message'] ?? 'HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Network error: ${e.message}');
      } else {
        rethrow;
      }
    }
  }

  /// Clear entire cart
  Future<void> clearCart() async {
    try {
      final uri = Uri.parse("${ApiUrl.baseUrl}/cart/clear");
      final response = await authHttpClient.delete(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          cartNotifier.value = null;
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to clear cart');
        }
      } else {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(
          jsonResponse['message'] ?? 'HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Network error: ${e.message}');
      } else {
        rethrow;
      }
    }
  }

  /// Clear local cart (without API call)
  void clearLocalCart() {
    cartNotifier.value = null;
  }
}
