import 'package:hive_flutter/hive_flutter.dart';

class SessionManager {
  static const String _boxName = 'authBox';
  static const String _keyAccessToken = 'accessToken';
  static const String _keyRefreshToken = 'refreshToken';
  static const String _keyUserJson = 'userJson';
  static const String _keyAccessTokenExpiresAt = 'accessTokenExpiresAt';
  static const String _keyRefreshTokenExpiresAt = 'refreshTokenExpiresAt';

  /// Get or open the Hive box
  static Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  /// Save authentication session with tokens and expiry times
  static Future<void> saveAuthSession({
    required String accessToken,
    String? refreshToken,
    String? userJson,
    DateTime? accessTokenExpiresAt,
    DateTime? refreshTokenExpiresAt,
  }) async {
    final box = await _getBox();
    await box.put(_keyAccessToken, accessToken);

    if (refreshToken != null) {
      await box.put(_keyRefreshToken, refreshToken);
    }

    if (userJson != null) {
      await box.put(_keyUserJson, userJson);
    }

    if (accessTokenExpiresAt != null) {
      await box.put(
        _keyAccessTokenExpiresAt,
        accessTokenExpiresAt.toIso8601String(),
      );
    }

    if (refreshTokenExpiresAt != null) {
      await box.put(
        _keyRefreshTokenExpiresAt,
        refreshTokenExpiresAt.toIso8601String(),
      );
    }
  }

  static Future<String?> getAccessToken() async {
    final box = await _getBox();
    return box.get(_keyAccessToken) as String?;
  }

  static Future<String?> getRefreshToken() async {
    final box = await _getBox();
    return box.get(_keyRefreshToken) as String?;
  }

  static Future<String?> getUserJson() async {
    final box = await _getBox();
    return box.get(_keyUserJson) as String?;
  }

  static Future<DateTime?> getAccessTokenExpiresAt() async {
    final box = await _getBox();
    final expiresAtStr = box.get(_keyAccessTokenExpiresAt) as String?;
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
    final box = await _getBox();
    final expiresAtStr = box.get(_keyRefreshTokenExpiresAt) as String?;
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
    final box = await _getBox();
    await box.delete(_keyAccessToken);
    await box.delete(_keyRefreshToken);
    await box.delete(_keyUserJson);
    await box.delete(_keyAccessTokenExpiresAt);
    await box.delete(_keyRefreshTokenExpiresAt);
  }
}
