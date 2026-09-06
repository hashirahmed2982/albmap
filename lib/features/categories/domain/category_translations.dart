import 'package:flutter/widgets.dart';

import 'category_visuals.dart';

/// Business/event category names come from the backend (an admin-managed
/// data table), not from the app's static translation JSON files — so
/// they can't just use `.tr()` the way a fixed UI string can. This used
/// to be a small hardcoded `Map<String, Map<String, String>>` of
/// translations bundled with the app, which meant any category an admin
/// added (or an existing one they only had in English) just never got
/// translated without a new app release. Categories now carry their own
/// nameDe/nameSq from the backend (required on every category — see
/// albmap-backend's category.service.js), cached by CategoryVisuals the
/// same way its icon/color lookups already were; this is now a thin
/// wrapper around that.
String localizedCategoryName(BuildContext context, String rawName) {
  final languageCode = Localizations.localeOf(context).languageCode;
  return CategoryVisuals.translatedName(rawName, languageCode);
}
