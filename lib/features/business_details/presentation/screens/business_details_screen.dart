import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/opening_hours_editor.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../categories/domain/category_translations.dart';
import '../../../dashboard/domain/entities/business_analytics_entity.dart';
import '../../../dashboard/presentation/providers/analytics_providers.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../events/presentation/screens/event_list_tile.dart';
import '../../../favorites/presentation/providers/favorites_providers.dart';
import '../../../map/presentation/providers/business_providers.dart';
import '../../../map/presentation/widgets/business_list_view.dart';

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

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 220,
                backgroundColor: accent,
                actions: [
                  if (canFavorite)
                    IconButton(
                      icon: const Icon(Icons.favorite_border, color: Colors.white),
                      onPressed: () => ref
                          .read(favoriteToggleControllerProvider.notifier)
                          .toggleBusiness(business),
                    ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () => Share.share('business.shareText'.tr(args: [business.name])),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: business.logoUrl != null
                      ? Image.network(AppConstants.resolveMediaUrl(business.logoUrl)!, fit: BoxFit.cover)
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [accent, accent.withValues(alpha: 0.7)],
                            ),
                          ),
                          child: Center(
                            child: Icon(categoryIcon(business.category), size: 72, color: Colors.white.withValues(alpha: 0.85)),
                          ),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              localizedCategoryName(context, business.category),
                              style: AppTextStyles.bodySmall.copyWith(color: accent, fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (business.rating != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 18, color: AppColors.warning),
                                const SizedBox(width: 4),
                                Text(business.rating!.toStringAsFixed(1), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Text('business.about'.tr(), style: AppTextStyles.h3),
                      const SizedBox(height: 8),
                      Text(business.description, style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 20),

                      _InfoCard(
                        accent: accent,
                        children: [
                          _InfoRow(icon: Icons.location_on_outlined, text: business.formattedAddress, accent: accent),
                          if (business.phone != null)
                            _InfoRow(icon: Icons.phone_outlined, text: business.phone!, accent: accent),
                          if (business.distanceKm != null)
                            _InfoRow(
                              icon: Icons.directions_walk,
                              text: 'business.kmAway'.tr(args: [business.distanceKm!.toStringAsFixed(1)]),
                              accent: accent,
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Always shown (not just when non-empty) — a business
                      // with no hours entered still gets an honest "Hours
                      // not provided" row rather than the section silently
                      // vanishing, which previously made it look like the
                      // screen simply had no hours feature at all.
                      Text('business.openingHours'.tr(), style: AppTextStyles.h3),
                      const SizedBox(height: 8),
                      _InfoCard(
                        accent: accent,
                        children: [OpeningHoursDisplay(hours: business.openingHours)],
                      ),
                      const SizedBox(height: 20),

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
                                      launchUrl(Uri.parse('tel:${business.phone}'));
                                    },
                            ),
                          ),
                          if (business.whatsappNumber != null) ...[
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  side: const BorderSide(color: Color(0xFF25D366)), // WhatsApp brand green
                                ),
                                onPressed: () {
                                  recordAnalyticsEvent(business.id, AnalyticsEventType.callClick);
                                  // wa.me requires digits only (no '+', spaces, or
                                  // dashes) in full international format.
                                  final sanitized = business.whatsappNumber!.replaceAll(RegExp(r'[^0-9]'), '');
                                  launchUrl(
                                    Uri.parse('https://wa.me/$sanitized'),
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                                child: const Icon(Icons.chat_outlined, color: Color(0xFF25D366)),
                              ),
                            ),
                          ],
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: accent),
                              icon: const Icon(Icons.directions),
                              label: Text('business.directions'.tr(), overflow: TextOverflow.ellipsis),
                              onPressed: () {
                                recordAnalyticsEvent(business.id, AnalyticsEventType.websiteClick);
                                launchUrl(Uri.parse(
                                  'https://www.google.com/maps/search/?api=1&query=${business.latitude},${business.longitude}',
                                ));
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Text('business.upcomingEvents'.tr(), style: AppTextStyles.h3),
                      const SizedBox(height: 8),
                      eventsAsync.when(
                        data: (events) {
                          final related = events.where((e) => e.businessId == business.id).toList();
                          if (related.isEmpty) {
                            return Text('business.noUpcomingEvents'.tr(), style: AppTextStyles.bodySmall);
                          }
                          return Column(children: [for (final e in related) EventListTile(event: e)]);
                        },
                        loading: () => const LoadingIndicator(size: 20),
                        error: (_, __) => const SizedBox.shrink(),
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children, required this.accent});
  final List<Widget> children;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
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
