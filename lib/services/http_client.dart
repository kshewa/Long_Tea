import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:longtea_mobile/services/session_manager.dart';
import 'package:longtea_mobile/constants/api_url.dart';

class AuthHttpClient extends http.BaseClient {
  final http.Client _inner;

  AuthHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await SessionManager.getAccessToken();
    final urlStr = request.url.toString();
    final isAuthEndpoint = urlStr.contains('/auth/');

    // Debug print HTTP client request details
    debugPrint('=== HTTP CLIENT REQUEST ===');
    debugPrint('Method: ${request.method}');
    debugPrint('URL: $urlStr');
    debugPrint('Headers: ${request.headers}');
    debugPrint('Is Auth Endpoint: $isAuthEndpoint');
    debugPrint('Has Token: ${token != null && token.isNotEmpty}');

    if (!isAuthEndpoint &&
        token != null &&
        token.isNotEmpty &&
        !request.headers.containsKey('Authorization')) {
      request.headers['Authorization'] = 'Bearer $token';
      debugPrint('Added Authorization header');
    }

    final originalRequest = _cloneRequest(request);

    http.StreamedResponse response;

    try {
      response = await _inner.send(request);

      // Debug print response details
      debugPrint('=== HTTP CLIENT RESPONSE ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Status Reason: ${response.reasonPhrase}');
      debugPrint('Response Headers: ${response.headers}');
      debugPrint('============================');
    } catch (e) {
      debugPrint('=== HTTP CLIENT ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Error Type: ${e.runtimeType}');
      debugPrint('========================');
      rethrow;
    }

    if (response.statusCode == 401 && !isAuthEndpoint) {
      debugPrint('=== TOKEN REFRESH ATTEMPT ===');
      final refreshed = await _tryRefreshToken();
      if (refreshed && originalRequest != null) {
        final newToken = await SessionManager.getAccessToken();
        if (newToken != null && newToken.isNotEmpty) {
          originalRequest.headers['Authorization'] = 'Bearer $newToken';
        }
        response = await _inner.send(originalRequest);
        debugPrint('Token refreshed and request retried');
      } else {
        // Clear invalid tokens so app can handle re-auth gracefully
        await SessionManager.clear();
        debugPrint('Token refresh failed, cleared session');
      }
    }

    return response;
  }

  http.BaseRequest? _cloneRequest(http.BaseRequest request) {
    try {
      if (request is http.Request) {
        final cloned = http.Request(request.method, request.url);
        cloned.headers.addAll(request.headers);
        cloned.bodyBytes = request.bodyBytes;
        cloned.followRedirects = request.followRedirects;
        cloned.maxRedirects = request.maxRedirects;
        cloned.persistentConnection = request.persistentConnection;
        return cloned;
      }
      // Fallback for other BaseRequest types
      final cloned = http.Request(request.method, request.url);
      cloned.headers.addAll(request.headers);
      cloned.followRedirects = request.followRedirects;
      cloned.maxRedirects = request.maxRedirects;
      cloned.persistentConnection = request.persistentConnection;
      return cloned;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await SessionManager.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final resp = await _inner.post(
        Uri.parse(ApiUrl.refreshUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "clientMode": "mobile-app",
          "refreshToken": refreshToken,
        }),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body);
        if (decoded is Map && decoded['data'] is Map) {
          final data = decoded['data'] as Map;
          final newAccess = data['accessToken'] as String?;
          final newRefresh = data['refreshToken'] as String?;

          // Parse token expiry times
          DateTime? accessTokenExpiresAt;
          DateTime? refreshTokenExpiresAt;

          if (data['accessTokenExpiresAt'] is String) {
            try {
              accessTokenExpiresAt = DateTime.parse(
                data['accessTokenExpiresAt'] as String,
              );
            } catch (_) {}
          }

          if (data['refreshTokenExpiresAt'] is String) {
            try {
              refreshTokenExpiresAt = DateTime.parse(
                data['refreshTokenExpiresAt'] as String,
              );
            } catch (_) {}
          }

          if (newAccess != null && newAccess.isNotEmpty) {
            // Get existing user data to preserve it
            final userJson = await SessionManager.getUserJson();

            await SessionManager.saveAuthSession(
              accessToken: newAccess,
              refreshToken: newRefresh ?? refreshToken,
              userJson: userJson,
              accessTokenExpiresAt: accessTokenExpiresAt,
              refreshTokenExpiresAt: refreshTokenExpiresAt,
            );
            return true;
          }
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

final http.Client authHttpClient = AuthHttpClient();
