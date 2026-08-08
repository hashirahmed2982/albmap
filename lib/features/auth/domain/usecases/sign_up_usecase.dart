import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Step 1 of signup — see [AuthRepository.requestSignupOtp]. No account
/// exists after this succeeds; the UI's next step is to collect the code
/// and call [VerifySignupOtpUseCase].
class RequestSignupOtpUseCase implements UseCase<void, SignUpParams> {
  RequestSignupOtpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, void>> call(SignUpParams params) {
    return _repository.requestSignupOtp(
      email: params.email,
      password: params.password,
      name: params.name,
    );
  }
}

/// Step 2 — the code from that email. This is what actually creates the
/// account.
class VerifySignupOtpUseCase implements UseCase<UserEntity, VerifySignupOtpParams> {
  VerifySignupOtpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(VerifySignupOtpParams params) {
    return _repository.verifySignupOtp(email: params.email, otp: params.otp);
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

class VerifySignupOtpParams extends Equatable {
  const VerifySignupOtpParams({required this.email, required this.otp});

  final String email;
  final String otp;

  @override
  List<Object?> get props => [email, otp];
}
