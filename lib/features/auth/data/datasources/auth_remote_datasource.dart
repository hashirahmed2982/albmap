import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
  });
  Future<void> forgotPassword({required String email});
  Future<UserModel> loginWithGoogle();
  Future<UserModel> loginWithFacebook();
  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dio, this._secureStorage);

  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  Future<void> _persistTokens(Map<String, dynamic> data) async {
    await _secureStorage.write(
      key: AppConstants.accessTokenKey,
      value: data['accessToken'] as String,
    );
    await _secureStorage.write(
      key: AppConstants.refreshTokenKey,
      value: data['refreshToken'] as String,
    );
  }

  @override
  Future<UserModel> login({required String email, required String password}) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/auth/login',
        data: <String, String>{'email': email, 'password': password},
      );
      await _persistTokens(response.data as Map<String, dynamic>);
      return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] as String? ?? 'Login failed',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/auth/signup',
        data: <String, String>{'email': email, 'password': password, 'name': name},
      );
      await _persistTokens(response.data as Map<String, dynamic>);
      return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] as String? ?? 'Sign up failed',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    try {
      await _dio.post<dynamic>('/auth/forgot-password', data: <String, String>{'email': email});
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] as String? ?? 'Request failed',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<UserModel> loginWithGoogle() async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>('/auth/google');
      await _persistTokens(response.data as Map<String, dynamic>);
      return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] as String? ?? 'Google login failed');
    }
  }

  @override
  Future<UserModel> loginWithFacebook() async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>('/auth/facebook');
      await _persistTokens(response.data as Map<String, dynamic>);
      return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] as String? ?? 'Facebook login failed');
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>('/auth/me');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] as String? ?? 'Failed to fetch user',
        e.response?.statusCode,
      );
    }
  }
}
