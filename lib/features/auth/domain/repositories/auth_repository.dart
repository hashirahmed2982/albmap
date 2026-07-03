import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> signUpBusinessUser({
    required String email,
    required String password,
    required String name,
  });

  Future<Either<Failure, UserEntity>> continueAsGuest();

  Future<Either<Failure, void>> forgotPassword({required String email});

  Future<Either<Failure, UserEntity>> loginWithGoogle();

  Future<Either<Failure, UserEntity>> loginWithFacebook();

  Future<Either<Failure, UserEntity?>> getCurrentUser();

  Future<Either<Failure, void>> logout();
}
