import "package:flutter/material.dart";

import "../../../../main/presentation/widgets/page_header.dart";
import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";

class MyListingEditPage extends StatelessWidget {
  final String? listingId;
  final String? title;

  const MyListingEditPage({super.key, this.listingId, this.title});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    final listingTitle = title?.trim().isNotEmpty == true
        ? title!.trim()
        : t(lang, "my_listings.fallback_title");

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          PageHeader(title: t(lang, "my_listings.edit_listing")),
          _WorkspaceCard(
            title: t(lang, "my_listings.edit_listing"),
            subtitle: listingTitle,
            detail: listingId,
            scheme: scheme,
            icon: Icons.edit_outlined,
          ),
        ],
      ),
    );
  }
}

class _WorkspaceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? detail;
  final ColorScheme scheme;
  final IconData icon;

  const _WorkspaceCard({
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.scheme,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: scheme.secondaryContainer.withValues(alpha: 0.22),
        border: Border.all(color: scheme.secondary.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: scheme.secondary.withValues(alpha: 0.10),
            ),
            child: Icon(icon, color: scheme.secondary),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface.withValues(alpha: 0.82),
            ),
          ),
          if (detail != null && detail!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              detail!,
              style: TextStyle(
                fontSize: 12.5,
                color: scheme.onSurface.withValues(alpha: 0.52),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            t(currentLangSync(), "common.coming_soon"),
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: scheme.onSurface.withValues(alpha: 0.68),
            ),
          ),
        ],
      ),
    );
  }
}
