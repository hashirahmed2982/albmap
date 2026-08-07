import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/review_entity.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({
    required this.review,
    super.key,
    this.isOwnReview = false,
    this.onEdit,
    this.onDelete,
  });

  final ReviewEntity review;
  final bool isOwnReview;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, yyyy', context.locale.languageCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  (review.userName?.isNotEmpty ?? false) ? review.userName![0].toUpperCase() : '?',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOwnReview
                          ? 'reviews.you'.tr()
                          : (review.userName?.isNotEmpty ?? false)
                              ? review.userName!
                              : 'reviews.anonymous'.tr(),
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 14,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(dateFmt.format(review.createdAt), style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ),
              if (isOwnReview)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'edit', child: Text('common.edit'.tr())),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('common.delete'.tr(), style: const TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
            ],
          ),
          if (review.comment != null && review.comment!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review.comment!, style: AppTextStyles.bodyMedium),
          ],
        ],
      ),
    );
  }
}
