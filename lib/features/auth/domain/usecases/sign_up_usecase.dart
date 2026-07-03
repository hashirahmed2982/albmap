import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase implements UseCase<UserEntity, SignUpParams> {
  SignUpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(SignUpParams params) {
    return _repository.signUpBusinessUser(
      email: params.email,
      password: params.password,
      name: params.name,
    );
  }
}

class SignUpParams extends Equatable {
  const SignUpParams({required this.email, required this.password, required this.name});

  final String email;
  final String password;
  final String name;

  @override
  List<Object?> get props => [email, password, name];
}
