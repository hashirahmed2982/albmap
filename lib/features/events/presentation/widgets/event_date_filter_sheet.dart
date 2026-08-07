import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../providers/event_providers.dart';

/// Date-range narrowing for the Events list. Each preset applies
/// immediately and closes the sheet (this is a one-tap action list, not a
/// form with a separate "Apply" step) — "All upcoming" clears the filter
/// entirely rather than being "no selection", since finished events are
/// always excluded anyway (see eventsProvider), so this is really
/// choosing *which* upcoming window to look at.
class EventDateFilterSheet extends ConsumerWidget {
  const EventDateFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(eventFilterProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    void apply(DateTime? from, DateTime? to) {
      ref.read(eventFilterProvider.notifier).state = filter.copyWith(
        fromDate: from,
        toDate: to,
        clearFromDate: from == null,
        clearToDate: to == null,
      );
      Navigator.of(context).pop();
    }

    Future<void> pickCustomRange() async {
      final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        firstDate: today,
        lastDate: today.add(const Duration(days: 365 * 2)),
        initialDateRange: DateTimeRange(
          start: filter.fromDate ?? today,
          end: filter.toDate ?? today.add(const Duration(days: 7)),
        ),
      );
      if (picked == null || !context.mounted) return;
      // End-of-day on the picked "to" date so an event later that same
      // day is still included, not excluded by an exact-midnight cutoff.
      final DateTime endOfDay =
          DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      apply(picked.start, endOfDay);
    }

    return AppBottomSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('events.filterByDate'.tr(), style: AppTextStyles.h3),
          const SizedBox(height: 12),
          _DateFilterTile(
            icon: Icons.all_inclusive_rounded,
            label: 'events.allUpcoming'.tr(),
            selected: !filter.hasDateFilter,
            onTap: () => apply(null, null),
          ),
          _DateFilterTile(
            icon: Icons.today_outlined,
            label: 'events.today'.tr(),
            onTap: () => apply(today, DateTime(today.year, today.month, today.day, 23, 59, 59)),
          ),
          _DateFilterTile(
            icon: Icons.view_week_outlined,
            label: 'events.thisWeek'.tr(),
            onTap: () => apply(today, today.add(const Duration(days: 7))),
          ),
          _DateFilterTile(
            icon: Icons.calendar_view_month_outlined,
            label: 'events.thisMonth'.tr(),
            onTap: () => apply(today, DateTime(today.year, today.month + 1, 0, 23, 59, 59)),
          ),
          _DateFilterTile(
            icon: Icons.date_range_outlined,
            label: 'events.customRange'.tr(),
            onTap: pickCustomRange,
          ),
        ],
      ),
    );
  }
}

class _DateFilterTile extends StatelessWidget {
  const _DateFilterTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (selected ? AppColors.primary : AppColors.textSecondary).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: selected ? AppColors.primary : AppColors.textSecondary),
      ),
      title: Text(
        label,
        style: AppTextStyles.bodyLarge.copyWith(
          color: selected ? AppColors.primary : null,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      trailing: selected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
      onTap: onTap,
    );
  }
}
