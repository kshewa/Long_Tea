import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../constants/api_url.dart';
import 'http_client.dart';

class PasswordResetService {
  /// Step 1: Request OTP for password reset
  /// Sends OTP to email or phone
  Future<Map<String, dynamic>> requestResetOTP(String emailOrPhone) async {
    try {
      final response = await authHttpClient.post(
        Uri.parse('${ApiUrl.baseUrl}/auth/reset/request-otp'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"emailOrPhone": emailOrPhone}),
      );

      debugPrint('REQUEST OTP status=${response.statusCode}');
      debugPrint('REQUEST OTP body=${response.body}');

      final jsonResponse = _safeDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          "success": true,
          "message": (jsonResponse is Map && jsonResponse["message"] is String)
              ? jsonResponse["message"]
              : "OTP sent successfully",
          "data": (jsonResponse is Map) ? jsonResponse["data"] : null,
          "statusCode": response.statusCode,
        };
      } else {
        return {
          "success": false,
          "message": _extractErrorMessage(jsonResponse) ?? "Failed to send OTP",
          "data": null,
          "details": _extractErrorDetails(jsonResponse),
          "statusCode": response.statusCode,
        };
      }
    } catch (e) {
      debugPrint('REQUEST OTP error: $e');
      return {"success": false, "message": e.toString(), "data": null};
    }
  }

  /// Step 2: Verify OTP and get reset token
  Future<Map<String, dynamic>> verifyResetOTP(
    String emailOrPhone,
    String otpCode,
  ) async {
    try {
      final response = await authHttpClient.post(
        Uri.parse('${ApiUrl.baseUrl}/auth/reset/verify-otp'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"emailOrPhone": emailOrPhone, "otpCode": otpCode}),
      );

      debugPrint('VERIFY OTP status=${response.statusCode}');
      debugPrint('VERIFY OTP body=${response.body}');

      final jsonResponse = _safeDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        String? resetToken;
        int? expiresIn;

        if (jsonResponse is Map) {
          final data = jsonResponse["data"];
          if (data is Map) {
            if (data["resetToken"] is String) {
              resetToken = data["resetToken"] as String;
            }
            if (data["expiresIn"] is int) {
              expiresIn = data["expiresIn"] as int;
            }
          }
        }

        return {
          "success": true,
          "message": (jsonResponse is Map && jsonResponse["message"] is String)
              ? jsonResponse["message"]
              : "OTP verified successfully",
          "data": {"resetToken": resetToken, "expiresIn": expiresIn},
          "statusCode": response.statusCode,
        };
      } else {
        return {
          "success": false,
          "message":
              _extractErrorMessage(jsonResponse) ?? "Failed to verify OTP",
          "data": null,
          "details": _extractErrorDetails(jsonResponse),
          "statusCode": response.statusCode,
        };
      }
    } catch (e) {
      debugPrint('VERIFY OTP error: $e');
      return {"success": false, "message": e.toString(), "data": null};
    }
  }

  /// Step 3: Change password with reset token
  Future<Map<String, dynamic>> changePasswordWithToken(
    String resetToken,
    String newPassword,
  ) async {
    try {
      final response = await authHttpClient.post(
        Uri.parse('${ApiUrl.baseUrl}/auth/reset/change-password'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $resetToken",
        },
        body: jsonEncode({"newPassword": newPassword}),
      );

      debugPrint('CHANGE PASSWORD status=${response.statusCode}');
      debugPrint('CHANGE PASSWORD body=${response.body}');

      final jsonResponse = _safeDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          "success": true,
          "message": (jsonResponse is Map && jsonResponse["message"] is String)
              ? jsonResponse["message"]
              : "Password reset successfully",
          "data": null,
          "statusCode": response.statusCode,
        };
      } else {
        return {
          "success": false,
          "message":
              _extractErrorMessage(jsonResponse) ?? "Failed to reset password",
          "data": null,
          "details": _extractErrorDetails(jsonResponse),
          "statusCode": response.statusCode,
        };
      }
    } catch (e) {
      debugPrint('CHANGE PASSWORD error: $e');
      return {"success": false, "message": e.toString(), "data": null};
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
        return item.toString();
      }).toList();
    }
    return const <String>[];
  }
}
