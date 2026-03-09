import "package:flutter/material.dart";
import "../../../../../../i18n/lang.dart";
import "../../../../../../i18n/translations.dart";

class PackageGalleryTab extends StatelessWidget {
  final List<String> images;
  const PackageGalleryTab({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lang = currentLangSync();

    if (images.isEmpty) {
      return Center(
        child: Text(
          t(lang, "common.empty"),
          style: TextStyle(
            color: scheme.onSurface.withOpacity(0.65),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final url = images[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: scheme.surfaceVariant,
              child: Icon(Icons.image, color: scheme.onSurface.withOpacity(0.5)),
            ),
          ),
        );
      },
    );
  }
}
