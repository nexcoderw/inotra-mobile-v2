import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";

class AppCachedImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final Widget Function(BuildContext context)? placeholderBuilder;
  final Widget Function(BuildContext context)? errorBuilder;
  final ColorFilter? colorFilter;
  final double? memCacheWidth;
  final double? memCacheHeight;
  final double? maxWidthDiskCache;
  final double? maxHeightDiskCache;
  final Alignment alignment;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholderBuilder,
    this.errorBuilder,
    this.colorFilter,
    this.memCacheWidth,
    this.memCacheHeight,
    this.maxWidthDiskCache,
    this.maxHeightDiskCache,
    this.alignment = Alignment.center,
  });

  bool get _hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final placeholder =
        placeholderBuilder?.call(context) ?? const SizedBox.shrink();
    final error = errorBuilder?.call(context) ?? placeholder;

    if (!_hasImage) {
      return error;
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!.trim(),
      fit: fit,
      alignment: alignment,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      memCacheWidth: memCacheWidth?.round(),
      memCacheHeight: memCacheHeight?.round(),
      maxWidthDiskCache: maxWidthDiskCache?.round(),
      maxHeightDiskCache: maxHeightDiskCache?.round(),
      imageBuilder: colorFilter == null
          ? null
          : (context, imageProvider) => ColorFiltered(
              colorFilter: colorFilter!,
              child: Image(
                image: imageProvider,
                fit: fit,
                alignment: alignment,
              ),
            ),
      placeholder: (_, __) => placeholder,
      errorWidget: (_, __, ___) => error,
    );
  }
}
