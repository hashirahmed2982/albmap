import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'entities/category_entity.dart';

/// Icon/color for a category name, driven by backend data instead of a
/// hardcoded `switch (category) { case 'Restaurants': ... }` — the
/// previous version meant an admin could never add a category without
/// shipping a new app build, since anything not in that switch's finite
/// list fell through to a generic default silently.
///
/// [update] is called once `categoriesProvider` resolves (see
/// category_providers.dart) to cache the backend's name -> iconName
/// mapping. Exposed as plain static lookups — rather than a Riverpod
/// provider — because `categoryIcon`/`categoryColor` are called from
/// many leaf widgets (map pins, list cards, dashboards) that only have a
/// category *name* string, not a `WidgetRef`; threading one through
/// every call site for a lookup this simple isn't worth the churn.
class CategoryVisuals {
  CategoryVisuals._();

  static Map<String, String?> _iconNamesByCategory = const {};

  static void update(List<CategoryEntity> categories) {
    _iconNamesByCategory = {for (final c in categories) c.name: c.iconName};
  }

  /// Recognized `iconName` values a category can carry from the backend.
  /// Deliberately broader than the categories currently seeded — an
  /// admin adding a new category later just needs to pick one of these
  /// names, no app update required. Unrecognized/missing names fall back
  /// to [_hashFallbackIcon] so nothing ever renders a blank icon.
  static const Map<String, IconData> _iconsByName = {
    'restaurant_outlined': Icons.restaurant_outlined,
    'coffee_outlined': Icons.coffee_outlined,
    'storefront_outlined': Icons.storefront_outlined,
    'build_outlined': Icons.build_outlined,
    'fitness_center_outlined': Icons.fitness_center_outlined,
    'local_movies_outlined': Icons.local_movies_outlined,
    'shopping_bag_outlined': Icons.shopping_bag_outlined,
    'spa_outlined': Icons.spa_outlined,
    'school_outlined': Icons.school_outlined,
    'local_hospital_outlined': Icons.local_hospital_outlined,
    'sports_soccer_outlined': Icons.sports_soccer_outlined,
    'music_note_outlined': Icons.music_note_outlined,
    'celebration_outlined': Icons.celebration_outlined,
    'groups_outlined': Icons.groups_outlined,
    'palette_outlined': Icons.palette_outlined,
    'local_bar_outlined': Icons.local_bar_outlined,
    'pets_outlined': Icons.pets_outlined,
    'directions_car_outlined': Icons.directions_car_outlined,
    'home_repair_service_outlined': Icons.home_repair_service_outlined,
    'checkroom_outlined': Icons.checkroom_outlined,
    'local_florist_outlined': Icons.local_florist_outlined,
    'bakery_dining_outlined': Icons.bakery_dining_outlined,
    'local_cafe_outlined': Icons.local_cafe_outlined,
    'theater_comedy_outlined': Icons.theater_comedy_outlined,
    'business_center_outlined': Icons.business_center_outlined,
  };

  // A handful of visually-distinct fallback icons — hashed into, not
  // matched semantically, for any category the app has no iconName for.
  static const List<IconData> _fallbackIcons = [
    Icons.category_outlined,
    Icons.storefront_outlined,
    Icons.local_offer_outlined,
    Icons.place_outlined,
    Icons.star_outline_rounded,
  ];

  // Curated so every color stays legible as white-on-color (marker pins,
  // badges) and doesn't clash with the brand red used for primary
  // actions/selection state elsewhere in the app.
  static const List<Color> _palette = [
    Color(0xFFFF7043),
    Color(0xFF8D6E63),
    Color(0xFF66BB6A),
    Color(0xFF42A5F5),
    Color(0xFFEC407A),
    Color(0xFFAB47BC),
    Color(0xFF26A69A),
    Color(0xFFFFA726),
    Color(0xFF5C6BC0),
    Color(0xFF7CB342),
  ];

  static int _hash(String category) => category.codeUnits.fold(0, (acc, c) => acc + c);

  static IconData iconFor(String category) {
    final String? iconName = _iconNamesByCategory[category];
    if (iconName != null && _iconsByName.containsKey(iconName)) {
      return _iconsByName[iconName]!;
    }
    if (category.isEmpty) return _fallbackIcons.first;
    return _fallbackIcons[_hash(category) % _fallbackIcons.length];
  }

  static Color colorFor(String category) {
    if (category.isEmpty) return AppColors.primary;
    return _palette[_hash(category) % _palette.length];
  }
}
