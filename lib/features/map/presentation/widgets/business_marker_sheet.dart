import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../categories/domain/category_translations.dart';
import '../../domain/business_open_status.dart';
import '../../domain/entities/business_entity.dart';

/// Quick-info card shown when a map marker is tapped.
class BusinessMarkerSheet extends StatelessWidget {
  const BusinessMarkerSheet({required this.business, super.key});
  final BusinessEntity business;

  @override
  Widget build(BuildContext context) {
    // Wrapped in `Wrap` so the sheet always sizes tightly to its content's
    // intrinsic height. Without this, showModalBottomSheet's default
    // constraints (up to ~56% of screen height) can stretch a bare
    // Container to fill that space instead of hugging the Row's natural
    // height — which is what was pushing the icon/chevron down to the
    // bottom of an oversized, mostly-empty sheet.
    return Wrap(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: business.logoUrl != null
                      ? AppNetworkImage(
                          url: AppConstants.resolveMediaUrl(business.logoUrl)!,
                          width: 64,
                          height: 64,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        )
                      : Container(
                          width: 64, height: 64, color: AppColors.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.storefront, color: AppColors.primary),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(business.name, style: AppTextStyles.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(localizedCategoryName(context, business.category), style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                          OpenStatusBadge(openingHours: business.openingHours, dense: true),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (business.rating != null) ...[
                            const Icon(Icons.star, size: 14, color: AppColors.warning),
                            const SizedBox(width: 2),
                            Text(business.rating!.toStringAsFixed(1), style: AppTextStyles.bodySmall),
                            const SizedBox(width: 10),
                          ],
                          if (business.distanceKm != null)
                            Flexible(
                              child: Text(
                                'common.km_away'.tr(args: [business.distanceKm!.toStringAsFixed(1)]),
                                style: AppTextStyles.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 18),
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(AppRoutes.businessDetailsPath(business.id));
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
