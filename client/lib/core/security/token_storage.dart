// Token storage using SharedPreferences (no local DB)
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class TokenStorage {
  final SharedPreferences _prefs;
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  TokenStorage(this._prefs);

  Future<void> saveToken(String token) {
    debugPrint('TokenStorage: Saving token...');
    return _prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final token = _prefs.getString(_tokenKey);
    debugPrint(
        'TokenStorage: Retrieving token: ${token != null && token.isNotEmpty ? 'present' : 'absent'}');
    return token;
  }

  Future<void> clearToken() async {
    debugPrint('TokenStorage: Clearing token...');
    await _prefs.remove(_tokenKey);
  }

  Future<void> saveRefreshToken(String refreshToken) {
    debugPrint('TokenStorage: Saving refresh token...');
    return _prefs.setString(_refreshTokenKey, refreshToken);
  }

  Future<String?> getRefreshToken() async {
    final token = _prefs.getString(_refreshTokenKey);
    debugPrint(
        'TokenStorage: Retrieving refresh token: ${token != null && token.isNotEmpty ? 'present' : 'absent'}');
    return token;
  }

  Future<void> clearRefreshToken() async {
    debugPrint('TokenStorage: Clearing refresh token...');
    await _prefs.remove(_refreshTokenKey);
  }
}

