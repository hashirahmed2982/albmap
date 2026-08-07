import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/review_entity.dart';
import '../providers/review_providers.dart';

/// Star-rating + optional comment, used both to write a first review and
/// to edit an existing one (POST is create-or-update server-side — see
/// review_remote_datasource.dart — so this sheet doesn't need to know
/// which case it's in beyond how it pre-fills).
class WriteReviewSheet extends ConsumerStatefulWidget {
  const WriteReviewSheet({required this.businessId, super.key, this.existingReview});

  final String businessId;
  final ReviewEntity? existingReview;

  @override
  ConsumerState<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends ConsumerState<WriteReviewSheet> {
  late int _rating = widget.existingReview?.rating ?? 0;
  late final TextEditingController _commentController =
      TextEditingController(text: widget.existingReview?.comment ?? '');
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      AppToast.warning(context, 'reviews.selectRatingError'.tr());
      return;
    }
    setState(() => _isLoading = true);
    final String? error = await ref.read(reviewControllerProvider.notifier).submit(
          businessId: widget.businessId,
          rating: _rating,
          comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error != null) {
      AppToast.error(context, error);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.existingReview != null;
    return AppBottomSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isEditing ? 'reviews.editYourReview'.tr() : 'reviews.writeReview'.tr(),
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final int starValue = i + 1;
              return IconButton(
                iconSize: 36,
                onPressed: _isLoading ? null : () => setState(() => _rating = starValue),
                icon: Icon(
                  starValue <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: AppColors.warning,
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _commentController,
            enabled: !_isLoading,
            maxLines: 4,
            maxLength: 1000,
            decoration: InputDecoration(
              labelText: 'reviews.commentLabel'.tr(),
              hintText: 'reviews.commentHint'.tr(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            label: isEditing ? 'reviews.updateReview'.tr() : 'reviews.submitReview'.tr(),
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
