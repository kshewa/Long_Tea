import 'package:hive/hive.dart';

class SessionManager {
  static const String _boxName = 'sessionBox';
  static const String _keyAccessToken = 'accessToken';
  static const String _keyRefreshToken = 'refreshToken';
  static const String _keyUserJson = 'userJson';

  static Future<void> saveAuthSession({
    required String accessToken,
    String? refreshToken,
    String? userJson,
  }) async {
    final box = await _openBox();
    await box.put(_keyAccessToken, accessToken);
    if (refreshToken != null) {
      await box.put(_keyRefreshToken, refreshToken);
    }
    if (userJson != null) {
      await box.put(_keyUserJson, userJson);
    }
  }

  static Future<String?> getAccessToken() async {
    final box = await _openBox();
    return box.get(_keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    final box = await _openBox();
    return box.get(_keyRefreshToken);
  }

  static Future<Map<String, String>> authHeaders({Map<String, String>? base}) async {
    final token = await getAccessToken();
    final headers = <String, String>{};
    if (base != null) headers.addAll(base);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<void> clear() async {
    final box = await _openBox();
    await box.delete(_keyAccessToken);
    await box.delete(_keyRefreshToken);
    await box.delete(_keyUserJson);
  }

  static Future<Box> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return Hive.openBox(_boxName);
  }
}