import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_pro9/services/session_manager.dart';
import 'package:my_pro9/constants/api_url.dart';

class AuthHttpClient extends http.BaseClient {
  final http.Client _inner;

  AuthHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await SessionManager.getAccessToken();
    final urlStr = request.url.toString();
    final isAuthEndpoint = urlStr.contains('/auth/');
    if (!isAuthEndpoint && token != null && token.isNotEmpty && !request.headers.containsKey('Authorization')) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    final originalRequest = _cloneRequest(request);
    http.StreamedResponse response = await _inner.send(request);

    if (response.statusCode == 401 && !isAuthEndpoint) {
      final refreshed = await _tryRefreshToken();
      if (refreshed && originalRequest != null) {
        final newToken = await SessionManager.getAccessToken();
        if (newToken != null && newToken.isNotEmpty) {
          originalRequest.headers['Authorization'] = 'Bearer $newToken';
        }
        response = await _inner.send(originalRequest);
      } else {
        // Clear invalid tokens so app can handle re-auth gracefully
        await SessionManager.clear();
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
          if (newAccess != null && newAccess.isNotEmpty) {
            await SessionManager.saveAuthSession(
              accessToken: newAccess,
              refreshToken: newRefresh ?? refreshToken,
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