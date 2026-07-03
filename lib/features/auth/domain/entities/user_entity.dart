import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    required this.role,
    this.name,
    this.phone,
    this.profileImageUrl,
    this.isEmailVerified = false,
  });

  final String id;
  final String email;
  final UserRole role;
  final String? name;
  final String? phone;
  final String? profileImageUrl;
  final bool isEmailVerified;

  bool get isGuest => role == UserRole.guest;
  bool get isBusinessUser => role == UserRole.business;

  @override
  List<Object?> get props =>
      [id, email, role, name, phone, profileImageUrl, isEmailVerified];
}
