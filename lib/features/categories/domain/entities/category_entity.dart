import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  const CategoryEntity({required this.name, this.nameDe, this.nameSq, this.iconName});

  /// Canonical (English) name — what businesses.category actually stores
  /// and matches against. [nameDe]/[nameSq] are display-only translations,
  /// required alongside it on every category an admin creates/edits (see
  /// CategoryVisuals.translatedName for how a UI picks the right one).
  final String name;
  final String? nameDe;
  final String? nameSq;
  final String? iconName;

  @override
  List<Object?> get props => [name, nameDe, nameSq, iconName];
}
