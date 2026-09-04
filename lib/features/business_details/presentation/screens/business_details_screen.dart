import 'dart:async';

import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/url_launcher_helper.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/opening_hours_editor.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../categories/domain/category_translations.dart';
import '../../../dashboard/domain/entities/business_analytics_entity.dart';
import '../../../dashboard/presentation/providers/analytics_providers.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../events/presentation/screens/event_list_tile.dart';
import '../../../favorites/presentation/providers/favorites_providers.dart';
import '../../../map/domain/business_open_status.dart';
import '../../../map/presentation/providers/business_providers.dart';
import '../../../map/presentation/widgets/business_list_view.dart';
import '../../../reviews/domain/entities/review_entity.dart';
import '../../../reviews/presentation/providers/review_providers.dart';
import '../../../reviews/presentation/widgets/review_card.dart';
import '../../../reviews/presentation/widgets/write_review_sheet.dart';

/// 4. Business Details Screen
///
/// A [ConsumerStatefulWidget] (not stateless) specifically so the
/// "profile view" analytics event fires exactly once per visit — a plain
/// ConsumerWidget would re-fire it on every rebuild (e.g. after toggling
/// favorite), inflating the owner's stats.
class BusinessDetailsScreen extends ConsumerStatefulWidget {
  const BusinessDetailsScreen({required this.businessId, super.key});
  final String businessId;

