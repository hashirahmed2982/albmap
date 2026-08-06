import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// 7. Notifications Screen — server-synced feed (see notifications_providers.dart).
/// Every approved broadcast and personal notice visible to the current
/// user lives here now, not just whatever this one device happened to
/// receive locally.
///
/// No swipe-to-delete here (unlike the old purely-local version) — this
/// is now a shared, server-side record, and there's no endpoint for a
/// user to delete someone else's (or even their own) copy of it. Marking
/// read/unread is the only per-user state that exists.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);
    final dateFmt = DateFormat('MMM d, HH:mm', context.locale.languageCode);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            GradientHeader(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('notifications.title'.tr(), style: AppTextStyles.h1),
                        const SizedBox(height: 4),
                        Text('notifications.subtitle'.tr(), style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ),
                  if (state.unreadCount > 0)
                    TextButton(
                      onPressed: () => ref.read(notificationsControllerProvider.notifier).markAllAsRead(),
                      child: Text('notifications.markAllRead'.tr()),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Builder(builder: (context) {
                if (state.isLoading && state.notifications.isEmpty) {
                  return const LoadingIndicator();
                }
                if (state.errorMessage != null && state.notifications.isEmpty) {
                  return ErrorStateWidget(
                    message: state.errorMessage!,
                    onRetry: () => ref.read(notificationsControllerProvider.notifier).load(),
                  );
                }
                if (state.notifications.isEmpty) {
                  return EmptyStateWidget(
                    message: 'notifications.empty'.tr(),
                    icon: Icons.notifications_off_outlined,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(notificationsControllerProvider.notifier).load(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: state.notifications.length,
                    itemBuilder: (context, i) {
                      final NotificationEntity n = state.notifications[i];
                      final Color accent = _colorFor(n.type);
                      return Container(
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
                            onTap: n.isRead
                                ? null
                                : () => ref.read(notificationsControllerProvider.notifier).markAsRead(n.id),
                            leading: CircleAvatar(
                              backgroundColor: accent.withValues(alpha: 0.12),
                              child: Icon(_iconFor(n.type), color: accent),
                            ),
                            title: Text(n.title, style: AppTextStyles.h3),
                            subtitle: Text(
                              n.businessName != null ? '${n.businessName} · ${n.body}' : n.body,
                              style: AppTextStyles.bodyMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(dateFmt.format(n.createdAt), style: AppTextStyles.caption),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
