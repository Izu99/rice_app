// Token storage using SharedPreferences (no local DB)
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import '../../domain/entities/user_entity.dart';
import '../../data/models/user_model.dart';
import '../../data/models/company_model.dart';

class TokenStorage {
  final SharedPreferences _prefs;
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'cached_user';
  static const String _companyKey = 'cached_company';

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

  Future<void> saveUser(UserEntity user) async {
    final model = UserModel.fromEntity(user);
    await _prefs.setString(_userKey, jsonEncode(model.toJson()));
  }

  Future<UserEntity?> getUser() async {
    final jsonStr = _prefs.getString(_userKey);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr);
      return UserModel.fromJson(map).toEntity();
    } catch (e) {
      return null;
    }
  }

  Future<void> clearUser() async {
    await _prefs.remove(_userKey);
  }

  Future<void> saveCompany(CompanyModel company) async {
    await _prefs.setString(_companyKey, jsonEncode(company.toJson()));
  }

  Future<CompanyModel?> getCompany() async {
    final jsonStr = _prefs.getString(_companyKey);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr);
      return CompanyModel.fromJson(map);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearCompany() async {
    await _prefs.remove(_companyKey);
  }

  Future<void> clearAll() async {
    await clearToken();
    await clearRefreshToken();
    await clearUser();
    await clearCompany();
  }
}
