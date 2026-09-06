import '../../domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({required super.name, super.nameDe, super.nameSq, super.iconName});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      name: json['name'] as String,
      nameDe: json['nameDe'] as String?,
      nameSq: json['nameSq'] as String?,
      iconName: json['iconName'] as String?,
    );
  }
}
