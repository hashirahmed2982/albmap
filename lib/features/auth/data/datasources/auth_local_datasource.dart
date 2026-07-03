import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(this._userBox, this._secureStorage);

  final Box<String> _userBox;
  final FlutterSecureStorage _secureStorage;

  static const String _userKey = 'current_user';

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      await _userBox.put(_userKey, jsonEncode(user.toJson()));
    } catch (_) {
      throw CacheException('Failed to cache user');
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final String? raw = _userBox.get(_userKey);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      throw CacheException('Failed to parse cached user');
    }
  }

  @override
  Future<void> clearUser() async {
    await _userBox.delete(_userKey);
    await _secureStorage.delete(key: AppConstants.accessTokenKey);
    await _secureStorage.delete(key: AppConstants.refreshTokenKey);
  }
}
