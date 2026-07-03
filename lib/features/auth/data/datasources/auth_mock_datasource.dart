import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';
import 'auth_remote_datasource.dart';

/// In-memory fake standing in for the real API. Accepts ANY email/password
/// combination for login (simulates an existing account) and always
/// succeeds for sign-up. Swap out via [AppConstants.useMockData] in
/// service_locator.dart — no other code needs to change.
class AuthMockDataSource implements AuthRemoteDataSource {
  AuthMockDataSource(this._secureStorage);

  final FlutterSecureStorage _secureStorage;

  static final UserModel _fakeUser = const UserModel(
    id: 'business-user-001',
    email: 'demo@albmap.com',
    role: UserRole.business,
    name: 'Demo Business',
    phone: '+355 69 123 4567',
  );

  Future<void> _fakeDelay() => Future<void>.delayed(const Duration(milliseconds: 500));

  Future<void> _persistFakeTokens() async {
    await _secureStorage.write(key: AppConstants.accessTokenKey, value: 'mock-access-token');
    await _secureStorage.write(key: AppConstants.refreshTokenKey, value: 'mock-refresh-token');
  }

  @override
  Future<UserModel> login({required String email, required String password}) async {
    await _fakeDelay();
    if (email.trim().isEmpty || password.isEmpty) {
      throw AuthException('Email and password are required');
    }
    await _persistFakeTokens();
    return UserModel(
      id: _fakeUser.id,
      email: email,
      role: UserRole.business,
      name: _fakeUser.name,
      phone: _fakeUser.phone,
    );
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    await _fakeDelay();
    await _persistFakeTokens();
    return UserModel(id: 'business-user-${DateTime.now().millisecondsSinceEpoch}', email: email, role: UserRole.business, name: name);
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await _fakeDelay();
  }

  @override
  Future<UserModel> loginWithGoogle() async {
    await _fakeDelay();
    await _persistFakeTokens();
    return _fakeUser;
  }

  @override
  Future<UserModel> loginWithFacebook() async {
    await _fakeDelay();
    await _persistFakeTokens();
    return _fakeUser;
  }

  @override
  Future<UserModel> getCurrentUser() async {
    await _fakeDelay();
    return _fakeUser;
  }
}
