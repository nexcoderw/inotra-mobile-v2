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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (place.description.isNotEmpty) ...[
            Text(
              t(lang, "listings.overview_title"),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              place.description,
              style: TextStyle(
                height: 1.5,
                color: scheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (place.services.isNotEmpty) ...[
            Text(
              t(lang, "listings.services"),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: place.services
                  .map((s) => ListingPill(
                        icon: HugeIcons.strokeRoundedSparkles,
                        label: s,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            t(lang, "listings.hours"),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ListingHoursTable(hours: place.hours),
        ],
      ),
    );
  }
}