  @override
  ConsumerState<BusinessDetailsScreen> createState() => _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends ConsumerState<BusinessDetailsScreen> {
  bool _viewRecorded = false;

  @override
  Widget build(BuildContext context) {
    final businessAsync = ref.watch(businessDetailsProvider(widget.businessId));
    final authState = ref.watch(authControllerProvider);
    final bool canFavorite = authState.user?.isBusinessUser ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: businessAsync.when(
        loading: () => const LoadingIndicator(),
        error: (_, __) => ErrorStateWidget(message: 'business.failedToLoad'.tr()),
        data: (business) {
          if (business == null) {
            return ErrorStateWidget(message: 'business.notFound'.tr());
          }

          if (!_viewRecorded) {
            _viewRecorded = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              recordAnalyticsEvent(business.id, AnalyticsEventType.profileView);
            });
          }

          final Color accent = categoryColor(business.category);
          final eventsAsync = ref.watch(eventsProvider);
          // Was hardcoded to always show the outline heart regardless of
          // whether this business was already favorited — toggling it
          // worked (the sync/persistence was fine), it just never
          // reflected the current state back visually.
          final bool isFavorite =
              canFavorite && ref.watch(businessIsFavoriteProvider(business.id));

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 220,
                backgroundColor: AppColors.primary,
                elevation: 0,
                // Bold Editorial hero band is always solid accent red
                // (not tinted per-category as before) with circular
                // semi-transparent icon buttons — matching
                // BusinessDetails.png rather than the old
                // category-colored gradient banner.
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _HeroIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.of(context).maybePop()),
                ),
                actions: [
                  if (canFavorite)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _HeroIconButton(
                        icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                        onTap: () async {
                          final error = await ref
                              .read(favoriteToggleControllerProvider.notifier)
                              .toggleBusiness(business);
                          if (error != null && context.mounted) {
                            AppToast.error(context, error);
                          }
                        },
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _HeroIconButton(
                      icon: Icons.ios_share_rounded,
                      onTap: () => Share.share('business.shareText'.tr(args: [business.name])),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: business.logoUrl != null
                      ? AppNetworkImage(url: AppConstants.resolveMediaUrl(business.logoUrl)!)
                      : Container(
                          color: AppColors.primary,
                          child: Center(
                            // Giant faint serif initial as a placeholder
                            // "logo" — matches the mockup's oversized "B"
                            // watermark for a business with no photo.
                            child: Text(
                              business.name.isNotEmpty ? business.name[0].toUpperCase() : '?',
                              style: AppTextStyles.h1.copyWith(
                                fontSize: 160,
                                color: Colors.white.withValues(alpha: 0.18),
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  // Bottom padding includes the device's safe-area inset
                  // (home indicator / gesture bar) — this screen has no
                  // bottom nav bar or app bar to absorb it, so without this
                  // the last row of content sits flush against the very
                  // edge of the screen on notched devices.
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(business.name, style: AppTextStyles.h1),
                      const SizedBox(height: 8),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 6,
                        children: [
                          // Plain small-caps label, not a colored chip —
                          // Bold Editorial reserves color for the two
                          // named accents (red/gold), not per-category
                          // badges.
                          Text(
                            localizedCategoryName(context, business.category).toUpperCase(),
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                          ),
                          if (business.rating != null) ...[
                            Text('·', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 18, color: AppColors.gold),
                                const SizedBox(width: 4),
                                Text(business.rating!.toStringAsFixed(1), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                if (business.ratingCount > 0) ...[
                                  const SizedBox(width: 3),
                                  Text(
                                    '(${business.ratingCount})',
                                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ],
                            ),
                          ],
                          OpenStatusBadge(openingHours: business.openingHours),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Text(
                        business.description,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 20),

                      _InfoRow(icon: Icons.location_on_outlined, text: business.formattedAddress, accent: AppColors.primary),
                      if (business.phone != null)
                        _InfoRow(icon: Icons.phone_outlined, text: business.phone!, accent: AppColors.primary),
                      if (business.distanceKm != null)
                        _InfoRow(
                          icon: Icons.directions_walk,
                          text: 'business.kmAway'.tr(args: [business.distanceKm!.toStringAsFixed(1)]),
                          accent: AppColors.primary,
                        ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Always shown (not just when non-empty) — a business
                      // with no hours entered still gets an honest "Hours
                      // not provided" row rather than the section silently
                      // vanishing, which previously made it look like the
                      // screen simply had no hours feature at all.
                      _SectionLabel('business.openingHours'.tr()),
                      const SizedBox(height: 8),
                      OpeningHoursDisplay(hours: business.openingHours),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.call_outlined),
                              label: Text('business.call'.tr(), overflow: TextOverflow.ellipsis),
                              onPressed: business.phone == null
                                  ? null
                                  : () {
                                      recordAnalyticsEvent(business.id, AnalyticsEventType.callClick);
                                      unawaited(launchUrlSafely(context, Uri.parse('tel:${business.phone}')));
                                    },
                            ),
                          ),
                          if (business.whatsappNumber != null) ...[
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                                onPressed: () {
                                  recordAnalyticsEvent(business.id, AnalyticsEventType.callClick);
                                  // wa.me requires digits only (no '+', spaces, or
                                  // dashes) in full international format.
                                  final sanitized = business.whatsappNumber!.replaceAll(RegExp(r'[^0-9]'), '');
                                  unawaited(launchUrlSafely(
                                    context,
                                    Uri.parse('https://wa.me/$sanitized'),
                                    mode: LaunchMode.externalApplication,
                                  ));
                                },
                                child: const Icon(Icons.chat_outlined),
                              ),
                            ),
                          ],
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.directions),
                              label: Text('business.directions'.tr(), overflow: TextOverflow.ellipsis),
                              onPressed: () {
                                recordAnalyticsEvent(business.id, AnalyticsEventType.websiteClick);
                                unawaited(launchUrlSafely(context, Uri.parse(
                                  'https://www.google.com/maps/search/?api=1&query=${business.latitude},${business.longitude}',
                                )));
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),

                      _SectionLabel('business.upcomingEvents'.tr()),
                      const SizedBox(height: 8),
                      eventsAsync.when(
                        data: (events) {
                          final related = events.where((e) => e.businessId == business.id).toList();
                          if (related.isEmpty) {
                            return Text(
                              'business.noUpcomingEvents'.tr(),
                              style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
                            );
                          }
                          return Column(children: [for (final e in related) EventListTile(event: e)]);
                        },
                        loading: () => const LoadingIndicator(size: 20),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),

                      _ReviewsSection(
                        businessId: business.id,
                        accent: accent,
                        // Same gating as the favorite button above — any
                        // signed-in non-guest account, not just business
                        // owners (there's no separate "customer" role).
                        canReview: canFavorite,
                        currentUserId: authState.user?.id,
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

/// Circular semi-transparent icon button used in the hero band's back/
/// favorite/share actions — the mockup's SliverAppBar buttons sit
/// directly on the red hero, so they need their own visible boundary
/// rather than relying on IconButton's default (which reads as
/// invisible against a solid-color background of the same brightness).
class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 19, color: Colors.white),
        ),
      ),
    );
  }
}

