import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../categories/domain/category_translations.dart';
import '../../../favorites/presentation/providers/favorites_providers.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/usecases/event_usecases.dart';
import '../providers/event_providers.dart';
import 'event_list_tile.dart';

final _eventDetailsProvider =
    FutureProvider.autoDispose.family<EventEntity?, String>((ref, id) async {
  final useCase = sl<GetEventsUseCase>();
  final result = await useCase(const GetEventsParams());
  return result.fold(
    (_) => null,
    (events) => events.where((e) => e.id == id).firstOrNull,
  );
});

/// Event details — shown from Events list, Business details, or Favorites.
class EventDetailsScreen extends ConsumerWidget {
  const EventDetailsScreen({required this.eventId, super.key});
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(_eventDetailsProvider(eventId));
    final authState = ref.watch(authControllerProvider);
    final bool canFavorite = authState.user?.isBusinessUser ?? false;
    final dateFmt = DateFormat('EEEE, MMM d, yyyy · HH:mm', context.locale.languageCode);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: eventAsync.when(
        loading: () => const LoadingIndicator(),
        error: (_, __) => ErrorStateWidget(message: 'events.failedToLoad'.tr()),
        data: (event) {
          if (event == null) return ErrorStateWidget(message: 'events.notFound'.tr());

          final Color accent = eventCategoryColor(event.category);
          // Was hardcoded to always show the outline heart regardless of
          // whether this event was already favorited (same gap as
          // Business Details' identical button).
          final bool isFavorite = canFavorite && ref.watch(eventIsFavoriteProvider(event.id));

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 200,
                backgroundColor: accent,
                actions: [
                  if (canFavorite)
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? AppColors.primary : Colors.white,
                      ),
                      onPressed: () async {
                        final error =
                            await ref.read(favoriteToggleControllerProvider.notifier).toggleEvent(event);
                        if (error != null && context.mounted) {
                          AppToast.error(context, error);
                        }
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () => Share.share('events.shareText'.tr(args: [event.name, event.businessName])),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: event.imageUrl != null
                      ? AppNetworkImage(url: AppConstants.resolveMediaUrl(event.imageUrl)!)
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [accent, accent.withValues(alpha: 0.7)],
                            ),
                          ),
                          child: Center(
                            child: Icon(eventCategoryIcon(event.category), size: 72, color: Colors.white.withValues(alpha: 0.85)),
                          ),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  // Bottom padding includes the safe-area inset (home
                  // indicator / gesture bar) — no bottom nav or app bar
                  // here to absorb it otherwise.
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                        child: Text(localizedCategoryName(context, event.category), style: AppTextStyles.bodySmall.copyWith(color: accent, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 10),
                      Text(event.name, style: AppTextStyles.h1),
                      const SizedBox(height: 6),
                      Text('events.hostedBy'.tr(args: [event.businessName]), style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 18),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 18, color: accent),
                                const SizedBox(width: 10),
                                Expanded(child: Text(dateFmt.format(event.startTime), style: AppTextStyles.bodyMedium)),
                              ],
                            ),
                            if (event.address != null) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 18, color: accent),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(event.address!, style: AppTextStyles.bodyMedium)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          const Icon(Icons.groups_outlined, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'events.interestedCount'.tr(args: [event.interestCount.toString()]),
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                          if (canFavorite)
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: event.isInterested ? Colors.white : accent,
                                backgroundColor: event.isInterested ? accent : Colors.transparent,
                                side: BorderSide(color: accent),
                                minimumSize: const Size(0, 36),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              icon: Icon(
                                event.isInterested ? Icons.check_circle : Icons.add_circle_outline,
                                size: 18,
                              ),
                              label: Text(
                                event.isInterested
                                    ? 'events.interested'.tr()
                                    : 'events.imInterested'.tr(),
                              ),
                              onPressed: () async {
                                final error = await ref
                                    .read(eventInterestControllerProvider.notifier)
                                    .toggle(event);
                                if (!context.mounted) return;
                                if (error != null) {
                                  AppToast.error(context, error);
                                  return;
                                }
                                // The toggle call itself doesn't return the
                                // updated event — refresh so the button/
                                // count reflect the new server state.
                                ref.invalidate(_eventDetailsProvider(eventId));
                                ref.invalidate(eventsProvider);
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      Text('events.aboutEvent'.tr(), style: AppTextStyles.h3),
                      const SizedBox(height: 8),
                      Text(event.description, style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: accent),
                          icon: const Icon(Icons.calendar_month_outlined),
                          label: Text('events.addToCalendar'.tr()),
                          onPressed: () => Add2Calendar.addEvent2Cal(Event(
                            title: event.name,
                            description: event.description,
                            location: event.address ?? '',
                            startDate: event.startTime,
                            endDate: event.endTime,
                          )),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
