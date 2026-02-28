import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
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

    final w = MediaQuery.sizeOf(context).width;
    final isTablet = w >= 700;

    final hPad = isTablet ? 24.0 : 16.0;
    final height = isTablet ? 260.0 : 224.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _GlassPill(
                child: Text(
                  t(lang, "explore.listings_title"),
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              _GlassLink(
                label: t(lang, "explore.listings_hint"),
                onTap: () {
                  // You can wire this to your listings page route later.
                  // Navigator.pushNamed(context, AppRoutes.listings);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: height,
          child: _loading
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  itemBuilder: (_, __) => const _ListingSkeleton(),
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: 4,
                )
              : _error != null
                  ? Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: _ErrorState(message: _error!, onRetry: _load),
                    )
                  : _items.isEmpty
                      ? Padding(
                          padding: EdgeInsets.symmetric(horizontal: hPad),
                          child: _EmptyState(label: t(lang, "packages.empty")),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: hPad),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            final listing = _items[i];
                            return _ListingCard(listing: listing, isTablet: isTablet);
                          },
                        ),
        ),
      ],
    );
  }
}

class _ListingCard extends StatefulWidget {
  final _Listing listing;
  final bool isTablet;

  const _ListingCard({
    required this.listing,
    required this.isTablet,
  });

  @override
  State<_ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<_ListingCard> {
  bool _pressed = false;

  void _set(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final cardW = widget.isTablet ? 260.0 : 200.0;
    final radius = BorderRadius.circular(widget.isTablet ? 26 : 22);

    final title = widget.listing.name.trim().isEmpty ? "Listing" : widget.listing.name.trim();

    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: () {
        // Wire this to listing details when you’re ready.
        // Navigator.pushNamed(context, AppRoutes.listingDetails, arguments: widget.listing.id);
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.992 : 1.0,
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              // Image background
              Positioned.fill(
                child: widget.listing.imageUrl != null
                    ? Image.network(
                        widget.listing.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: scheme.surfaceVariant.withOpacity(0.7),
                        ),
                        loadingBuilder: (context, child, evt) {
                          if (evt == null) return child;
                          return Container(color: scheme.surfaceVariant.withOpacity(0.7));
                        },
                      )
                    : Container(color: scheme.surfaceVariant.withOpacity(0.7)),
              ),

              // Vignette gradient for legibility
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.10),
                        Colors.black.withOpacity(0.52),
                      ],
                    ),
                  ),
                ),
              ),

              // Glass border + glow
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(
                      color: Colors.white.withOpacity(isDark ? 0.12 : 0.18),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.30 : 0.14),
                        blurRadius: 26,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom glass content
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _GlassFooter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: widget.isTablet ? 14.5 : 13.5,
                          color: Colors.white,
                          letterSpacing: -0.2,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _RatingPill(
                          rating: widget.listing.avgRating,
                          reviews: widget.listing.reviewsCount,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Optional "save" affordance (user friendly)
              Positioned(
                top: 10,
                right: 10,
                child: _RoundGlassButton(
                  icon: HugeIcons.strokeRoundedBookmark,
                  onTap: () {
                    // placeholder save action
                  },
                ),
              ),

              // Subtle top highlight
              Positioned.fill(
                child: IgnorePointer(
                  child: _SpecularHighlight(radius: radius),
                ),
              ),

              // Fixed width to keep layout consistent in horizontal list
              SizedBox(width: cardW),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassFooter extends StatelessWidget {
  final Widget child;
  const _GlassFooter({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isDark ? 0.10 : 0.14),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(isDark ? 0.14 : 0.18)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withOpacity(0.22),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.white.withOpacity(0.92),
        ),
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  final double rating;
  final int reviews;

  const _RatingPill({
    required this.rating,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final displayRating = rating <= 0 ? "0.0" : rating.toStringAsFixed(1);
    final displayReviews = reviews < 0 ? 0 : reviews;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedStar,
            size: 14,
            strokeWidth: 2,
            color: Colors.amber.shade300,
          ),
          const SizedBox(width: 6),
          Text(
            displayRating,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            "(${displayReviews})",
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.80),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundGlassButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundGlassButton({
    required this.icon,
    required this.onTap,
  });

  @override
  State<_RoundGlassButton> createState() => _RoundGlassButtonState();
}

class _RoundGlassButtonState extends State<_RoundGlassButton> {
  bool _pressed = false;
  void _set(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.96 : 1,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isDark ? 0.10 : 0.16),
                border: Border.all(color: Colors.white.withOpacity(isDark ? 0.14 : 0.18)),
              ),
              child: Icon(
                widget.icon,
                size: 20,
                color: scheme.onSurface.withOpacity(isDark ? 0.92 : 0.86),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecularHighlight extends StatelessWidget {
  final BorderRadius radius;
  const _SpecularHighlight({required this.radius});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: [
          Positioned(
            top: -60,
            left: -40,
            child: Transform.rotate(
              angle: -0.25,
              child: Container(
                width: 220,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(80),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.14),
                      Colors.white.withOpacity(0.0),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingSkeleton extends StatelessWidget {
  const _ListingSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final w = MediaQuery.sizeOf(context).width;
    final isTablet = w >= 700;

    final radius = BorderRadius.circular(isTablet ? 26 : 22);
    final cardW = isTablet ? 260.0 : 200.0;

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: cardW,
        decoration: BoxDecoration(
          color: scheme.surfaceVariant.withOpacity(0.55),
          borderRadius: radius,
          border: Border.all(color: scheme.onSurface.withOpacity(0.06)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 84,
                  color: Colors.white.withOpacity(0.10),
                ),
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

    return _GlassPanel(
      child: SizedBox(
        width: 220,
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
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: Text(t(currentLangSync(), "common.try_again")),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: SizedBox(
        width: 220,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surface.withOpacity(0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.onSurface.withOpacity(0.10)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final Widget child;
  const _GlassPill({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: scheme.surface.withOpacity(0.55),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: scheme.onSurface.withOpacity(0.10)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GlassLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: scheme.primary,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}

class _Listing {
  final String name;
  final String city;
  final String country;
  final String? imageUrl;
  final double avgRating;
  final int reviewsCount;

  const _Listing({
    required this.name,
    required this.city,
    required this.country,
    required this.imageUrl,
    required this.avgRating,
    required this.reviewsCount,
  });

  factory _Listing.fromJson(Map json) {
    final avg = (json["avg_rating"] as num?)?.toDouble() ?? 0.0;
    final reviews = (json["reviews_count"] as num?)?.toInt() ?? 0;
    return _Listing(
      name: (json["name"] ?? json["title"] ?? "").toString(),
      city: (json["city"] ?? "").toString(),
      country: (json["country"] ?? "").toString(),
      imageUrl: json["first_image_url"] as String?,
      avgRating: avg,
      reviewsCount: reviews,
    );
  }
}
