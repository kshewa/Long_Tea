// lib/services/register_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../constants/api_url.dart';
import 'http_client.dart';

class RegisterService {
  // Register new user
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    String role = "customer",
  }) async {
    try {
      final response = await authHttpClient.post(
        Uri.parse(ApiUrl.registerUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fullName": fullName,
          "email": email,
          "phoneNumber": phoneNumber ?? "",
          "password": password,
          "role": role,
        }),
      );

      debugPrint('REGISTER status=${response.statusCode}');
      debugPrint('REGISTER body=${response.body}');

      final decoded = _safeDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          "success": true,
          "message": (decoded is Map && decoded["message"] is String)
              ? decoded["message"]
              : "Registration successful",
          "data": (decoded is Map) ? decoded["data"] : decoded,
          "details": const <String>[],
          "statusCode": response.statusCode,
        };
      }

      return {
        "success": false,
        "message": _extractErrorMessage(decoded) ?? "Registration failed",
        "details": _extractErrorDetails(decoded),
        "data": null,
        "statusCode": response.statusCode,
      };
    } catch (e) {
      debugPrint('REGISTER error=$e');
      return {"success": false, "message": e.toString()};
    }
  }

  dynamic _safeDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return {"message": body};
    }
  }

  String? _extractErrorMessage(dynamic err) {
    if (err is Map<String, dynamic>) {
      if (err["message"] is String) return err["message"] as String;
      if (err["error"] is String) return err["error"] as String;
    }
    return null;
  }

  List<String> _extractErrorDetails(dynamic err) {
    if (err is Map<String, dynamic> && err["details"] is List) {
      final list = err["details"] as List;
      return list.map<String>((item) {
        if (item is Map && item["message"] is String) return item["message"] as String;
        return item.toString();
      }).toList();
    }
    return const <String>[];
  }
}