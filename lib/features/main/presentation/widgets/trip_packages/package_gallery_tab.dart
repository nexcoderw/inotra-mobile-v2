import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../../../core/widgets/app_cached_image.dart";
import "../../../../../../i18n/lang.dart";
import "../../../../../../i18n/translations.dart";
import "package_models.dart";

class PackageGalleryTab extends StatelessWidget {
  final List<PackageImageItem> images;

  const PackageGalleryTab({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    if (images.isEmpty) {
      return _EmptyState(
        icon: HugeIcons.strokeRoundedImage01,
        message: t(lang, "listings.no_data"),
        scheme: scheme,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: images.length,
      itemBuilder: (_, i) {
        final img = images[i];
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppCachedImage(
                imageUrl: img.url,
                fit: BoxFit.cover,
                memCacheWidth: 900,
                memCacheHeight: 1100,
                maxWidthDiskCache: 1200,
                maxHeightDiskCache: 1400,
                errorBuilder: (_) => _ImageFallback(scheme: scheme),
                placeholderBuilder: (_) => _ImageFallback(scheme: scheme),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(14),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.62),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              if (img.caption.isNotEmpty)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 7,
                  child: Text(
                    img.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (img.isFeatured)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade600,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedStar,
                          size: 11,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          t(lang, "trips.featured"),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final ColorScheme scheme;
  const _ImageFallback({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedImageNotFound01,
          size: 34,
          color: scheme.onSurface.withValues(alpha: 0.30),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final dynamic icon;
  final String message;
  final ColorScheme scheme;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: icon,
            size: 34,
            color: scheme.onSurface.withValues(alpha: 0.30),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.50),
            ),
          ),
        ],
      ),
    );
  }
}
