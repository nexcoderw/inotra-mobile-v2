import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "listing_details_shared.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class ListingTransportTab extends StatelessWidget {
  final PlaceDetails place;
  const ListingTransportTab({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(lang, "listings.transport_title"),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ListingInfoRow(
            icon: HugeIcons.strokeRoundedCall,
            label: place.phone.isNotEmpty ? place.phone : t(lang, "listings.no_data"),
          ),
          const SizedBox(height: 10),
          ListingInfoRow(
            icon: HugeIcons.strokeRoundedMessage02,
            label: place.whatsapp.isNotEmpty ? place.whatsapp : t(lang, "listings.no_data"),
          ),
          const SizedBox(height: 10),
          ListingInfoRow(
            icon: HugeIcons.strokeRoundedMail02,
            label: place.email.isNotEmpty ? place.email : t(lang, "listings.no_data"),
          ),
          const SizedBox(height: 10),
          ListingInfoRow(
            icon: HugeIcons.strokeRoundedGlobe02,
            label: place.website.isNotEmpty ? place.website : t(lang, "listings.no_data"),
          ),
        ],
      ),
    );
  }
}
