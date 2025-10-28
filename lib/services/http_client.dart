import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:longtea_mobile/services/session_manager.dart';
import 'package:longtea_mobile/constants/api_url.dart';

class AuthHttpClient extends http.BaseClient {
  final http.Client _inner;
  bool _isRefreshing = false;
  List<Function> _refreshQueue = [];

  AuthHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Check if this is an auth endpoint (don't add auth header)
    final urlStr = request.url.toString();
    final isAuthEndpoint =
        urlStr.contains('/auth/login') ||
        urlStr.contains('/auth/register') ||
        urlStr.contains('/auth/refresh');

    debugPrint('=== HTTP CLIENT REQUEST ===');
    debugPrint('Method: ${request.method}');
    debugPrint('URL: $urlStr');
    debugPrint('Is Auth Endpoint: $isAuthEndpoint');

    // For non-auth endpoints, check token expiry proactively
    if (!isAuthEndpoint) {
      final shouldRefresh = await _shouldRefreshToken();
      if (shouldRefresh) {
        debugPrint('⏰ Token expiring soon, refreshing proactively...');
        await _refreshTokenWithQueue();
      }
    }

    // Add authorization header for non-auth endpoints
    if (!isAuthEndpoint && !request.headers.containsKey('Authorization')) {
      final token = await SessionManager.getAccessToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
        debugPrint('✅ Added Authorization header');
      }
    }

    // Clone request for potential retry
    final originalRequest = _cloneRequest(request);

    http.StreamedResponse response;

    try {
      response = await _inner.send(request);

      debugPrint('=== HTTP CLIENT RESPONSE ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('============================');
    } catch (e) {
      debugPrint('=== HTTP CLIENT ERROR ===');
      debugPrint('Error: $e');
      debugPrint('========================');
      rethrow;
    }

    // Handle 401 Unauthorized - token expired
    if (response.statusCode == 401 && !isAuthEndpoint) {
      debugPrint('=== 401 UNAUTHORIZED - TOKEN EXPIRED ===');
      debugPrint('Request URL: $urlStr');

      // Try to refresh token
      final refreshed = await _refreshTokenWithQueue();

      if (refreshed && originalRequest != null) {
        debugPrint('✅ Token refreshed, retrying request...');

        // Add new token to retry request
        final newToken = await SessionManager.getAccessToken();
        if (newToken != null && newToken.isNotEmpty) {
          originalRequest.headers['Authorization'] = 'Bearer $newToken';
        }

        // Retry the original request
        response = await _inner.send(originalRequest);
        debugPrint('✅ Retry complete. Status: ${response.statusCode}');
      } else {
        debugPrint('❌ Token refresh failed - clearing session');
        await SessionManager.clear();
      }
    }

    return response;
  }

  /// Check if token should be refreshed proactively (before expiry)
  Future<bool> _shouldRefreshToken() async {
    try {
      // Check if access token is expired or will expire soon (2 min buffer)
      final isExpired = await SessionManager.isAccessTokenExpired(
        bufferSeconds: 120,
      );

      if (isExpired) {
        // Check if refresh token is still valid
        final isRefreshExpired = await SessionManager.isRefreshTokenExpired();
        return !isRefreshExpired;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking token expiry: $e');
      return false;
    }
  }

  /// Refresh token with queue to prevent multiple simultaneous refresh calls
  Future<bool> _refreshTokenWithQueue() async {
    // If already refreshing, queue this request
    if (_isRefreshing) {
      debugPrint('⏳ Token refresh in progress, queuing request...');
      final completer = Completer<bool>();
      _refreshQueue.add(() => completer.complete(true));
      return completer.future;
    }

    _isRefreshing = true;

    try {
      final success = await _tryRefreshToken();

      // Process queued requests
      if (_refreshQueue.isNotEmpty) {
        debugPrint('Processing ${_refreshQueue.length} queued requests...');
        for (final callback in _refreshQueue) {
          callback();
        }
        _refreshQueue.clear();
      }

      return success;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Clone request for retry
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
    } catch (e) {
      debugPrint('Error cloning request: $e');
      return null;
    }
  }

  /// Try to refresh the access token using refresh token
  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await SessionManager.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('❌ No refresh token available');
        return false;
      }

      debugPrint('🔄 Attempting token refresh...');

      final resp = await _inner.post(
        Uri.parse(ApiUrl.refreshUrl),
        headers: {
          "Content-Type": "application/json",
          "x-refresh-token": refreshToken,
          "x-client": "mobile-app",
        },
        body: jsonEncode({
          "clientMode": "mobile-app",
          "refreshToken": refreshToken,
        }),
      );

      debugPrint('Token refresh response: ${resp.statusCode}');

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body);

        if (decoded is! Map || decoded['success'] != true) {
          debugPrint('❌ Invalid refresh response format');
          return false;
        }

        final data = decoded['data'];
        if (data is! Map) {
          debugPrint('❌ No data in refresh response');
          return false;
        }

        // Extract tokens from response
        final newAccessToken = data['accessToken'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;

        if (newAccessToken == null || newAccessToken.isEmpty) {
          debugPrint('❌ No access token in refresh response');
          return false;
        }

        // Parse expiry times from backend
        DateTime? accessTokenExpiresAt;
        DateTime? refreshTokenExpiresAt;

        try {
          if (data['accessTokenExpiresAt'] is String) {
            accessTokenExpiresAt = DateTime.parse(
              data['accessTokenExpiresAt'] as String,
            );
          }
          if (data['refreshTokenExpiresAt'] is String) {
            refreshTokenExpiresAt = DateTime.parse(
              data['refreshTokenExpiresAt'] as String,
            );
          }
        } catch (e) {
          debugPrint('⚠️ Could not parse expiry times: $e');
        }

        // Get existing user data to preserve it
        final userJson = await SessionManager.getUserJson();

        // Save new tokens with expiry times
        await SessionManager.saveAuthSession(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken ?? refreshToken,
          userJson: userJson,
          accessTokenExpiresAt: accessTokenExpiresAt,
          refreshTokenExpiresAt: refreshTokenExpiresAt,
        );

        debugPrint('✅ Token refreshed successfully');
        debugPrint('   New access token expires at: $accessTokenExpiresAt');
        debugPrint('   New refresh token expires at: $refreshTokenExpiresAt');

        return true;
      } else {
        debugPrint('❌ Token refresh failed with status: ${resp.statusCode}');
        debugPrint('   Response: ${resp.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Token refresh error: $e');
      return false;
    }
  }
}

final http.Client authHttpClient = AuthHttpClient();
