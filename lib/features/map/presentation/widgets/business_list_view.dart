import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../categories/domain/category_translations.dart';
import '../../domain/entities/business_entity.dart';

IconData categoryIcon(String category) {
  switch (category) {
    case 'Restaurants':
      return Icons.restaurant_outlined;
    case 'Cafes':
      return Icons.coffee_outlined;
    case 'Shops':
      return Icons.storefront_outlined;
    case 'Services':
      return Icons.build_outlined;
    case 'Health':
      return Icons.fitness_center_outlined;
    case 'Entertainment':
      return Icons.local_movies_outlined;
    default:
      return Icons.category_outlined;
  }
}

Color categoryColor(String category) {
  switch (category) {
    case 'Restaurants':
      return const Color(0xFFFF7043);
    case 'Cafes':
      return const Color(0xFF8D6E63);
    case 'Shops':
      return const Color(0xFF66BB6A);
    case 'Services':
      return const Color(0xFF42A5F5);
    case 'Health':
      return const Color(0xFFEC407A);
    case 'Entertainment':
      return const Color(0xFFAB47BC);
    default:
      return AppColors.primary;
  }
}

/// Scrollable, pull-to-refresh business list — the shared "browse
/// businesses" visual language used by Discover's List view and Favorites.
class BusinessListView extends StatelessWidget {
  const BusinessListView({
    required this.businesses,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onRefresh,
    super.key,
  });

  final List<BusinessEntity> businesses;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (isLoading && businesses.isEmpty) {
      return const BusinessListSkeleton();
    }
    if (errorMessage != null && businesses.isEmpty) {
      return ErrorStateWidget(message: errorMessage!, onRetry: onRetry);
    }
    if (businesses.isEmpty) {
      return EmptyStateWidget(
        message: 'discover.noBusinessesNearby'.tr(),
        icon: Icons.storefront_outlined,
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: businesses.length,
        itemBuilder: (context, i) => BusinessCard(business: businesses[i]),
      ),
    );
  }
}

/// Public so Favorites and other screens can reuse the exact same card look.
class BusinessCard extends StatelessWidget {
  const BusinessCard({required this.business, this.trailing, super.key});
  final BusinessEntity business;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final Color accent = categoryColor(business.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(AppRoutes.businessDetailsPath(business.id)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: business.logoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: AppNetworkImage(
                            url: AppConstants.resolveMediaUrl(business.logoUrl)!,
                            width: 56,
                            height: 56,
                            backgroundColor: accent.withValues(alpha: 0.12),
                          ),
                        )
                      : Icon(categoryIcon(business.category), color: accent, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(business.name, style: AppTextStyles.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          localizedCategoryName(context, business.category),
                          style: AppTextStyles.caption.copyWith(color: accent, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (business.rating != null) ...[
                            const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                            const SizedBox(width: 2),
                            Text(business.rating!.toStringAsFixed(1), style: AppTextStyles.bodySmall),
                            const SizedBox(width: 12),
                          ],
                          if (business.distanceKm != null) ...[
                            const Icon(Icons.near_me_outlined, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 2),
                            Text('common.km_away'.tr(args: [business.distanceKm!.toStringAsFixed(1)]), style: AppTextStyles.bodySmall),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
