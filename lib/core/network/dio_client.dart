import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/app_constants.dart';

/// Single Dio instance shared across all data sources.
/// Handles: base config, auth token injection, silent token refresh on 401,
/// and request/response logging (debug only).
class DioClient {
  DioClient(this._secureStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        contentType: 'application/json',
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) async {
          final String? token = await _secureStorage.read(key: AppConstants.accessTokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          if (error.response?.statusCode == 401) {
            final bool refreshed = await _tryRefreshToken();
            if (refreshed) {
              final RequestOptions req = error.requestOptions;
              final String? newToken =
                  await _secureStorage.read(key: AppConstants.accessTokenKey);
              req.headers['Authorization'] = 'Bearer $newToken';
              try {
                final Response<dynamic> response = await _dio.fetch(req);
                return handler.resolve(response);
              } catch (_) {
                // fall through to original error
              }
            }
          }
          handler.next(error);
        },
      ),
    );

    assert(() {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          error: true,
          compact: true,
        ),
      );
      return true;
    }());
  }

  late final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  Dio get dio => _dio;

  Future<bool> _tryRefreshToken() async {
    try {
      final String? refreshToken =
          await _secureStorage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null) return false;

      final Response<dynamic> response = await Dio(
        BaseOptions(baseUrl: AppConstants.baseUrl),
      ).post<dynamic>('/auth/refresh', data: <String, String>{'refreshToken': refreshToken});

      final String newAccessToken = response.data['accessToken'] as String;
      await _secureStorage.write(key: AppConstants.accessTokenKey, value: newAccessToken);
      return true;
    } catch (_) {
      await _secureStorage.delete(key: AppConstants.accessTokenKey);
      await _secureStorage.delete(key: AppConstants.refreshTokenKey);
      return false;
    }
  }
}
