import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/page_header_title.dart';
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
/// Swipe-to-delete and "Clear all" hide a notification from just this
/// user's feed server-side (see DELETE /notifications[/:id] on the
/// backend) — the underlying row is shared across every recipient, so
/// this can never remove it for anyone else. Tapping a notification marks
/// it read and, for anything business-related, deep-links to that
/// business — matching what tapping the equivalent push notification
/// already does (see FcmService._handleNotificationTap).
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  void _handleTap(BuildContext context, WidgetRef ref, NotificationEntity n) {
    if (!n.isRead) {
      ref.read(notificationsControllerProvider.notifier).markAsRead(n.id);
    }
    // relatedId is the business id for every type the backend currently
    // sends (business_offer, business_approved, business_rejected) — see
    // notification.service.js. There's no event-related notification yet,
    // and 'general' has nothing to deep-link to.
    switch (n.type) {
      case 'business_offer':
      case 'business_approved':
      case 'business_rejected':
        if (n.relatedId != null && n.relatedId!.isNotEmpty) {
          context.push(AppRoutes.businessDetailsPath(n.relatedId!));
        }
    }
  }

  Future<void> _deleteOne(BuildContext context, WidgetRef ref, String id) async {
    final bool ok = await ref.read(notificationsControllerProvider.notifier).deleteNotification(id);
    if (!ok && context.mounted) {
      AppToast.error(context, 'notifications.deleteFailed'.tr());
    }
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('notifications.clearAllConfirmTitle'.tr()),
        content: Text('notifications.clearAllConfirmBody'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('common.cancel'.tr())),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('notifications.clearAll'.tr(), style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final bool ok = await ref.read(notificationsControllerProvider.notifier).clearAll();
    if (!ok && context.mounted) {
      AppToast.error(context, 'notifications.deleteFailed'.tr());
    }
  }

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
              child: PageHeaderTitle(
                title: 'notifications.title'.tr(),
                subtitle: 'notifications.subtitle'.tr(),
                icon: Icons.notifications_rounded,
                showBackButton: false,
                trailing: state.notifications.isEmpty
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (state.unreadCount > 0)
                            TextButton(
                              onPressed: () => ref.read(notificationsControllerProvider.notifier).markAllAsRead(),
                              child: Text('notifications.markAllRead'.tr()),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.textSecondary),
                            tooltip: 'notifications.clearAll'.tr(),
                            onPressed: () => _confirmClearAll(context, ref),
                          ),
                        ],
                      ),
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
                      return Dismissible(
                        key: ValueKey(n.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _deleteOne(context, ref, n.id),
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
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
                              onTap: () => _handleTap(context, ref, n),
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
