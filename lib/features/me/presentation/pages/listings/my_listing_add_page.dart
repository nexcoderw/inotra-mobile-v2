import "package:flutter/material.dart";

import "../../../../main/presentation/widgets/page_header.dart";
import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";

class MyListingAddPage extends StatelessWidget {
  const MyListingAddPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          PageHeader(title: t(lang, "my_listings.add_listing")),
          _WorkspaceCard(
            title: t(lang, "my_listings.add_listing"),
            subtitle: t(lang, "common.coming_soon"),
            scheme: scheme,
            icon: Icons.add_business_rounded,
          ),
        ],
      ),
    );
  }
}

class _WorkspaceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final ColorScheme scheme;
  final IconData icon;

  const _WorkspaceCard({
    required this.title,
    required this.subtitle,
    required this.scheme,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: scheme.primaryContainer.withValues(alpha: 0.22),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: scheme.primary.withValues(alpha: 0.10),
            ),
            child: Icon(icon, color: scheme.primary),
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
          const SizedBox(height: 12),
          Text(
            subtitle,
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
