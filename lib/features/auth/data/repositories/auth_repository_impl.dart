import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  })  : _remote = remoteDataSource,
        _local = localDataSource,
        _networkInfo = networkInfo;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final NetworkInfo _networkInfo;

  Future<Either<Failure, UserEntity>> _guardedCall(
      Future<UserModel> Function() action,
      ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final UserModel user = await action();
      await _local.cacheUser(user);
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      // Surface the real exception message (e.g. a raw PlatformException
      // from the native Facebook/Google SDK) instead of a generic
      // "Unknown failure" that hides what actually went wrong — this is
      // exactly the situation that made "unexpected error occurred"
      // undiagnosable from the UI alone.
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) {
    return _guardedCall(() => _remote.login(email: email, password: password));
  }

  @override
  Future<Either<Failure, UserEntity>> signUpBusinessUser({
    required String email,
    required String password,
    required String name,
  }) {
    return _guardedCall(
      () => _remote.signUp(email: email, password: password, name: name),
    );
  }

  @override
  Future<Either<Failure, UserEntity>> continueAsGuest() async {
    final UserModel guest = UserModel(
      id: 'guest-${const Uuid().v4()}',
      email: '',
      role: UserRole.guest,
      name: 'Guest',
    );
    await _local.cacheUser(guest);
    return Right(guest);
  }

  @override
  Future<Either<Failure, void>> forgotPassword({required String email}) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await _remote.forgotPassword(email: email);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> loginWithGoogle() {
    return _guardedCall(_remote.loginWithGoogle);
  }

  @override
  Future<Either<Failure, UserEntity>> loginWithFacebook() {
    return _guardedCall(_remote.loginWithFacebook);
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final UserModel? cached = await _local.getCachedUser();
      if (cached != null && cached.role == UserRole.guest) {
        return Right(cached);
      }
      if (await _networkInfo.isConnected) {
        try {
          final UserModel fresh = await _remote.getCurrentUser();
          await _local.cacheUser(fresh);
          return Right(fresh);
        } on ServerException {
          // fall back to cache below
        }
      }
      return Right(cached);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _local.clearUser();
      return const Right(null);
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await _remote.changePassword(currentPassword: currentPassword, newPassword: newPassword);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount({String? password}) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await _remote.deleteAccount(password: password);
      // Mirrors logout(): clear the cached user + secure-storage tokens
      // so the app doesn't keep sending requests as an account that no
      // longer exists server-side.
      await _local.clearUser();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    String? name,
    String? phone,
    String? profileImageUrl,
  }) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final UserModel updated = await _remote.updateProfile(
        name: name,
        phone: phone,
        profileImageUrl: profileImageUrl,
      );
      await _local.cacheUser(updated);
      return Right(updated);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> uploadAvatar(String filePath) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final UserModel updated = await _remote.uploadAvatar(filePath);
      await _local.cacheUser(updated);
      return Right(updated);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
