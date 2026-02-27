import "package:flutter/material.dart";

import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";
import "../../widgets/main_scaffold.dart";

class ListingReviewsPage extends StatelessWidget {
  const ListingReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return MainScaffold(
      title: t(lang, "nav.listing_reviews"),
      child: Center(
        child: Text(
          t(lang, "common.coming_soon"),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface.withOpacity(0.8),
          ),
        ),
      ),
    );
  }
}
