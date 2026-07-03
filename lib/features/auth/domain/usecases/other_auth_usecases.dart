import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class ContinueAsGuestUseCase implements UseCase<UserEntity, NoParams> {
  ContinueAsGuestUseCase(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) {
    return _repository.continueAsGuest();
  }
}

class GetCurrentUserUseCase implements UseCase<UserEntity?, NoParams> {
  GetCurrentUserUseCase(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity?>> call(NoParams params) {
    return _repository.getCurrentUser();
  }
}

class LogoutUseCase implements UseCase<void, NoParams> {
  LogoutUseCase(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return _repository.logout();
  }
}
