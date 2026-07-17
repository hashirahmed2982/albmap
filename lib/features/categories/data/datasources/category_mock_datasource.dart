import '../models/category_model.dart';
import 'category_remote_datasource.dart';

/// Mirrors the backend's seeded categories exactly (see
/// albmap-backend/src/db/seed.js's CATEGORIES list) so mock and real mode
/// show identical category options.
class CategoryMockDataSource implements CategoryDataSource {
  static const List<CategoryModel> _categories = [
    CategoryModel(name: 'Restaurants', iconName: 'restaurant_outlined'),
    CategoryModel(name: 'Cafes', iconName: 'coffee_outlined'),
    CategoryModel(name: 'Shops', iconName: 'storefront_outlined'),
    CategoryModel(name: 'Services', iconName: 'build_outlined'),
    CategoryModel(name: 'Health', iconName: 'fitness_center_outlined'),
    CategoryModel(name: 'Entertainment', iconName: 'local_movies_outlined'),
    CategoryModel(name: 'Other', iconName: 'category_outlined'),
  ];

  @override
  Future<List<CategoryModel>> getCategories() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _categories;
  }
}
