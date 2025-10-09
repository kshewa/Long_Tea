import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyAccessToken = 'accessToken';
  static const String _keyRefreshToken = 'refreshToken';
  static const String _keyUserJson = 'userJson';
  static const String _keyAccessTokenExpiresAt = 'accessTokenExpiresAt';
  static const String _keyRefreshTokenExpiresAt = 'refreshTokenExpiresAt';

  /// Save authentication session with tokens and expiry times
  static Future<void> saveAuthSession({
    required String accessToken,
    String? refreshToken,
    String? userJson,
    DateTime? accessTokenExpiresAt,
    DateTime? refreshTokenExpiresAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);

    if (refreshToken != null) {
      await prefs.setString(_keyRefreshToken, refreshToken);
    }

    if (userJson != null) {
      await prefs.setString(_keyUserJson, userJson);
    }

    if (accessTokenExpiresAt != null) {
      await prefs.setString(
        _keyAccessTokenExpiresAt,
        accessTokenExpiresAt.toIso8601String(),
      );
    }

    if (refreshTokenExpiresAt != null) {
      await prefs.setString(
        _keyRefreshTokenExpiresAt,
        refreshTokenExpiresAt.toIso8601String(),
      );
    }
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  static Future<String?> getUserJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserJson);
  }

  static Future<DateTime?> getAccessTokenExpiresAt() async {
    final prefs = await SharedPreferences.getInstance();
    final expiresAtStr = prefs.getString(_keyAccessTokenExpiresAt);
    if (expiresAtStr != null) {
      try {
        return DateTime.parse(expiresAtStr);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<DateTime?> getRefreshTokenExpiresAt() async {
    final prefs = await SharedPreferences.getInstance();
    final expiresAtStr = prefs.getString(_keyRefreshTokenExpiresAt);
    if (expiresAtStr != null) {
      try {
        return DateTime.parse(expiresAtStr);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Check if access token is expired or will expire soon (within buffer)
  static Future<bool> isAccessTokenExpired({int bufferSeconds = 60}) async {
    final expiresAt = await getAccessTokenExpiresAt();
    if (expiresAt == null) return true;

    final now = DateTime.now();
    final bufferTime = now.add(Duration(seconds: bufferSeconds));
    return bufferTime.isAfter(expiresAt);
  }

  /// Check if refresh token is expired
  static Future<bool> isRefreshTokenExpired() async {
    final expiresAt = await getRefreshTokenExpiresAt();
    if (expiresAt == null) return true;

    final now = DateTime.now();
    return now.isAfter(expiresAt);
  }

  static Future<Map<String, String>> authHeaders({
    Map<String, String>? base,
  }) async {
    final token = await getAccessToken();
    final headers = <String, String>{};
    if (base != null) headers.addAll(base);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUserJson);
    await prefs.remove(_keyAccessTokenExpiresAt);
    await prefs.remove(_keyRefreshTokenExpiresAt);
  }
}
