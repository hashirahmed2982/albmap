import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  /// Step 1 of signup — emails a 6-digit code and does NOT create an
  /// account or session. The email has to be proven real (by entering
  /// that code — see [verifySignupOtp]) before it ever occupies an
  /// account slot, so a mistyped/fake address can't block the real
  /// owner from signing up later.
  Future<Either<Failure, void>> requestSignupOtp({
    required String email,
    required String password,
    required String name,
  });

  /// Step 2 — the code from that email. This is what actually creates
  /// the account and returns a session.
  Future<Either<Failure, UserEntity>> verifySignupOtp({
    required String email,
    required String otp,
  });

  Future<Either<Failure, UserEntity>> continueAsGuest();

  Future<Either<Failure, void>> forgotPassword({required String email});

  Future<Either<Failure, UserEntity>> loginWithGoogle();

  Future<Either<Failure, UserEntity>> loginWithFacebook();

  Future<Either<Failure, UserEntity?>> getCurrentUser();

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Permanent — deletes the account server-side (and, for a business
  /// owner, every business/event/review that references it) and clears
  /// all local session state on success. [password] is required for a
  /// password-auth account, ignored (may be null) for a social-login-only
  /// account with nothing to confirm.
  Future<Either<Failure, void>> deleteAccount({String? password});

  Future<Either<Failure, UserEntity>> updateProfile({
    String? name,
    String? phone,
    String? profileImageUrl,
  });

  Future<Either<Failure, UserEntity>> uploadAvatar(String filePath);
}
