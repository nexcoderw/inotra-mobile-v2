import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/foundation.dart";
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

    final trimmedUrl = imageUrl!.trim();

    if (kIsWeb) {
      final image = Image.network(
        trimmedUrl,
        fit: fit,
        alignment: alignment,
        cacheWidth: memCacheWidth?.round(),
        cacheHeight: memCacheHeight?.round(),
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder;
        },
        errorBuilder: (context, errorObject, stackTrace) => error,
      );

      if (colorFilter == null) return image;

      return ColorFiltered(colorFilter: colorFilter!, child: image);
    }

    return CachedNetworkImage(
      imageUrl: trimmedUrl,
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
      placeholder: (context, url) => placeholder,
      errorWidget: (context, url, errorObject) => error,
    );
  }
}
