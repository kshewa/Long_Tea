import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../constants/api_url.dart';
import '../models/user.dart';
import 'http_client.dart';

class ProfileService {
  /// Get user profile from backend
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await authHttpClient.get(
        Uri.parse(ApiUrl.profileUrl),
        headers: {"Content-Type": "application/json"},
      );

      debugPrint('=== GET PROFILE RESPONSE ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('===========================');

      final jsonResponse = _safeDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        dynamic data;
        User? user;

        if (jsonResponse is Map) {
          data = jsonResponse["data"];
          if (data is Map<String, dynamic>) {
            user = User.fromJson(data);
          }
        }

        return {
          "success": true,
          "message": (jsonResponse is Map && jsonResponse["message"] is String)
              ? jsonResponse["message"]
              : "Profile retrieved successfully",
          "data": user,
          "statusCode": response.statusCode,
        };
      } else {
        return {
          "success": false,
          "message":
              _extractErrorMessage(jsonResponse) ?? "Failed to get profile",
          "data": null,
          "details": _extractErrorDetails(jsonResponse),
          "statusCode": response.statusCode,
        };
      }
    } catch (e) {
      debugPrint('Get profile error: $e');
      return {
        "success": false,
        "message": e.toString(),
        "data": null,
        "details": const <String>[],
      };
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? email,
    String? phoneNumber,
  }) async {
    try {
      // Build payload with only provided fields
      final Map<String, dynamic> payload = {};

      if (fullName != null && fullName.isNotEmpty) {
        payload["fullName"] = fullName.trim();
      }
      if (email != null && email.isNotEmpty) {
        payload["email"] = email.trim();
      }
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        payload["phoneNumber"] = phoneNumber.trim();
      }

      debugPrint('=== UPDATE PROFILE REQUEST ===');
      debugPrint('URL: ${ApiUrl.profileUrl}');
      debugPrint('Payload: $payload');
      debugPrint('==============================');

      final response = await authHttpClient.put(
        Uri.parse(ApiUrl.profileUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      debugPrint('=== UPDATE PROFILE RESPONSE ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('===============================');

      final jsonResponse = _safeDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        dynamic data;
        User? user;

        if (jsonResponse is Map) {
          data = jsonResponse["data"];
          if (data is Map<String, dynamic>) {
            user = User.fromJson(data);
          }
        }

        return {
          "success": true,
          "message": (jsonResponse is Map && jsonResponse["message"] is String)
              ? jsonResponse["message"]
              : "Profile updated successfully",
          "data": user,
          "statusCode": response.statusCode,
        };
      } else {
        return {
          "success": false,
          "message":
              _extractErrorMessage(jsonResponse) ?? "Failed to update profile",
          "data": null,
          "details": _extractErrorDetails(jsonResponse),
          "statusCode": response.statusCode,
        };
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
      return {
        "success": false,
        "message": e.toString(),
        "data": null,
        "details": const <String>[],
      };
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
        if (item is Map && item["message"] is String) {
          return item["message"] as String;
        }
        if (item is Map && item["field"] is String) {
          final field = item["field"] as String;
          final message = item["message"] is String
              ? item["message"] as String
              : "";
          return "$field: $message";
        }
        return item.toString();
      }).toList();
    }
    return const <String>[];
  }
}
