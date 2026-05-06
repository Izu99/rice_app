import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user_entity.dart';
import '../../data/models/user_model.dart';
import '../../data/models/company_model.dart';

class TokenStorage {
  final FlutterSecureStorage _secure;
  final SharedPreferences _prefs;

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'cached_user';
  static const String _companyKey = 'cached_company';

  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  TokenStorage(this._prefs)
      : _secure = const FlutterSecureStorage(
          aOptions: _androidOptions,
        );

  Future<void> saveToken(String token) =>
      _secure.write(key: _tokenKey, value: token);

  Future<String?> getToken() => _secure.read(key: _tokenKey);

  Future<void> clearToken() => _secure.delete(key: _tokenKey);

  Future<void> saveRefreshToken(String refreshToken) =>
      _secure.write(key: _refreshTokenKey, value: refreshToken);

  Future<String?> getRefreshToken() => _secure.read(key: _refreshTokenKey);

  Future<void> clearRefreshToken() => _secure.delete(key: _refreshTokenKey);

  Future<void> saveUser(UserEntity user) async {
    final model = UserModel.fromEntity(user);
    await _prefs.setString(_userKey, jsonEncode(model.toJson()));
  }

  Future<UserEntity?> getUser() async {
    final jsonStr = _prefs.getString(_userKey);
    if (jsonStr == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(jsonStr)).toEntity();
    } catch (_) {
      return null;
    }
  }

  Future<void> clearUser() => _prefs.remove(_userKey);

  Future<void> saveCompany(CompanyModel company) async {
    await _prefs.setString(_companyKey, jsonEncode(company.toJson()));
  }

  Future<CompanyModel?> getCompany() async {
    final jsonStr = _prefs.getString(_companyKey);
    if (jsonStr == null) return null;
    try {
      return CompanyModel.fromJson(jsonDecode(jsonStr));
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCompany() => _prefs.remove(_companyKey);

  Future<void> clearAll() async {
    await Future.wait([
      clearToken(),
      clearRefreshToken(),
      clearUser(),
      clearCompany(),
    ]);
  }
}
