import '../models/category_model.dart';
import 'category_remote_datasource.dart';

/// Mirrors the backend's seeded categories exactly (see
/// albmap-backend/src/db/seed.js's CATEGORIES list) so mock and real mode
/// show identical category options.
class CategoryMockDataSource implements CategoryDataSource {
  static const List<CategoryModel> _categories = [
    CategoryModel(name: 'Restaurants', nameDe: 'Restaurants', nameSq: 'Restorante', iconName: 'restaurant_outlined'),
    CategoryModel(name: 'Cafes', nameDe: 'Cafés', nameSq: 'Kafene', iconName: 'coffee_outlined'),
    CategoryModel(name: 'Shops', nameDe: 'Geschäfte', nameSq: 'Dyqane', iconName: 'storefront_outlined'),
    CategoryModel(name: 'Services', nameDe: 'Dienstleistungen', nameSq: 'Shërbime', iconName: 'build_outlined'),
    CategoryModel(name: 'Health', nameDe: 'Gesundheit', nameSq: 'Shëndeti', iconName: 'fitness_center_outlined'),
    CategoryModel(name: 'Entertainment', nameDe: 'Unterhaltung', nameSq: 'Argëtim', iconName: 'local_movies_outlined'),
    CategoryModel(name: 'Other', nameDe: 'Sonstiges', nameSq: 'Tjetër', iconName: 'category_outlined'),
  ];

  @override
  Future<List<CategoryModel>> getCategories() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _categories;
  }
}
