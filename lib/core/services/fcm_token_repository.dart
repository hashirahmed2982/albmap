import 'package:dio/dio.dart';

/// Registers the current device's FCM token with the backend — matches
/// POST /users/me/fcm-token exactly (see
/// albmap-backend/src/modules/users/user.routes.js). Kept as a plain,
/// single-method class rather than the full clean-architecture datasource/
/// repository/use-case chain used elsewhere, since there's genuinely only
/// one operation here and no domain logic to separate out.
abstract class FcmTokenRepository {
  Future<void> registerToken(String token);
}

class FcmTokenRepositoryImpl implements FcmTokenRepository {
  FcmTokenRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<void> registerToken(String token) async {
    try {
      await _dio.post<dynamic>('/users/me/fcm-token', data: <String, String>{'fcmToken': token});
    } on DioException {
      // Best-effort — a failed token registration means push delivery
      // won't reach this device, not something that should interrupt
      // whatever the user was doing when this ran (app startup, login).
    }
  }
}

/// Mock mode has no backend to register a token with — succeeds
/// unconditionally so FcmService's initialization flow doesn't need a
/// separate code path for mock vs real.
class FcmTokenRepositoryMock implements FcmTokenRepository {
  @override
  Future<void> registerToken(String token) async {}
}
