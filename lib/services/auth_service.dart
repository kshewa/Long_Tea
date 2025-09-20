import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../constants/api_url.dart';
import 'session_manager.dart';
import 'http_client.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String emailOrPhone, String password) async {
    try {
      // Backend expects a single key: emailOrPhone
      final Map<String, dynamic> payload = {
        "emailOrPhone": emailOrPhone,
        "password": password,
         "clientMode" : "mobile-app"
      };

      // No auth header needed for login, but keep Content-Type
      final response = await authHttpClient.post(
        Uri.parse(ApiUrl.loginUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      debugPrint('LOGIN status=${response.statusCode}');
      debugPrint('LOGIN body=${response.body}');

      final jsonResponse = _safeDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        
        dynamic data;
        String? accessToken;
        String? refreshToken;
        Map<String, dynamic>? user;
        if (jsonResponse is Map) {
          data = jsonResponse["data"];
          if (data is Map) {
            if (data["accessToken"] is String) accessToken = data["accessToken"] as String;
            if (data["refreshToken"] is String) refreshToken = data["refreshToken"] as String;
            if (data["user"] is Map<String, dynamic>) {
              user = Map<String, dynamic>.from(data["user"] as Map);
            }
          }
        }

        // Persist tokens for session continuity
        final tokenToSave = accessToken;
        if (tokenToSave != null && tokenToSave.isNotEmpty) {
          await SessionManager.saveAuthSession(
            accessToken: tokenToSave,
            refreshToken: refreshToken,
            userJson: user != null ? jsonEncode(user) : null,
          );
        }

        return {
          "success": (jsonResponse is Map && jsonResponse["success"] is bool)
              ? jsonResponse["success"]
              : true,
          "message": (jsonResponse is Map && jsonResponse["message"] is String)
              ? jsonResponse["message"]
              : "Login successful",
          "data": {
            "accessToken": accessToken,
            "user": user,
            "raw": data ?? jsonResponse,
          },
          "details": const <String>[],
          "statusCode": response.statusCode,
        };
        
      } else {
        return {
          "success": false,
          "message": _extractErrorMessage(jsonResponse) ?? "Login failed",
          "data": null,
          "details": _extractErrorDetails(jsonResponse),
          "statusCode": response.statusCode,
        };
      }
    } catch (e) {
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
        if (item is Map && item["message"] is String) return item["message"] as String;
        return item.toString();
      }).toList();
    }
    return const <String>[];
  }
}