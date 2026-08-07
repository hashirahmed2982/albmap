import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';

/// Shared shimmer wrapper — `shimmer` has been a pubspec dependency (and
/// AppColors.shimmerBase/shimmerHighlight already existed) since day one,
/// but nothing in the app actually used it: every loading state was a
/// bare centered spinner, including full-screen list loads where a
/// skeleton that previews the eventual layout reads as noticeably more
/// "finished" than a spinner floating in empty space.
class AppShimmer extends StatelessWidget {
  const AppShimmer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: child,
    );
  }
}

/// A plain rounded block — the building unit every skeleton below is
/// made of.
class ShimmerBlock extends StatelessWidget {
  const ShimmerBlock({
    required this.width,
    required this.height,
    this.borderRadius = 8,
    super.key,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        // Shimmer.fromColors recolors its descendants based on opacity,
        // so the fill color itself just needs to be opaque — white reads
        // as fully "on" against the base/highlight sweep.
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton matching [BusinessCard]'s layout — logo square, title line,
/// category-pill line, meta line — so the loading state previews the
/// shape of what's about to appear instead of a generic spinner.
class BusinessCardSkeleton extends StatelessWidget {
  const BusinessCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          ShimmerBlock(width: 56, height: 56, borderRadius: 14),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBlock(width: 140, height: 16),
                SizedBox(height: 8),
                ShimmerBlock(width: 90, height: 18, borderRadius: 8),
                SizedBox(height: 8),
                ShimmerBlock(width: 110, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A scrollable column of [BusinessCardSkeleton]s, wrapped in one
/// [AppShimmer] so the whole list sweeps in sync rather than each card
/// animating independently.
class BusinessListSkeleton extends StatelessWidget {
  const BusinessListSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, i) => const BusinessCardSkeleton(),
      ),
    );
  }
}
