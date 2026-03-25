import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:toastification/toastification.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../core/repositories/public_discovery_repository.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

/// Premium Explore Listings (NO sliding gestures / NO swipe-to-reveal).
/// - Keeps horizontal browsing, but removes any "sliding logic" effects.
/// - Uses polished glassmorphism cards + responsive sizes.
/// - Favorite persistence (7 days) remains.
class ExploreListingsFeature extends StatefulWidget {
  const ExploreListingsFeature({super.key});

  @override
  State<ExploreListingsFeature> createState() => _ExploreListingsFeatureState();
}

class _ExploreListingsFeatureState extends State<ExploreListingsFeature> {
  bool _loading = true;
  String? _error;
  List<_Listing> _items = const [];
  Set<String> _favoriteIds = {};

  static const _favKey = "explore_listing_favs";
  static const _expiryMs = 7 * 24 * 60 * 60 * 1000; // 7 days

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadFavorites();
    await _load();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_favKey);
    if (raw == null) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final kept = decoded.whereType<Map>().where((m) {
          final ts = m["ts"] as int? ?? 0;
          return now - ts < _expiryMs;
        }).toList();

        _favoriteIds = kept.map((m) => (m["id"] ?? "").toString()).toSet();
        await prefs.setString(_favKey, jsonEncode(kept));
        if (mounted) setState(() {});
      }
    } catch (_) {
      // ignore invalid cache
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final payload = _favoriteIds
        .map((id) => {"id": id, "ts": now})
        .toList(growable: false);
    await prefs.setString(_favKey, jsonEncode(payload));
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final resp = await PublicDiscoveryRepository.instance
          .fetchExploreListings(
            page: 1,
            pageSize: 4,
            forceRefresh: forceRefresh,
          );

      if (resp.isSuccess) {
        final decoded = resp.decodeJson();
        final results =
            (decoded is Map ? decoded["results"] : decoded) as List? ?? [];
        _items = results
            .whereType<Map>()
            .map((e) => _Listing.fromJson(e))
            .toList();
      } else {
        _error = "Status ${resp.statusCode}";
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleFavorite(String id) async {
    final added = !_favoriteIds.contains(id);

    setState(() {
      if (added) {
        _favoriteIds.add(id);
      } else {
        _favoriteIds.remove(id);
      }
    });

    await _saveFavorites();
    if (!mounted) return;

    final msg = added
        ? "Listing added to favorites"
        : "Listing removed from favorites";

    toastification.show(
      context: context,
      type: added ? ToastificationType.success : ToastificationType.info,
      style: ToastificationStyle.fillColored,
      title: Text(msg),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    final w = MediaQuery.sizeOf(context).width;
    final isTablet = w >= 700;

    final hPad = isTablet ? 24.0 : 16.0;
    final height = isTablet ? 270.0 : 232.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t(lang, "explore.listings_title"),
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
              _GlassButton(
                label: t(lang, "explore.listings_hint"),
                onTap: () => Navigator.pushNamed(context, AppRoutes.listings),
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
                  child: _ErrorState(
                    message: _error!,
                    onRetry: () => _load(forceRefresh: true),
                  ),
                )
              : _items.isEmpty
              ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: _EmptyState(label: t(lang, "packages.empty")),
                )
              : ListView.separated(
                  // ✅ Keep simple scroll. No slide-to-reveal / dismiss logic anywhere.
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final listing = _items[i];
                    return _ListingCard(
                      listing: listing,
                      isTablet: isTablet,
                      isFavorite: _favoriteIds.contains(listing.id),
                      onToggleFavorite: () => _toggleFavorite(listing.id),
                      onOpen: () => Navigator.pushNamed(
                        context,
                        AppRoutes.listingDetails,
                        arguments: listing.id,
                      ),
                    );
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
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpen;

  const _ListingCard({
    required this.listing,
    required this.isTablet,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onOpen,
  });

  @override
  State<_ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<_ListingCard> {
  bool _pressed = false;
  bool _hover = false;

  void _setPressed(bool v) => setState(() => _pressed = v);
  void _setHover(bool v) => setState(() => _hover = v);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final cardW = widget.isTablet ? 270.0 : 210.0;
    final radius = BorderRadius.circular(widget.isTablet ? 26 : 22);

    final title = widget.listing.name.trim().isEmpty
        ? "Listing"
        : widget.listing.name.trim();
    final subtitle = _compactLocation(
      widget.listing.city,
      widget.listing.country,
    );

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onOpen,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          scale: _pressed ? 0.992 : 1.0,
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              children: [
                // Background image
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
                            return Container(
                              color: scheme.surfaceVariant.withOpacity(0.7),
                            );
                          },
                        )
                      : Container(
                          color: scheme.surfaceVariant.withOpacity(0.7),
                        ),
                ),

                // Vignette for readability
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.10),
                          Colors.black.withOpacity(0.55),
                        ],
                      ),
                    ),
                  ),
                ),

                // Glass border + depth
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
                          color: Colors.black.withOpacity(isDark ? 0.34 : 0.14),
                          blurRadius: 28,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                  ),
                ),

                // Specular highlight
                Positioned.fill(
                  child: IgnorePointer(
                    child: _SpecularHighlight(radius: radius),
                  ),
                ),

                // Bottom glass info
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: _GlassFooter(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: widget.isTablet ? 14.8 : 13.6,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                  height: 1.05,
                                ),
                              ),
                              if (subtitle.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: widget.isTablet ? 12.2 : 11.8,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withOpacity(0.82),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              _RatingPill(
                                rating: widget.listing.avgRating,
                                reviews: widget.listing.reviewsCount,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOutCubic,
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(
                              (_hover || _pressed) ? 0.18 : 0.12,
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.16),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Favorite button (tap only, no sliding)
                Positioned(
                  top: 10,
                  right: 10,
                  child: _FavoriteButton(
                    active: widget.isFavorite,
                    onTap: widget.onToggleFavorite,
                  ),
                ),

                // Fixed width for horizontal list
                SizedBox(width: cardW),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatefulWidget {
  final bool active;
  final VoidCallback onTap;

  const _FavoriteButton({required this.active, required this.onTap});

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  bool _pressed = false;
  void _set(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final bg = widget.active
        ? Colors.red
        : Colors.white.withOpacity(isDark ? 0.10 : 0.16);
    final border = widget.active
        ? Colors.red.withOpacity(0.9)
        : Colors.white.withOpacity(isDark ? 0.14 : 0.18);
    final iconColor = widget.active
        ? Colors.white
        : scheme.onSurface.withOpacity(isDark ? 0.92 : 0.86);

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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bg,
                border: Border.all(color: border),
              ),
              child: Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedBookmark01,
                  size: 12,
                  strokeWidth: 2,
                  color: iconColor,
                ),
              ),
            ),
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
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.14 : 0.18),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  final double rating;
  final int reviews;

  const _RatingPill({required this.rating, required this.reviews});

  @override
  Widget build(BuildContext context) {
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
            "($displayReviews)",
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

class _Listing {
  final String id;
  final String name;
  final String city;
  final String country;
  final String? imageUrl;
  final double avgRating;
  final int reviewsCount;

  const _Listing({
    required this.id,
    required this.name,
    required this.city,
    required this.country,
    required this.imageUrl,
    required this.avgRating,
    required this.reviewsCount,
  });

  factory _Listing.fromJson(Map json) {
    final avg = _toDouble(json["avg_rating"]);
    final reviews = _toInt(json["reviews_count"]);

    return _Listing(
      id: (json["id"] ?? "").toString(),
      name: (json["name"] ?? json["title"] ?? "").toString(),
      city: (json["city"] ?? "").toString(),
      country: (json["country"] ?? "").toString(),
      imageUrl: json["first_image_url"] as String?,
      avgRating: avg,
      reviewsCount: reviews,
    );
  }
}

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? 0;
  return 0;
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
    final cardW = isTablet ? 270.0 : 210.0;

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
                  height: 92,
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

class _GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GlassButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: scheme.surface.withOpacity(0.50),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: scheme.onSurface.withOpacity(0.10)),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
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
      width: 240,
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
          TextButton(
            onPressed: onRetry,
            child: Text(t(currentLangSync(), "common.try_again")),
          ),
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
      width: 240,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
        textAlign: TextAlign.center,
      ),
    );
  }
}

String _compactLocation(String city, String country) {
  final c = city.trim();
  final k = country.trim();
  if (c.isEmpty && k.isEmpty) return "";
  if (c.isEmpty) return k;
  if (k.isEmpty) return c;
  return "$c, $k";
}
