import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/category_visuals.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/usecases/get_categories_usecase.dart';

/// Fixes a real gap: category names were previously a hardcoded Dart
/// constant (kBusinessCategories), completely disconnected from the
/// backend's categories table — an admin could never add a new category
/// without shipping a new app build. This fetches the live list instead.
final categoriesProvider = FutureProvider<List<CategoryEntity>>((ref) async {
  final useCase = sl<GetCategoriesUseCase>();
  final result = await useCase(const NoParams());
  final categories = result.fold((_) => const <CategoryEntity>[], (categories) => categories);
  // Side effect, deliberately: CategoryVisuals.iconFor/colorFor are called
  // from plain (non-Riverpod) functions all over the map/list UI that
  // only have a category name string to work with, not a WidgetRef — see
  // category_visuals.dart's doc comment for why that's the right
  // tradeoff here instead of threading a provider through every call site.
  CategoryVisuals.update(categories);
  return categories;
});

/// Just the names, for widgets that only need strings (dropdowns, chip
/// labels) and don't care about icon metadata.
final categoryNamesProvider = Provider<List<String>>((ref) {
  final categoriesAsync = ref.watch(categoriesProvider);
  return categoriesAsync.maybeWhen(
    data: (categories) => categories.map((c) => c.name).toList(),
    orElse: () => const <String>[],
  );
});
