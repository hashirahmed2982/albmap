import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/opening_hours_editor.dart' show DayHours, kWeekdayKeys;

/// Whether a business is open right now, computed purely from the
/// `openingHours` map already fetched with every business (no network
/// call, no backend change needed) — this used to be information only
/// visible after tapping into Business Details; nothing in the list/map
/// view let you tell at a glance.
enum BusinessOpenStatus {
  open,
  closed,
  /// No hours were ever entered for this business — deliberately distinct
  /// from [closed] so the UI can omit the badge entirely rather than
  /// falsely claim a place is closed when the truth is just "unknown".
  unknown,
}

BusinessOpenStatus businessOpenStatus(Map<String, String> openingHours, {DateTime? now}) {
  if (openingHours.isEmpty) return BusinessOpenStatus.unknown;

  final DateTime n = now ?? DateTime.now();
  // DateTime.weekday is 1 (Monday) .. 7 (Sunday), matching kWeekdayKeys' order.
  final String todayKey = kWeekdayKeys[n.weekday - 1];
  final DayHours today = DayHours.fromStoredString(openingHours[todayKey]);
  if (!today.isOpen || today.openTime == null || today.closeTime == null) {
    return BusinessOpenStatus.closed;
  }

  final int nowMinutes = n.hour * 60 + n.minute;
  final int openMinutes = today.openTime!.hour * 60 + today.openTime!.minute;
  final int closeMinutes = today.closeTime!.hour * 60 + today.closeTime!.minute;

  if (closeMinutes > openMinutes) {
    return (nowMinutes >= openMinutes && nowMinutes < closeMinutes)
        ? BusinessOpenStatus.open
        : BusinessOpenStatus.closed;
  }
  // Overnight range (e.g. 20:00-02:00): open from openMinutes through
  // midnight, then again from midnight through closeMinutes.
  return (nowMinutes >= openMinutes || nowMinutes < closeMinutes)
      ? BusinessOpenStatus.open
      : BusinessOpenStatus.closed;
}

/// Small color-coded pill — "Open now" / "Closed" — for list cards, map
/// marker popups, and the details header. Renders nothing for
/// [BusinessOpenStatus.unknown] so a business with no hours entered
/// doesn't show a potentially-wrong badge.
class OpenStatusBadge extends StatelessWidget {
  const OpenStatusBadge({required this.openingHours, super.key, this.dense = false});

  final Map<String, String> openingHours;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final status = businessOpenStatus(openingHours);
    if (status == BusinessOpenStatus.unknown) return const SizedBox.shrink();

    final bool isOpen = status == BusinessOpenStatus.open;
    final Color color = isOpen ? AppColors.success : AppColors.error;
    final String label = isOpen ? 'business.openNow'.tr() : 'business.closedNow'.tr();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 6 : 8, vertical: dense ? 1 : 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: dense ? 10 : 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
