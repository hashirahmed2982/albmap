import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Every remote image in the app (business logos, event photos, avatars)
/// used a bare `Image.network`, despite `cached_network_image` already
/// being a pubspec dependency nothing referenced. Bare `Image.network`
/// re-fetches on every rebuild/scroll (no disk cache), and shows Flutter's
/// default broken-image icon — full bleed, wrong color, no rounding — the
/// instant a URL 404s or the device is briefly offline. This wraps
/// `CachedNetworkImage` with a themed placeholder (a soft-tinted box, so
/// the loading state matches the eventual image's footprint) and a
/// themed error state (a muted broken-image icon instead of the jarring
/// default), and turns on disk caching everywhere by default.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    required this.url,
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.backgroundColor,
    this.errorIconSize,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? backgroundColor;
  final double? errorIconSize;

  @override
  Widget build(BuildContext context) {
    final Color bg = backgroundColor ?? AppColors.inputFill;
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (context, _) => Container(width: width, height: height, color: bg),
      errorWidget: (context, _, __) => Container(
        width: width,
        height: height,
        color: bg,
        alignment: Alignment.center,
        child: Icon(
          Icons.image_not_supported_outlined,
          size: errorIconSize ?? ((width ?? height ?? 48) * 0.4).clamp(16, 32),
          color: AppColors.textSecondary.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
