import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "listing_details_shared.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class ListingMapTab extends StatelessWidget {
  final PlaceDetails place;
  const ListingMapTab({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lang = currentLangSync();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(lang, "listings.address"),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ListingInfoRow(
            icon: HugeIcons.strokeRoundedMapsLocation02,
            label: place.address.isNotEmpty ? place.address : t(lang, "listings.no_data"),
          ),
          const SizedBox(height: 12),
          ListingInfoRow(
            icon: HugeIcons.strokeRoundedMapsLocation02,
            label: "${place.latitude?.toStringAsFixed(6) ?? '--'}, "
                "${place.longitude?.toStringAsFixed(6) ?? '--'}",
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: scheme.surfaceVariant.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.onSurface.withOpacity(0.08)),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                    icon: HugeIcons.strokeRoundedMapsLocation02,
                    size: 34,
                    color: scheme.onSurface.withOpacity(0.55),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(lang, "listings.map_placeholder"),
                    style: TextStyle(
                      color: scheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
