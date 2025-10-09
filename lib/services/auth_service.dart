import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../constants/api_url.dart';
import 'session_manager.dart';
import 'http_client.dart';

class AuthService {
  Future<Map<String, dynamic>> login(
    String emailOrPhone,
    String password,
  ) async {
    try {
      // Backend expects a single key: emailOrPhone
      final Map<String, dynamic> payload = {
        "emailOrPhone": emailOrPhone,
        "password": password,
        "clientMode": "mobile-app",
      };

      final loginUrl = ApiUrl.loginUrl;
      final headers = {"Content-Type": "application/json"};
      final body = jsonEncode(payload);

      // Debug print request details
      debugPrint('=== LOGIN REQUEST DEBUG ===');
      debugPrint('URL: $loginUrl');
      debugPrint('Headers: $headers');
      debugPrint('Payload: $payload');
      debugPrint('Body JSON: $body');
      debugPrint('========================');

      // No auth header needed for login, but keep Content-Type
      final response = await authHttpClient.post(
        Uri.parse(loginUrl),
        headers: headers,
        body: body,
      );

      // Debug print response details
      debugPrint('=== LOGIN RESPONSE DEBUG ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Status Reason: ${response.reasonPhrase}');
      debugPrint('Response Headers: ${response.headers}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('============================');

      final jsonResponse = _safeDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        dynamic data;
        String? accessToken;
        String? refreshToken;
        Map<String, dynamic>? user;
        DateTime? accessTokenExpiresAt;
        DateTime? refreshTokenExpiresAt;

        if (jsonResponse is Map) {
          data = jsonResponse["data"];
          if (data is Map) {
            if (data["accessToken"] is String) {
              accessToken = data["accessToken"] as String;
            }
            if (data["refreshToken"] is String) {
              refreshToken = data["refreshToken"] as String;
            }
            if (data["user"] is Map<String, dynamic>) {
              user = Map<String, dynamic>.from(data["user"] as Map);
            }

            // Parse token expiry times
            if (data["accessTokenExpiresAt"] is String) {
              try {
                accessTokenExpiresAt = DateTime.parse(
                  data["accessTokenExpiresAt"] as String,
                );
              } catch (e) {
                debugPrint('Failed to parse accessTokenExpiresAt: $e');
              }
            }
            if (data["refreshTokenExpiresAt"] is String) {
              try {
                refreshTokenExpiresAt = DateTime.parse(
                  data["refreshTokenExpiresAt"] as String,
                );
              } catch (e) {
                debugPrint('Failed to parse refreshTokenExpiresAt: $e');
              }
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
            accessTokenExpiresAt: accessTokenExpiresAt,
            refreshTokenExpiresAt: refreshTokenExpiresAt,
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
            "refreshToken": refreshToken,
            "user": user,
            "accessTokenExpiresAt": accessTokenExpiresAt,
            "refreshTokenExpiresAt": refreshTokenExpiresAt,
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
      // Debug print exception details
      debugPrint('=== LOGIN EXCEPTION DEBUG ===');
      debugPrint('Exception: $e');
      debugPrint('Exception Type: ${e.runtimeType}');
      debugPrint('Stack Trace: ${StackTrace.current}');
      debugPrint('=============================');

      return {
        "success": false,
        "message": e.toString(),
        "data": null,
        "details": const <String>[],
      };
    }
  }

  /// Refresh access token using the stored refresh token
  Future<Map<String, dynamic>> refreshAccessToken() async {
    try {
      final refreshToken = await SessionManager.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        return {
          "success": false,
          "message": "No refresh token available",
          "data": null,
        };
      }

      final Map<String, dynamic> payload = {
        "refreshToken": refreshToken,
        "clientMode": "mobile-app",
      };

      final response = await authHttpClient.post(
        Uri.parse(ApiUrl.refreshUrl),
        headers: {
          "Content-Type": "application/json",
          "x-refresh-token": refreshToken,
        },
        body: jsonEncode(payload),
      );

      debugPrint('REFRESH TOKEN status=${response.statusCode}');
      debugPrint('REFRESH TOKEN body=${response.body}');

      final jsonResponse = _safeDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        dynamic data;
        String? accessToken;
        String? newRefreshToken;
        DateTime? accessTokenExpiresAt;
        DateTime? refreshTokenExpiresAt;

        if (jsonResponse is Map) {
          data = jsonResponse["data"];
          if (data is Map) {
            if (data["accessToken"] is String) {
              accessToken = data["accessToken"] as String;
            }
            if (data["refreshToken"] is String) {
              newRefreshToken = data["refreshToken"] as String;
            }

            // Parse token expiry times
            if (data["accessTokenExpiresAt"] is String) {
              try {
                accessTokenExpiresAt = DateTime.parse(
                  data["accessTokenExpiresAt"] as String,
                );
              } catch (e) {
                debugPrint('Failed to parse accessTokenExpiresAt: $e');
              }
            }
            if (data["refreshTokenExpiresAt"] is String) {
              try {
                refreshTokenExpiresAt = DateTime.parse(
                  data["refreshTokenExpiresAt"] as String,
                );
              } catch (e) {
                debugPrint('Failed to parse refreshTokenExpiresAt: $e');
              }
            }
          }
        }

        // Update stored tokens
        if (accessToken != null && accessToken.isNotEmpty) {
          // Get existing user data
          final userJson = await SessionManager.getUserJson();

          await SessionManager.saveAuthSession(
            accessToken: accessToken,
            refreshToken: newRefreshToken ?? refreshToken,
            userJson: userJson,
            accessTokenExpiresAt: accessTokenExpiresAt,
            refreshTokenExpiresAt: refreshTokenExpiresAt,
          );
        }

        return {
          "success": true,
          "message": "Token refreshed successfully",
          "data": {
            "accessToken": accessToken,
            "refreshToken": newRefreshToken ?? refreshToken,
            "accessTokenExpiresAt": accessTokenExpiresAt,
            "refreshTokenExpiresAt": refreshTokenExpiresAt,
          },
          "statusCode": response.statusCode,
        };
      } else {
        // If refresh fails, clear session
        await SessionManager.clear();

        return {
          "success": false,
          "message":
              _extractErrorMessage(jsonResponse) ?? "Token refresh failed",
          "data": null,
          "statusCode": response.statusCode,
        };
      }
    } catch (e) {
      debugPrint('Token refresh error: $e');
      return {"success": false, "message": e.toString(), "data": null};
    }
  }

  /// Register new user
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String password,
    String? email,
    String? phoneNumber,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        "fullName": fullName,
        "password": password,
      };

      // Add email if provided
      if (email != null && email.isNotEmpty) {
        payload["email"] = email;
      }

      // Add phoneNumber if provided
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        payload["phoneNumber"] = phoneNumber;
      }

      final response = await authHttpClient.post(
        Uri.parse(ApiUrl.registerUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      debugPrint('REGISTER status=${response.statusCode}');
      debugPrint('REGISTER body=${response.body}');

      final jsonResponse = _safeDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          "success": true,
          "message": (jsonResponse is Map && jsonResponse["message"] is String)
              ? jsonResponse["message"]
              : "Registration successful",
          "data": (jsonResponse is Map) ? jsonResponse["data"] : null,
          "details": const <String>[],
          "statusCode": response.statusCode,
        };
      } else {
        return {
          "success": false,
          "message":
              _extractErrorMessage(jsonResponse) ?? "Registration failed",
          "data": null,
          "details": _extractErrorDetails(jsonResponse),
          "statusCode": response.statusCode,
        };
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      return {
        "success": false,
        "message": e.toString(),
        "data": null,
        "details": const <String>[],
      };
    }
  }

  /// Logout user by clearing session
  Future<void> logout() async {
    await SessionManager.clear();
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
        if (item is Map && item["message"] is String)
          return item["message"] as String;
        return item.toString();
      }).toList();
    }
    return const <String>[];
  }
}
