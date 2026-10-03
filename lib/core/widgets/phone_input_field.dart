import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Phone-number input with a country dial-code dropdown in front of it —
/// used everywhere the app collects a phone number (profile, business
/// phone, business WhatsApp number) so every number is saved as
/// "+<dial code><local number>" instead of the country-less free text it
/// used to be.
///
/// [controller] holds the FULL composed value ("+355691234567") both
/// before and after this widget edits it — every existing call site
/// already reads `controller.text.trim()` at submit time and that keeps
/// working unchanged; this widget only ever reaches into it to read the
/// starting value once and to write the recomposed value back out.
class PhoneInputField extends StatefulWidget {
  const PhoneInputField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  /// Runs against the LOCAL NUMBER only (no dial code) — exactly what
  /// Validators.optionalPhone/requiredPhone already expect, since a
  /// national number's own digit count (7-15) is what those check.
  final String? Function(String?)? validator;
  /// Receives the FULL composed value, same as controller.text would hold
  /// after the change — some screens re-derive other UI off the phone
  /// field changing (see add_business_screen.dart's WhatsApp checkbox).
  final ValueChanged<String>? onChanged;

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late String _dialCode;
  late final TextEditingController _localController;

  @override
  void initState() {
    super.initState();
    final (dialCode, localNumber) = _splitStoredPhone(widget.controller.text);
    _dialCode = dialCode;
    _localController = TextEditingController(text: localNumber);
  }

  @override
  void dispose() {
    _localController.dispose();
    super.dispose();
  }

  /// Best-effort split of a stored phone value into (dial code, local
  /// number): tries the longest dial-code prefix that matches (so "+1"
  /// doesn't shadow "+1684"), defaulting to Albania — this app's home
  /// market — and leaving the value untouched as the local number when it
  /// doesn't start with "+" at all (old free-text entries predating this
  /// field, e.g. "0691234567") or no dial code matches. Imperfect for
  /// that legacy case (the local number keeps whatever leading trunk
  /// digit it already had), but never loses or corrupts data — the
  /// person can always re-type it once if they notice.
  static (String, String) _splitStoredPhone(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('+')) {
      final sorted = [...codes]
        ..sort((a, b) => (b['dial_code']?.length ?? 0).compareTo(a['dial_code']?.length ?? 0));
      for (final c in sorted) {
        final dial = c['dial_code'];
        if (dial != null && trimmed.startsWith(dial)) {
          return (dial, trimmed.substring(dial.length).trim());
        }
      }
    }
    return ('+355', trimmed);
  }

  void _emitChange() {
    final local = _localController.text.trim();
    final full = local.isEmpty ? '' : '$_dialCode$local';
    widget.controller.text = full;
    widget.onChanged?.call(full);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6, right: 4),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: CountryCodePicker(
            onChanged: (country) {
              setState(() => _dialCode = country.dialCode ?? '+355');
              _emitChange();
            },
            initialSelection: _dialCode,
            favorite: const ['+355'],
            showFlag: true,
            showDropDownButton: true,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            textStyle: const TextStyle(color: AppColors.textPrimary),
            dialogBackgroundColor: AppColors.surface,
            searchStyle: const TextStyle(color: AppColors.textPrimary),
            dialogTextStyle: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
        Expanded(
          child: TextFormField(
            controller: _localController,
            keyboardType: TextInputType.phone,
            maxLength: 15,
            decoration: InputDecoration(labelText: widget.label),
            validator: widget.validator,
            onChanged: (_) => _emitChange(),
          ),
        ),
      ],
    );
  }
}
