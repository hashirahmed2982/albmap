import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/business_providers.dart';

const List<String> kBusinessCategories = [
  'Restaurants', 'Shops', 'Services', 'Cafes', 'Health', 'Entertainment', 'Other',
];

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
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Filter businesses', style: AppTextStyles.h3),
          const SizedBox(height: 16),
          Text('Category', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              for (final c in kBusinessCategories)
                ChoiceChip(
                  label: Text(c),
                  selected: _draft.category == c,
                  onSelected: (sel) => setState(() {
                    _draft = _draft.copyWith(category: sel ? c : null, clearCategory: !sel);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Radius: ${_draft.radiusKm.toStringAsFixed(0)} km', style: AppTextStyles.bodyMedium),
          Slider(
            value: _draft.radiusKm, min: 1, max: 50, divisions: 49,
            onChanged: (v) => setState(() => _draft = _draft.copyWith(radiusKm: v)),
          ),
          const SizedBox(height: 12),
          Text('Sort by', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'distance', label: Text('Distance')),
              ButtonSegment(value: 'popularity', label: Text('Popularity')),
            ],
            selected: {_draft.sortBy},
            onSelectionChanged: (s) => setState(() => _draft = _draft.copyWith(sortBy: s.first)),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Apply filters',
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
