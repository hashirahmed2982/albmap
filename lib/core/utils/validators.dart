/// Centralized form-field validators.
///
/// Every screen used to hand-roll its own `validator: (v) => ...` closures,
/// which meant the "email" check on the login screen (`v.contains('@')`)
/// accepted garbage like `"@"` or `"a@"` while another screen might do
/// something slightly different. Centralizing these keeps every field in
/// the app to the same bar and makes fixing a rule (e.g. tightening the
/// email regex) a one-line change instead of a grep-and-replace across a
/// dozen files.
///
/// All validators return `null` when the value is valid, otherwise a
/// human-readable (already-translated) error string.
library;

class Validators {
  Validators._();

  /// RFC-5322-ish email pattern — deliberately not the "full spec" regex
  /// (that one is famously enormous and still wrong); this catches the
  /// realistic classes of typo'd input we actually see: missing '@',
  /// missing domain, missing TLD, stray spaces, multiple '@'.
  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
  );

  /// Characters a phone number is allowed to be made of: an optional
  /// leading '+', digits, and the usual separators (space, hyphen,
  /// parentheses, dot) — covers "(069) 123 4567", "+355 69-123-4567",
  /// "069.123.4567", etc. Letters or anything else fail this first.
  static final RegExp _phoneAllowedChars = RegExp(r'^\+?[0-9\s\-().]+$');

  static String? required(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? email(String? value, {required String requiredMessage, required String invalidMessage}) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return requiredMessage;
    if (!_emailPattern.hasMatch(trimmed)) return invalidMessage;
    return null;
  }

  /// A phone "looks valid" if it's built only from digits/+/separators
  /// (checked via [_phoneAllowedChars]) *and* has a realistic number of
  /// actual digits once separators are stripped — anchoring on digit
  /// *count* rather than a strict positional pattern is what lets
  /// "(069) 123 4567" pass without also letting "123" or "call me" pass.
  static bool _looksLikePhone(String value) {
    if (!_phoneAllowedChars.hasMatch(value)) return false;
    final int digitCount = value.replaceAll(RegExp(r'[^0-9]'), '').length;
    return digitCount >= 7 && digitCount <= 15;
  }

  /// Phone is treated as optional across the app (business/profile forms
  /// let it be left blank), but if the user *did* type something, it has
  /// to look like a phone number rather than silently accepting anything.
  static String? optionalPhone(String? value, {required String invalidMessage}) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (!_looksLikePhone(trimmed)) return invalidMessage;
    return null;
  }

  static String? requiredPhone(String? value, {required String requiredMessage, required String invalidMessage}) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return requiredMessage;
    if (!_looksLikePhone(trimmed)) return invalidMessage;
    return null;
  }

  static String? password(
    String? value, {
    required String requiredMessage,
    required String tooShortMessage,
    int minLength = 6,
  }) {
    if (value == null || value.isEmpty) return requiredMessage;
    if (value.length < minLength) return tooShortMessage;
    return null;
  }

  static String? confirmPassword(String? value, String original, {required String requiredMessage, required String mismatchMessage}) {
    if (value == null || value.isEmpty) return requiredMessage;
    if (value != original) return mismatchMessage;
    return null;
  }

  /// The email-verification code shown at signup — always exactly 6 digits.
  static String? otp(String? value, {required String requiredMessage, required String invalidMessage}) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return requiredMessage;
    if (!RegExp(r'^\d{6}$').hasMatch(trimmed)) return invalidMessage;
    return null;
  }
}
