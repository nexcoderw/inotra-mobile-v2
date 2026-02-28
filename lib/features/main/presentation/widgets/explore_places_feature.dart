import "package:flutter/material.dart";

import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class ExplorePlacesFeature extends StatelessWidget {
  const ExplorePlacesFeature({super.key});

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
              t(lang, "explore.places_title"),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
              ),
            ),
            Text(
              t(lang, "explore.places_hint"),
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
            itemCount: _places.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final p = _places[i];
              return _PlaceCard(
                place: p,
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

class _PlaceCard extends StatelessWidget {
  final _Place place;
  final bool isDark;
  final ColorScheme scheme;

  const _PlaceCard({
    required this.place,
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
              child: place.imageUrl != null
                  ? Ink.image(
                      image: NetworkImage(place.imageUrl!),
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
                    place.name,
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
                          "${place.city}, ${place.country}",
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
                          place.category,
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

class _Place {
  final String name;
  final String category;
  final String city;
  final String country;
  final String? imageUrl;

  const _Place({
    required this.name,
    required this.category,
    required this.city,
    required this.country,
    required this.imageUrl,
  });
}

// Static seed content for now (API wiring can replace this later).
const _places = <_Place>[
  _Place(
    name: "Kigali Serena Hotel",
    category: "Accomodation",
    city: "Kigali",
    country: "Rwanda",
    imageUrl:
        "https://res.cloudinary.com/dllcdjply/image/upload/v1/media/places/2026/02/a9d852ad00f44daa938ae852fb741d4d_esriz1",
  ),
  _Place(
    name: "Boho Restaurant",
    category: "Restaurant",
    city: "Kigali",
    country: "Rwanda",
    imageUrl:
        "https://res.cloudinary.com/dllcdjply/image/upload/v1/media/places/2026/02/695f789854eb4228ad7052da71960305_ktozfv",
  ),
  _Place(
    name: "Akagera National Park",
    category: "Attractions",
    city: "Kageyo",
    country: "Rwanda",
    imageUrl:
        "https://res.cloudinary.com/dllcdjply/image/upload/v1/media/places/2026/02/2fc023b2e04f416794445ae61a13fe19_gmburl",
  ),
  _Place(
    name: "Nyungwe National Park",
    category: "Attractions",
    city: "Luhonge",
    country: "Rwanda",
    imageUrl:
        "https://res.cloudinary.com/dllcdjply/image/upload/v1/media/places/2026/02/9fe4456f4e2b4349b0c452e8b698ea00_v7lp1p",
  ),
  _Place(
    name: "Kigali Genocide Memorial",
    category: "Attractions",
    city: "Kigali",
    country: "Rwanda",
    imageUrl:
        "https://res.cloudinary.com/dllcdjply/image/upload/v1/media/places/2026/02/f5efe096689a4c34bee4bccb2765edbe_tbullb",
  ),
];
