import 'package:easy_localization/easy_localization.dart';
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
///
/// [searchable] adds a filter field at the top — off by default (a short
/// list like categories doesn't need it and stays exactly as it looked
/// before), but should be turned on for anything long enough that
/// scrolling to find an entry isn't reasonable (e.g. the ~200-country
/// list on Add/Edit Business's Country field).
Future<T?> showSelectionBottomSheet<T>({
  required BuildContext context,
  required String title,
  required List<SelectionOption<T>> options,
  T? selectedValue,
  bool searchable = false,
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
              // Sharp corners, matching every other surface in the app —
              // this sheet builds its own Container (rather than going
              // through the app-wide bottomSheetTheme) so it needs its own
              // border for the same depth cue too; only the top edge is
              // visible (the rest is flush with the screen), same
              // convention as the bottom nav bar's top-only border.
              border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
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
                    child: searchable
                        ? _SearchableOptionList(
                            scrollController: scrollController,
                            options: options,
                            selectedValue: selectedValue,
                          )
                        : _OptionList(
                            scrollController: scrollController,
                            options: options,
                            selectedValue: selectedValue,
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

class _OptionList<T> extends StatelessWidget {
  const _OptionList({required this.scrollController, required this.options, required this.selectedValue});

  final ScrollController scrollController;
  final List<SelectionOption<T>> options;
  final T? selectedValue;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
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
    );
  }
}

/// Same list, with a filter field above it — its own small StatefulWidget
/// since narrowing the list as the user types needs local state the
/// (stateless) bottom sheet builder above doesn't otherwise have any
/// reason to carry.
class _SearchableOptionList<T> extends StatefulWidget {
  const _SearchableOptionList({required this.scrollController, required this.options, required this.selectedValue});

  final ScrollController scrollController;
  final List<SelectionOption<T>> options;
  final T? selectedValue;

  @override
  State<_SearchableOptionList<T>> createState() => _SearchableOptionListState<T>();
}

class _SearchableOptionListState<T> extends State<_SearchableOptionList<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.options
        : widget.options.where((o) => o.label.toLowerCase().contains(query)).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: TextField(
            autofocus: false,
            onChanged: (v) => setState(() => _query = v),
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, size: 20),
              hintText: 'common.search'.tr(),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text('common.noResults'.tr(), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)))
              : _OptionList(scrollController: widget.scrollController, options: filtered, selectedValue: widget.selectedValue),
        ),
      ],
    );
  }
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
    this.searchable = false,
    super.key,
  });

  final String label;
  final List<SelectionOption<T>> options;
  final T? selectedValue;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final String? Function(T?)? validator;
  /// Adds a filter field to the bottom sheet — see showSelectionBottomSheet's
  /// doc for when to turn this on.
  final bool searchable;

  @override
  Widget build(BuildContext context) {
    final SelectionOption<T>? selected =
        options.where((o) => o.value == selectedValue).cast<SelectionOption<T>?>().firstOrNull;

    return FormField<T>(
      initialValue: selectedValue,
      validator: validator,
      builder: (state) {
        return InkWell(
          onTap: () async {
            final result = await showSelectionBottomSheet<T>(
              context: context,
              title: label,
              options: options,
              selectedValue: selectedValue,
              searchable: searchable,
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