/// Small uppercase section label ("ORARI I PUNËS", "EVENTE TË
/// ARDHSHME", "VLERËSIMET") — same treatment as the plain category text
/// above, matching the mockup's understated section headers (no longer
/// large bold h3 titles).
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w700, letterSpacing: 0.5),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, required this.accent});
  final IconData icon;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}

/// Reviews list + "write/edit a review" entry point. A separate
/// ConsumerWidget (rather than inlined in the build method above) so it
/// only rebuilds off businessReviewsProvider — the parent's business
/// details fetch doesn't need to re-run every time a review is added.
class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection({
    required this.businessId,
    required this.accent,
    required this.canReview,
    required this.currentUserId,
  });

  final String businessId;
  final Color accent;
  final bool canReview;
  final String? currentUserId;

  Future<void> _openWriteSheet(BuildContext context, WidgetRef ref, {ReviewEntity? existing}) async {
    final bool? submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => WriteReviewSheet(businessId: businessId, existingReview: existing),
    );
    if (submitted == true) {
      // Refresh both this business's review list and its header rating
      // badge (rating/ratingCount are recalculated server-side on write).
      ref.invalidate(businessReviewsProvider(businessId));
      ref.invalidate(businessDetailsProvider(businessId));
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('reviews.deleteConfirmTitle'.tr()),
        content: Text('reviews.deleteConfirmBody'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('common.cancel'.tr())),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('common.delete'.tr(), style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final String? error = await ref.read(reviewControllerProvider.notifier).delete(businessId);
    if (!context.mounted) return;
    if (error != null) {
      AppToast.error(context, error);
      return;
    }
    ref.invalidate(businessReviewsProvider(businessId));
    ref.invalidate(businessDetailsProvider(businessId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(businessReviewsProvider(businessId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _SectionLabel('reviews.title'.tr())),
            if (canReview)
              reviewsAsync.maybeWhen(
                data: (reviews) {
                  final ReviewEntity? ownReview =
                      reviews.where((r) => r.userId == currentUserId).firstOrNull;
                  // Plain "Edit →"/"Write →" red text link rather than an
                  // icon+label button — matches the mockup's understated
                  // "Ndrysho →" treatment for this section's action.
                  return GestureDetector(
                    onTap: () => _openWriteSheet(context, ref, existing: ownReview),
                    child: Text(
                      '${ownReview != null ? 'reviews.editYourReview'.tr() : 'reviews.writeReview'.tr()} →',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
          ],
        ),
        const SizedBox(height: 8),
        reviewsAsync.when(
          loading: () => const LoadingIndicator(size: 20),
          error: (_, __) => Text('reviews.failedToLoad'.tr(), style: AppTextStyles.bodySmall),
          data: (reviews) {
            if (reviews.isEmpty) {
              return Text('reviews.noReviewsYet'.tr(), style: AppTextStyles.bodySmall);
            }
            return Column(
              children: [
                for (final review in reviews)
                  ReviewCard(
                    review: review,
                    isOwnReview: review.userId == currentUserId,
                    onEdit: () => _openWriteSheet(context, ref, existing: review),
                    onDelete: () => _confirmDelete(context, ref),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
