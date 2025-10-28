import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:longtea_mobile/constants/api_url.dart';
import 'package:longtea_mobile/models/payment.dart';

import 'http_client.dart';

class PaymentService {
  PaymentService._();

  static final PaymentService instance = PaymentService._();

  static const Duration _timeout = Duration(seconds: 30);

  Future<PaymentIntent> initiatePayment({
    required String orderId,
    PaymentMethod? method,
  }) async {
    final uri = Uri.parse('${ApiUrl.paymentUrl}/initiate');
    final payload = {
      'orderId': orderId,
      if (method != null) 'paymentMethod': method.value,
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
          return PaymentIntent.fromJson(
            decoded['data'] as Map<String, dynamic>,
          );
        }
        throw PaymentException(
          message:
              decoded['message']?.toString() ?? 'Failed to initiate payment',
        );
      } else {
        throw PaymentException.fromResponse(decoded, response.statusCode);
      }
    } on http.ClientException catch (e) {
      throw PaymentException(message: 'Network error: ${e.message}');
    }
  }

  Future<PaymentStatus> getPaymentStatus(String transactionId) async {
    final uri = Uri.parse('${ApiUrl.paymentUrl}/status/$transactionId');

    try {
      final response = await authHttpClient.get(uri).timeout(_timeout);

      final decoded = _decodeBody(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded['success'] == true) {
          return PaymentStatus.fromJson(decoded);
        }
        throw PaymentException(
          message:
              decoded['message']?.toString() ??
              'Failed to fetch payment status',
        );
      } else {
        throw PaymentException.fromResponse(decoded, response.statusCode);
      }
    } on http.ClientException catch (e) {
      throw PaymentException(message: 'Network error: ${e.message}');
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

class PaymentException implements Exception {
  final String message;
  final int? statusCode;
  final List<String>? details;

  PaymentException({required this.message, this.statusCode, this.details});

  factory PaymentException.fromResponse(
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

    return PaymentException(
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
