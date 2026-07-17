import 'package:flutter/widgets.dart';

/// Business/event category names come from the backend (an admin-managed
/// data table), not from the app's static translation JSON files — so they
/// can't just use `.tr()` the way a fixed UI string can. This is a small,
/// explicit translation map instead: safe by construction, since an
/// untranslated category (e.g. one an admin adds later that isn't in this
/// map yet) simply falls back to showing its original English name rather
/// than an ugly raw translation key.
const Map<String, Map<String, String>> _categoryTranslations = {
  'Restaurants': {'sq': 'Restorante', 'de': 'Restaurants'},
  'Cafes': {'sq': 'Kafene', 'de': 'Cafés'},
  'Shops': {'sq': 'Dyqane', 'de': 'Geschäfte'},
  'Services': {'sq': 'Shërbime', 'de': 'Dienstleistungen'},
  'Health': {'sq': 'Shëndeti', 'de': 'Gesundheit'},
  'Entertainment': {'sq': 'Argëtim', 'de': 'Unterhaltung'},
  'Other': {'sq': 'Tjetër', 'de': 'Sonstiges'},
  'General': {'sq': 'Të përgjithshme', 'de': 'Allgemein'},
  'Music': {'sq': 'Muzikë', 'de': 'Musik'},
  'Food': {'sq': 'Ushqim', 'de': 'Essen'},
  'Sports': {'sq': 'Sport', 'de': 'Sport'},
  'Workshop': {'sq': 'Punëtori', 'de': 'Workshop'},
  'Community': {'sq': 'Komunitet', 'de': 'Gemeinschaft'},
};

String localizedCategoryName(BuildContext context, String rawName) {
  final languageCode = Localizations.localeOf(context).languageCode;
  if (languageCode == 'en') return rawName;
  return _categoryTranslations[rawName]?[languageCode] ?? rawName;
}
