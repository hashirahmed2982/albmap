import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  const CategoryEntity({required this.name, this.iconName});

  final String name;
  final String? iconName;

  @override
  List<Object?> get props => [name, iconName];
}
