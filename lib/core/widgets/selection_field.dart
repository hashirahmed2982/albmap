import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A single option shown inside [SelectionBottomSheet] / [SelectionField].
class SelectionOption<T> {
  const SelectionOption({required this.value, required this.label, this.icon, this.subtitle});

  final T value;
  final String label;
  final IconData? icon;
  final String? subtitle;
}

/// Opens a consistent, good-looking bottom sheet to pick one value from a
/// list — used everywhere the app previously used a native
/// [DropdownButtonFormField], which renders very differently (and rather
/// plainly) across Android/iOS and doesn't match the rest of the app's
/// visual language. Returns the picked value, or null if dismissed
/// without picking.
Future<T?> showSelectionBottomSheet<T>({
  required BuildContext context,
  required String title,
  required List<SelectionOption<T>> options,
  T? selectedValue,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: options.length > 6 ? 0.6 : 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(title, style: AppTextStyles.h3)),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SafeArea(
                    top: false,
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: options.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final bool isSelected = option.value == selectedValue;
                        return ListTile(
                          onTap: () => Navigator.of(context).pop(option.value),
                          leading: option.icon != null
                              ? Icon(option.icon, color: isSelected ? AppColors.primary : AppColors.textSecondary)
                              : null,
                          title: Text(
                            option.label,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                          subtitle: option.subtitle != null ? Text(option.subtitle!, style: AppTextStyles.bodySmall) : null,
                          trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20) : null,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// A form-field-styled button that looks like a text field but opens
/// [showSelectionBottomSheet] when tapped, rather than a native dropdown.
/// Drop-in visual replacement for DropdownButtonFormField in this app.
class SelectionField<T> extends StatelessWidget {
  const SelectionField({
    required this.label,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    this.hint,
    this.validator,
    super.key,
  });

  final String label;
  final List<SelectionOption<T>> options;
  final T? selectedValue;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    final SelectionOption<T>? selected =
        options.where((o) => o.value == selectedValue).cast<SelectionOption<T>?>().firstOrNull;

    return FormField<T>(
      initialValue: selectedValue,
      validator: validator,
      builder: (state) {
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final result = await showSelectionBottomSheet<T>(
              context: context,
              title: label,
              options: options,
              selectedValue: selectedValue,
            );
            if (result != null) {
              onChanged(result);
              state.didChange(result);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              errorText: state.errorText,
              suffixIcon: const Icon(Icons.expand_more_rounded, color: AppColors.textSecondary),
            ),
            child: Row(
              children: [
                if (selected?.icon != null) ...[
                  Icon(selected!.icon, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    selected?.label ?? hint ?? 'Select…',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: selected == null ? AppColors.textSecondary : AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
