import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "listing_details_shared.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class ListingOverviewTab extends StatelessWidget {
  final PlaceDetails place;
  const ListingOverviewTab({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ABOUT DESTINATION (like screenshot)
          Text(
            t(lang, "listings.overview_title"),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            place.description.isNotEmpty
                ? place.description
                : "—",
            style: TextStyle(
              height: 1.65,
              fontSize: 14.5,
              color: scheme.onSurface.withOpacity(0.72),
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 18),

          // SERVICES (if exists)
          if (place.services.isNotEmpty) ...[
            Text(
              t(lang, "listings.services"),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: place.services
                  .map(
                    (s) => ListingPill(
                      icon: HugeIcons.strokeRoundedSparkles,
                      label: s,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
          ],

          // HOURS (kept, but styled clean)
          Text(
            t(lang, "listings.hours"),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ListingHoursTable(hours: place.hours),
        ],
      ),
    );
  }
}