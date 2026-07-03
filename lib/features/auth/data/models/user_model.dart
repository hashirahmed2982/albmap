import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.role,
    super.name,
    super.phone,
    super.profileImageUrl,
    super.isEmailVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (UserRole r) => r.name == json['role'],
        orElse: () => UserRole.guest,
      ),
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'role': role.name,
      'name': name,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'isEmailVerified': isEmailVerified,
    };
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      role: entity.role,
      name: entity.name,
      phone: entity.phone,
      profileImageUrl: entity.profileImageUrl,
      isEmailVerified: entity.isEmailVerified,
    );
  }
}
