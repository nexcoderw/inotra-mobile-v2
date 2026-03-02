import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class ListingReviewsTab extends StatelessWidget {
  const ListingReviewsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedMessage02,
            size: 36,
            color: scheme.onSurface.withOpacity(0.35),
          ),
          const SizedBox(height: 10),
          Text(
            t(lang, "listings.reviews_empty"),
            style: TextStyle(
              color: scheme.onSurface.withOpacity(0.65),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
