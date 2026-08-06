import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/event_entity.dart';

IconData eventCategoryIcon(String category) {
  switch (category) {
    case 'Music':
      return Icons.music_note_outlined;
    case 'Food':
      return Icons.restaurant_outlined;
    case 'Sports':
      return Icons.sports_soccer_outlined;
    case 'Workshop':
      return Icons.school_outlined;
    case 'Community':
      return Icons.groups_outlined;
    default:
      return Icons.event_outlined;
  }
}

Color eventCategoryColor(String category) {
  switch (category) {
    case 'Music':
      return const Color(0xFFAB47BC);
    case 'Food':
      return const Color(0xFFFF7043);
    case 'Sports':
      return const Color(0xFF42A5F5);
    case 'Workshop':
      return const Color(0xFF66BB6A);
    case 'Community':
      return const Color(0xFFEC407A);
    default:
      return AppColors.secondary;
  }
}

class EventListTile extends StatelessWidget {
  const EventListTile({required this.event, super.key});
  final EventEntity event;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, MMM d · HH:mm', context.locale.languageCode);
    final Color accent = eventCategoryColor(event.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(AppRoutes.eventDetailsPath(event.id)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: event.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(AppConstants.resolveMediaUrl(event.imageUrl)!, fit: BoxFit.cover),
                        )
                      : Icon(eventCategoryIcon(event.category), color: accent, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.name, style: AppTextStyles.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(event.businessName, style: AppTextStyles.bodySmall),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 14, color: accent),
                          const SizedBox(width: 4),
                          Text(dateFmt.format(event.startTime), style: AppTextStyles.bodySmall.copyWith(color: accent, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
