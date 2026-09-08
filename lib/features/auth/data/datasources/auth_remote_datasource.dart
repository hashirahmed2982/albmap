import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});

  /// Step 1 of signup — emails a code, doesn't create an account. See
  /// [verifySignupOtp].
  Future<void> requestSignupOtp({
    required String email,
    required String password,
    required String name,
  });

  /// Step 2 — the code from that email. This is what actually creates
  /// the account and returns a session.
  Future<UserModel> verifySignupOtp({required String email, required String otp});
  Future<void> forgotPassword({required String email});
  Future<UserModel> loginWithGoogle();
  Future<UserModel> loginWithFacebook();
  Future<UserModel> loginWithApple();
  Future<UserModel> getCurrentUser();
  Future<void> changePassword({required String currentPassword, required String newPassword});
  Future<void> deleteAccount({String? password});
  Future<UserModel> updateProfile({String? name, String? phone, String? profileImageUrl});
  Future<UserModel> uploadAvatar(String filePath);
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
  Future<void> requestSignupOtp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/auth/signup',
        data: <String, String>{'email': email, 'password': password, 'name': name},
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] as String? ?? 'Sign up failed',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<UserModel> verifySignupOtp({required String email, required String otp}) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/auth/signup/verify',
        data: <String, String>{'email': email, 'otp': otp},
      );
      await _persistTokens(response.data as Map<String, dynamic>);
      return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] as String? ?? 'Verification failed',
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
    // Triggers the native Google account picker — this is what was
    // actually missing before: the backend call existed, but nothing
    // ever obtained a real ID token to send it, so it always failed
    // validation with an empty body.
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      // Without this, Android's native Google Sign-In can complete the
      // account picker successfully but return a null idToken — the SDK
      // needs to be told which OAuth client (audience) to mint the ID
      // token FOR. This must be the Web application client ID (the same
      // value as the backend's GOOGLE_CLIENT_ID), not the Android client ID
      // — the Android client ID is used implicitly via the package
      // name+SHA-1 already registered in google-services.json.
      //
      // If this ever needs changing again: the source of truth is
      // Firebase Console's Authentication > Sign-in method > Google >
      // Web SDK configuration for whichever Firebase project
      // android/app/google-services.json and ios/Runner/GoogleService-
      // Info.plist actually belong to — cross-check against those files'
      // own project number (google-services.json's project_number, or
      // GoogleService-Info.plist's GCM_SENDER_ID) before trusting a
      // value pasted from memory, since a mismatched Google account/
      // project has silently broken this more than once.
      serverClientId: '1011810478555-sgv43v7tqvmq5ifctljmev2flgp51cbq.apps.googleusercontent.com',
    );
    final GoogleSignInAccount? account = await googleSignIn.signIn();
    if (account == null) {
      // User cancelled the picker — not an error, just no result.
      throw ServerException('Sign-in cancelled');
    }

    final GoogleSignInAuthentication auth = await account.authentication;
    final String? idToken = auth.idToken;
    if (idToken == null) {
      throw ServerException('Google did not return an ID token');
    }

    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/auth/google',
        data: <String, String>{'idToken': idToken},
      );
      await _persistTokens(response.data as Map<String, dynamic>);
      return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] as String? ?? 'Google login failed');
    }
  }

  @override
  Future<UserModel> loginWithFacebook() async {
    final LoginResult result = await FacebookAuth.instance.login(permissions: const ['email', 'public_profile']);
    if (result.status == LoginStatus.cancelled) {
      throw ServerException('Sign-in cancelled');
    }
    if (result.status != LoginStatus.success || result.accessToken == null) {
      throw ServerException(result.message ?? 'Facebook login failed');
    }

    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/auth/facebook',
        data: <String, String>{'accessToken': result.accessToken!.tokenString},
      );
      await _persistTokens(response.data as Map<String, dynamic>);
      return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] as String? ?? 'Facebook login failed');
    }
  }

  @override
  Future<UserModel> loginWithApple() async {
    try {
      final AuthorizationCredentialAppleID credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        // Only used on Android — iOS/macOS sign in through the native
        // AuthenticationServices SDK directly and never touch this. This
        // must be the Services ID (NOT the app's bundle ID — that's only
        // for the native iOS flow), configured in the Apple Developer
        // portal with `redirectUri` below registered as one of its
        // Return URLs. See docs/APPLE_SIGN_IN_SETUP.md in albmap-backend.
        webAuthenticationOptions: Platform.isAndroid
            ? WebAuthenticationOptions(
                clientId: 'com.albmap.app.web',
                redirectUri: Uri.parse('${AppConstants.baseUrl}/auth/apple/callback'),
              )
            : null,
      );

      final String? identityToken = credential.identityToken;
      if (identityToken == null) {
        throw ServerException('Apple did not return an identity token');
      }

      final Response<dynamic> response = await _dio.post<dynamic>(
        '/auth/apple',
        data: <String, String>{
          'identityToken': identityToken,
          // Only ever non-null on the very first authorization — Apple
          // never sends the name again after that (see the backend's
          // loginWithApple comment), so this is a no-op on every later
          // sign-in for the same account.
          if (credential.givenName != null) 'firstName': credential.givenName!,
          if (credential.familyName != null) 'lastName': credential.familyName!,
        },
      );
      await _persistTokens(response.data as Map<String, dynamic>);
      return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw ServerException('Sign-in cancelled');
      }
      throw ServerException(e.message);
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] as String? ?? 'Apple login failed');
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

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/auth/change-password',
        data: <String, String>{'currentPassword': currentPassword, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] as String? ?? 'Failed to change password',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> deleteAccount({String? password}) async {
    try {
      await _dio.delete<dynamic>(
        '/auth/me',
        data: <String, String>{if (password != null) 'password': password},
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] as String? ?? 'Failed to delete account',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<UserModel> updateProfile({String? name, String? phone, String? profileImageUrl}) async {
    try {
      final Response<dynamic> response = await _dio.patch<dynamic>(
        '/auth/me',
        data: <String, dynamic>{
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        },
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] as String? ?? 'Failed to update profile',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<UserModel> uploadAvatar(String filePath) async {
    try {
      final formData = FormData.fromMap(<String, dynamic>{
        'avatar': await MultipartFile.fromFile(filePath),
      });
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/users/me/avatar',
        data: formData,
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] as String? ?? 'Failed to upload avatar',
        e.response?.statusCode,
      );
    }
  }
}