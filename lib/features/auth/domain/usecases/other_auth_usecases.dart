import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

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

class ChangePasswordParams extends Equatable {
  const ChangePasswordParams({required this.currentPassword, required this.newPassword});
  final String currentPassword;
  final String newPassword;

  @override
  List<Object?> get props => [currentPassword, newPassword];
}

class ChangePasswordUseCase implements UseCase<void, ChangePasswordParams> {
  ChangePasswordUseCase(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, void>> call(ChangePasswordParams params) {
    return _repository.changePassword(
      currentPassword: params.currentPassword,
      newPassword: params.newPassword,
    );
  }
}

class UpdateProfileParams extends Equatable {
  const UpdateProfileParams({this.name, this.phone, this.profileImageUrl});
  final String? name;
  final String? phone;
  final String? profileImageUrl;

  @override
  List<Object?> get props => [name, phone, profileImageUrl];
}

class UpdateProfileUseCase implements UseCase<UserEntity, UpdateProfileParams> {
  UpdateProfileUseCase(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(UpdateProfileParams params) {
    return _repository.updateProfile(
      name: params.name,
      phone: params.phone,
      profileImageUrl: params.profileImageUrl,
    );
  }
}

class UploadAvatarUseCase implements UseCase<UserEntity, String> {
  UploadAvatarUseCase(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(String filePath) {
    return _repository.uploadAvatar(filePath);
  }
}
