import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
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
        error: (_, __) => const ErrorStateWidget(message: 'Failed to load business'),
        data: (business) {
          if (business == null) {
            return const ErrorStateWidget(message: 'Business not found');
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
                    onPressed: () => Share.share('Check out ${business.name} on AlbMap!'),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: business.logoUrl != null
                      ? Image.network(business.logoUrl!, fit: BoxFit.cover)
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                            child: Text(business.category, style: AppTextStyles.bodySmall.copyWith(color: accent, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 10),
                          if (business.rating != null) ...[
                            const Icon(Icons.star_rounded, size: 18, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text(business.rating!.toStringAsFixed(1), style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),

                      Text('About', style: AppTextStyles.h3),
                      const SizedBox(height: 8),
                      Text(business.description, style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 20),

                      _InfoCard(
                        accent: accent,
                        children: [
                          _InfoRow(icon: Icons.location_on_outlined, text: business.address, accent: accent),
                          if (business.phone != null)
                            _InfoRow(icon: Icons.phone_outlined, text: business.phone!, accent: accent),
                          if (business.distanceKm != null)
                            _InfoRow(icon: Icons.directions_walk, text: '${business.distanceKm!.toStringAsFixed(1)} km away', accent: accent),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (business.openingHours.isNotEmpty) ...[
                        Text('Opening hours', style: AppTextStyles.h3),
                        const SizedBox(height: 8),
                        _InfoCard(
                          accent: accent,
                          children: [
                            for (final entry in business.openingHours.entries)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(entry.key, style: AppTextStyles.bodyMedium),
                                    Text(entry.value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.call_outlined),
                              label: const Text('Call'),
                              onPressed: business.phone == null
                                  ? null
                                  : () {
                                      recordAnalyticsEvent(business.id, AnalyticsEventType.callClick);
                                      launchUrl(Uri.parse('tel:${business.phone}'));
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: accent),
                              icon: const Icon(Icons.directions),
                              label: const Text('Directions'),
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

                      Text('Upcoming events', style: AppTextStyles.h3),
                      const SizedBox(height: 8),
                      eventsAsync.when(
                        data: (events) {
                          final related = events.where((e) => e.businessId == business.id).toList();
                          if (related.isEmpty) {
                            return const Text('No upcoming events', style: AppTextStyles.bodySmall);
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
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}
