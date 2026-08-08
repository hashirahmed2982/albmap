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

  static const UserModel _fakeUser = UserModel(
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

  // Mock signup mirrors the real two-step OTP flow so the UI can actually
  // be exercised without a backend: requestSignupOtp "sends" a fixed
  // code (there's no real inbox to check in mock mode) and remembers the
  // pending name/email like the real signup_otps row does, and
  // verifySignupOtp only succeeds for that exact code — anything else
  // fails the same way a wrong code would against the real API.
  static const String _mockOtp = '123456';
  String? _pendingSignupEmail;
  String? _pendingSignupName;

  @override
  Future<void> requestSignupOtp({
    required String email,
    required String password,
    required String name,
  }) async {
    await _fakeDelay();
    _pendingSignupEmail = email;
    _pendingSignupName = name;
  }

  @override
  Future<UserModel> verifySignupOtp({required String email, required String otp}) async {
    await _fakeDelay();
    if (otp != _mockOtp || email != _pendingSignupEmail) {
      throw AuthException('Incorrect code.');
    }
    await _persistFakeTokens();
    return UserModel(
      id: 'business-user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      role: UserRole.business,
      name: _pendingSignupName ?? 'Demo Business',
    );
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

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await _fakeDelay();
    if (currentPassword.isEmpty) {
      throw AuthException('Current password is incorrect');
    }
    // Mock mode has nothing real to change — succeeds unconditionally
    // otherwise, matching the mock philosophy elsewhere in this file (any
    // non-empty credential "works").
  }

  @override
  Future<void> deleteAccount({String? password}) async {
    await _fakeDelay();
    if (password != null && password.isEmpty) {
      throw AuthException('Incorrect password');
    }
    // Mock mode has nothing real to delete — succeeds unconditionally
    // otherwise, matching changePassword's mock philosophy above.
  }

  @override
  Future<UserModel> updateProfile({String? name, String? phone, String? profileImageUrl}) async {
    await _fakeDelay();
    return UserModel(
      id: _fakeUser.id,
      email: _fakeUser.email,
      role: _fakeUser.role,
      name: name ?? _fakeUser.name,
      phone: phone ?? _fakeUser.phone,
      profileImageUrl: profileImageUrl ?? _fakeUser.profileImageUrl,
    );
  }

  @override
  Future<UserModel> uploadAvatar(String filePath) async {
    await _fakeDelay();
    // No real server to upload to in mock mode — just pretend it worked and
    // echo back the local file path as if it were a hosted URL, so the UI
    // still shows the picked image immediately.
    return UserModel(
      id: _fakeUser.id,
      email: _fakeUser.email,
      role: _fakeUser.role,
      name: _fakeUser.name,
      phone: _fakeUser.phone,
      profileImageUrl: filePath,
    );
  }
}
