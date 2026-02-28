import "dart:convert";

import "package:flutter/material.dart";
import "package:http/http.dart" as http;

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/place_endpoints.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class ExploreListingsFeature extends StatefulWidget {
  const ExploreListingsFeature({super.key});

  @override
  State<ExploreListingsFeature> createState() => _ExploreListingsFeatureState();
}

class _ExploreListingsFeatureState extends State<ExploreListingsFeature> {
  bool _loading = true;
  String? _error;
  List<_Listing> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Api.url("${PlaceEndpoints.list}?page=1&page_size=4");
      final resp = await http.get(uri);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body);
        final results = (decoded is Map ? decoded["results"] : decoded) as List? ?? [];
        _items = results.whereType<Map>().map((e) => _Listing.fromJson(e)).toList();
      } else {
        _error = "Status ${resp.statusCode}";
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
          child: _loading
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 12),
                  itemBuilder: (_, __) => const _ListingSkeleton(),
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: 4,
                )
              : _error != null
                  ? _ErrorState(message: _error!, onRetry: _load)
                  : _items.isEmpty
                      ? _EmptyState(label: t(lang, "packages.empty"))
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(right: 12),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            final listing = _items[i];
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

class _ListingSkeleton extends StatelessWidget {
  const _ListingSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: scheme.surfaceVariant.withOpacity(0.55),
          border: Border.all(color: scheme.onSurface.withOpacity(0.06)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(color: scheme.surfaceVariant.withOpacity(0.6)),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: 120,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 90,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 20,
                    width: 80,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(999),
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceVariant.withOpacity(0.6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, color: scheme.error),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.error,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(t(currentLangSync(), "common.try_again"))),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
        textAlign: TextAlign.center,
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

  factory _Listing.fromJson(Map json) {
    return _Listing(
      name: (json["name"] ?? json["title"] ?? "").toString(),
      category: (json["category_name"] ?? json["category"] ?? "").toString(),
      city: (json["city"] ?? "").toString(),
      country: (json["country"] ?? "").toString(),
      imageUrl: json["first_image_url"] as String?,
    );
  }
}
