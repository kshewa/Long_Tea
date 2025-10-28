import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:longtea_mobile/constants/api_url.dart';
import 'package:longtea_mobile/models/cart_item.dart';
import 'package:longtea_mobile/models/order.dart';

import 'http_client.dart';

class OrderService {
  OrderService._();

  static final OrderService instance = OrderService._();

  static const Duration _timeout = Duration(seconds: 30);

  Future<Order> createOrder({
    required String storeId,
    required DateTime pickupTime,
    required List<OrderItemPayload> items,
  }) async {
    final uri = Uri.parse(ApiUrl.orderUrl);
    final payload = {
      'storeId': storeId,
      'pickupTime': pickupTime.toUtc().toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };

    try {
      final response = await authHttpClient
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      final decoded = _decodeBody(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded['success'] == true && decoded['data'] != null) {
          return Order.fromJson(decoded['data'] as Map<String, dynamic>);
        }
        throw OrderException(
          message: decoded['message']?.toString() ?? 'Failed to create order',
        );
      } else {
        throw OrderException.fromResponse(decoded, response.statusCode);
      }
    } on http.ClientException catch (e) {
      throw OrderException(message: 'Network error: ${e.message}');
    }
  }

  Future<List<Order>> fetchOrders() async {
    final uri = Uri.parse(ApiUrl.orderUrl);

    try {
      final response = await authHttpClient.get(uri).timeout(_timeout);

      final decoded = _decodeBody(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = decoded['data'];
        if (data is List) {
          return data
              .map((order) => Order.fromJson(order as Map<String, dynamic>))
              .toList();
        }
        return [];
      }

      if (response.statusCode == 404) {
        return [];
      }

      throw OrderException.fromResponse(decoded, response.statusCode);
    } on http.ClientException catch (e) {
      throw OrderException(message: 'Network error: ${e.message}');
    }
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    if (response.body.isEmpty) return {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'data': decoded};
    } catch (e) {
      return {
        'message':
            'Unexpected response (${response.statusCode}): ${response.body}',
      };
    }
  }
}

class OrderItemPayload {
  final String productId;
  final int quantity;
  final String size;
  final List<String> toppings;
  final List<String> allergyCheck;

  const OrderItemPayload({
    required this.productId,
    required this.quantity,
    required this.size,
    this.toppings = const [],
    this.allergyCheck = const [],
  });

  factory OrderItemPayload.fromCartItem(CartItem item) {
    return OrderItemPayload(
      productId: item.productId,
      quantity: item.quantity,
      size: item.size,
      toppings: item.toppings,
      allergyCheck: item.allergyCheck,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'size': size,
      if (toppings.isNotEmpty) 'toppings': toppings,
      if (allergyCheck.isNotEmpty) 'allergyCheck': allergyCheck,
    };
  }
}

class OrderException implements Exception {
  final String message;
  final int? statusCode;
  final List<String>? details;

  OrderException({required this.message, this.statusCode, this.details});

  factory OrderException.fromResponse(
    Map<String, dynamic> response,
    int statusCode,
  ) {
    final details = response['details'];
    List<String>? parsedDetails;

    if (details is List) {
      parsedDetails = details
          .map((detail) {
            if (detail is String) return detail;
            if (detail is Map && detail['message'] != null) {
              return detail['message'].toString();
            }
            return detail.toString();
          })
          .cast<String>()
          .toList();
    }

    return OrderException(
      message:
          response['message']?.toString() ??
          'Failed with status code $statusCode',
      statusCode: statusCode,
      details: parsedDetails,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer(message);
    if (details != null && details!.isNotEmpty) {
      buffer.write(': ${details!.join(", ")}');
    }
    return buffer.toString();
  }
}
