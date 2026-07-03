import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notifications_providers.dart';

IconData _iconFor(String type) {
  switch (type) {
    case 'business_approved':
      return Icons.check_circle_outline;
    case 'business_rejected':
      return Icons.cancel_outlined;
    case 'event_reminder':
      return Icons.event_outlined;
    case 'business_offer':
      return Icons.local_offer_outlined;
    default:
      return Icons.notifications_outlined;
  }
}

Color _colorFor(String type) {
  switch (type) {
    case 'business_approved':
      return AppColors.success;
    case 'business_rejected':
      return AppColors.error;
    case 'event_reminder':
      return AppColors.secondary;
    case 'business_offer':
      return AppColors.secondary;
    default:
      return AppColors.primary;
  }
}

/// 7. Notifications Screen — history + read/unread management.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsControllerProvider);
    final dateFmt = DateFormat('MMM d, HH:mm');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            GradientHeader(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notifications', style: AppTextStyles.h1),
                        const SizedBox(height: 4),
                        const Text('Stay up to date', style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ),
                  if (notifications.any((n) => !n.isRead))
                    TextButton(
                      onPressed: () => ref.read(notificationsControllerProvider.notifier).markAllAsRead(),
                      child: const Text('Mark all read'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: notifications.isEmpty
                  ? const EmptyStateWidget(message: 'No notifications yet', icon: Icons.notifications_off_outlined)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      itemCount: notifications.length,
                      itemBuilder: (context, i) {
                        final NotificationEntity n = notifications[i];
                        final Color accent = _colorFor(n.type);
                        return Dismissible(
                          key: ValueKey(n.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete_outline, color: Colors.white),
                          ),
                          onDismissed: (_) => ref.read(notificationsControllerProvider.notifier).delete(n.id),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: n.isRead ? AppColors.surface : accent.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(18),
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                onTap: () => ref.read(notificationsControllerProvider.notifier).markAsRead(n.id),
                                leading: CircleAvatar(
                                  backgroundColor: accent.withValues(alpha: 0.12),
                                  child: Icon(_iconFor(n.type), color: accent),
                                ),
                                title: Text(n.title, style: AppTextStyles.h3),
                                subtitle: Text(n.body, style: AppTextStyles.bodyMedium),
                                trailing: Text(dateFmt.format(n.createdAt), style: AppTextStyles.caption),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
