import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Canonical day order/labels — used both by the picker (input) and by
/// display widgets (Business Details) so hours always render in the same
/// Mon→Sun order regardless of the Map's natural (insertion/alphabetical)
/// iteration order.
const List<String> kWeekdayKeys = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class DayHours {
  DayHours({this.isOpen = false, this.openTime, this.closeTime});

  bool isOpen;
  TimeOfDay? openTime;
  TimeOfDay? closeTime;

  String? toStoredString() {
    if (!isOpen || openTime == null || closeTime == null) return null;
    return '${_fmt(openTime!)}-${_fmt(closeTime!)}';
  }

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static DayHours fromStoredString(String? value) {
    if (value == null || !value.contains('-')) return DayHours();
    final parts = value.split('-');
    if (parts.length != 2) return DayHours();
    final open = _parseTime(parts[0]);
    final close = _parseTime(parts[1]);
    if (open == null || close == null) return DayHours();
    return DayHours(isOpen: true, openTime: open, closeTime: close);
  }

  static TimeOfDay? _parseTime(String value) {
    final parts = value.trim().split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }
}

/// Editable per-weekday opening-hours section for Add/Edit Business.
/// Produces a `Map<String, String>` in the exact `{"Mon": "09:00-18:00"}`
/// shape the backend/BusinessEntity already expect — this widget fixes the
/// gap where that field existed end-to-end but nothing in the UI ever
/// populated it, so every business showed no hours at all.
class OpeningHoursEditor extends StatefulWidget {
  const OpeningHoursEditor({required this.initialHours, required this.onChanged, super.key});

  final Map<String, String> initialHours;
  final ValueChanged<Map<String, String>> onChanged;

  @override
  State<OpeningHoursEditor> createState() => _OpeningHoursEditorState();
}

class _OpeningHoursEditorState extends State<OpeningHoursEditor> {
  late final Map<String, DayHours> _days;

  @override
  void initState() {
    super.initState();
    _days = {
      for (final day in kWeekdayKeys) day: DayHours.fromStoredString(widget.initialHours[day]),
    };
  }

  void _emitChange() {
    final result = <String, String>{};
    for (final day in kWeekdayKeys) {
      final stored = _days[day]!.toStoredString();
      if (stored != null) result[day] = stored;
    }
    widget.onChanged(result);
  }

  Future<void> _pickTime({required String day, required bool isOpenTime}) async {
    final current = isOpenTime ? _days[day]!.openTime : _days[day]!.closeTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null) return;
    setState(() {
      if (isOpenTime) {
        _days[day]!.openTime = picked;
      } else {
        _days[day]!.closeTime = picked;
      }
    });
    _emitChange();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final day in kWeekdayKeys) _buildDayRow(day),
      ],
    );
  }

  Widget _buildDayRow(String day) {
    final hours = _days[day]!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hours.isOpen ? AppColors.primary.withValues(alpha: 0.04) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(day, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          ),
          Switch(
            value: hours.isOpen,
            activeThumbColor: AppColors.primary,
            onChanged: (value) {
              setState(() => hours.isOpen = value);
              _emitChange();
            },
          ),
          Expanded(
            child: hours.isOpen
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _TimeChip(
                        label: hours.openTime?.format(context) ?? 'hours.openPlaceholder'.tr(),
                        onTap: () => _pickTime(day: day, isOpenTime: true),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text('–', style: AppTextStyles.bodySmall),
                      ),
                      _TimeChip(
                        label: hours.closeTime?.format(context) ?? 'hours.closePlaceholder'.tr(),
                        onTap: () => _pickTime(day: day, isOpenTime: false),
                      ),
                    ],
                  )
                :  Align(
                    alignment: Alignment.centerRight,
                    child: Text('hours.closed'.tr(), style: AppTextStyles.bodySmall),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Read-only display counterpart, used on Business Details — renders in
/// canonical Mon→Sun order and collapses consecutive identical ranges
/// (e.g. "Mon-Fri: 09:00-18:00") instead of one row per day, which is both
/// more compact and how most real business-hours listings are shown.
class OpeningHoursDisplay extends StatelessWidget {
  const OpeningHoursDisplay({required this.hours, super.key});
  final Map<String, String> hours;

  @override
  Widget build(BuildContext context) {
    final entries = _collapseSameRanges();
    if (entries.isEmpty) {
      return Text('hours.notProvided'.tr(), style: AppTextStyles.bodySmall);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry.key, style: AppTextStyles.bodyMedium),
                Text(
                  entry.value,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<MapEntry<String, String>> _collapseSameRanges() {
    final ordered = [
      for (final day in kWeekdayKeys)
        if (hours[day] != null) MapEntry(day, hours[day]!),
    ];
    if (ordered.isEmpty) return [];

    final result = <MapEntry<String, String>>[];
    int i = 0;
    while (i < ordered.length) {
      int j = i;
      while (j + 1 < ordered.length && ordered[j + 1].value == ordered[i].value) {
        j++;
      }
      final label = i == j ? ordered[i].key : '${ordered[i].key}-${ordered[j].key}';
      result.add(MapEntry(label, _prettyRange(ordered[i].value)));
      i = j + 1;
    }
    return result;
  }

  String _prettyRange(String stored) {
    final parts = stored.split('-');
    if (parts.length != 2) return stored;
    return '${parts[0]} - ${parts[1]}';
  }
}
