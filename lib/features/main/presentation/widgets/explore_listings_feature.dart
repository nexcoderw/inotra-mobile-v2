import "package:flutter/material.dart";

import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class ExploreListingsFeature extends StatelessWidget {
  const ExploreListingsFeature({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t(lang, "explore.listings_title"),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
              ),
            ),
            Text(
              t(lang, "explore.listings_hint"),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 12),
            itemCount: _listings.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final listing = _listings[i];
              return _ListingCard(
                listing: listing,
                isDark: isDark,
                scheme: scheme,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ListingCard extends StatelessWidget {
  final _Listing listing;
  final bool isDark;
  final ColorScheme scheme;

  const _ListingCard({
    required this.listing,
    required this.isDark,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: scheme.surface.withOpacity(isDark ? 0.55 : 0.75),
          border: Border.all(color: scheme.onSurface.withOpacity(0.06)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: listing.imageUrl != null
                  ? Ink.image(
                      image: NetworkImage(listing.imageUrl!),
                      fit: BoxFit.cover,
                      child: const SizedBox.expand(),
                    )
                  : Container(color: scheme.surfaceVariant),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 14, color: scheme.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "${listing.city}, ${listing.country}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurface.withOpacity(0.72),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.category_rounded,
                            size: 13, color: scheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          listing.category,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Listing {
  final String name;
  final String category;
  final String city;
  final String country;
  final String? imageUrl;

  const _Listing({
    required this.name,
    required this.category,
    required this.city,
    required this.country,
    required this.imageUrl,
  });
}

// Static seed content for now (limited to 4 listings).
const _listings = <_Listing>[
  _Listing(
    name: "Kigali Serena Hotel",
    category: "Accommodation",
    city: "Kigali",
    country: "Rwanda",
    imageUrl:
        "https://res.cloudinary.com/dllcdjply/image/upload/v1/media/places/2026/02/a9d852ad00f44daa938ae852fb741d4d_esriz1",
  ),
  _Listing(
    name: "Boho Restaurant",
    category: "Restaurant",
    city: "Kigali",
    country: "Rwanda",
    imageUrl:
        "https://res.cloudinary.com/dllcdjply/image/upload/v1/media/places/2026/02/695f789854eb4228ad7052da71960305_ktozfv",
  ),
  _Listing(
    name: "Akagera National Park",
    category: "Attraction",
    city: "Kageyo",
    country: "Rwanda",
    imageUrl:
        "https://res.cloudinary.com/dllcdjply/image/upload/v1/media/places/2026/02/2fc023b2e04f416794445ae61a13fe19_gmburl",
  ),
  _Listing(
    name: "Nyungwe National Park",
    category: "Attraction",
    city: "Luhonge",
    country: "Rwanda",
    imageUrl:
        "https://res.cloudinary.com/dllcdjply/image/upload/v1/media/places/2026/02/9fe4456f4e2b4349b0c452e8b698ea00_v7lp1p",
  ),
];
