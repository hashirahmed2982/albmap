import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../categories/domain/category_translations.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../providers/business_providers.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late BusinessFilter _draft;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(businessFilterProvider);
  }

  @override
  Widget build(BuildContext context) {
    final categoryNames = ref.watch(categoryNamesProvider);

    return AppBottomSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('filter.title'.tr(), style: AppTextStyles.h3),
          const SizedBox(height: 16),
          Text('filter.category'.tr(), style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              for (final c in categoryNames)
                ChoiceChip(
                  label: Text(localizedCategoryName(context, c)),
                  selected: _draft.category == c,
                  onSelected: (sel) => setState(() {
                    _draft = _draft.copyWith(category: sel ? c : null, clearCategory: !sel);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('filter.radius'.tr(args: [_draft.radiusKm.toStringAsFixed(0)]), style: AppTextStyles.bodyMedium),
          Slider(
            value: _draft.radiusKm, min: 1, max: 50, divisions: 49,
            onChanged: (v) => setState(() => _draft = _draft.copyWith(radiusKm: v)),
          ),
          const SizedBox(height: 12),
          Text('filter.sortBy'.tr(), style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'distance', label: Text('filter.distance'.tr())),
              ButtonSegment(value: 'popularity', label: Text('filter.popularity'.tr())),
            ],
            selected: {_draft.sortBy},
            onSelectionChanged: (s) => setState(() => _draft = _draft.copyWith(sortBy: s.first)),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'filter.apply'.tr(),
            onPressed: () {
              ref.read(businessFilterProvider.notifier).state = _draft;
              ref.read(businessListControllerProvider.notifier).load();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
