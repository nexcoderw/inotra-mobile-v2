import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;
import "package:shared_preferences/shared_preferences.dart";
import "package:toastification/toastification.dart";

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/place_endpoints.dart";
import "../../../../core/config/app_routes.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

/// Totally different layout + behavior:
/// ✅ No sliding / no horizontal carousel
/// ✅ Cards stacked (one below another)
/// ✅ Advanced animations: staggered entrance + animated favorite pulse + ripple press
/// ✅ Designed to sit inside a parent scroll view (ListView shrinkWrap + no inner scrolling)
class ExploreListingsFeature extends StatefulWidget {
  const ExploreListingsFeature({super.key});

  @override
  State<ExploreListingsFeature> createState() => _ExploreListingsFeatureState();
}

class _ExploreListingsFeatureState extends State<ExploreListingsFeature>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  List<_Listing> _items = const [];
  Set<String> _favoriteIds = {};

  static const _favKey = "explore_listing_favs";
  static const _expiryMs = 7 * 24 * 60 * 60 * 1000; // 7 days

  late final AnimationController _introCtrl;

  @override
  void initState() {
    super.initState();
    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
    _init();
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    super.dispose();
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
    final payload =
        _favoriteIds.map((id) => {"id": id, "ts": now}).toList(growable: false);
    await prefs.setString(_favKey, jsonEncode(payload));
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

        // Restart entrance animation when fresh data is loaded.
        if (mounted) {
          _introCtrl.stop();
          _introCtrl.value = 0;
          _introCtrl.forward();
        }
      } else {
        _error = "Status ${resp.statusCode}";
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFavorite(String id) async {
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

    final msg = added ? "Listing added to favorites" : "Listing removed from favorites";

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
                    fontSize: isTablet ? 14 : 12,
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              _GlassLink(
                label: t(lang, "explore.listings_hint"),
                onTap: () => Navigator.pushNamed(context, AppRoutes.listings),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (_loading)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: Column(
              children: const [
                _VerticalListingSkeleton(),
                SizedBox(height: 12),
                _VerticalListingSkeleton(),
                SizedBox(height: 12),
                _VerticalListingSkeleton(),
                SizedBox(height: 12),
                _VerticalListingSkeleton(),
              ],
            ),
          )
        else if (_error != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: _ErrorState(message: _error!, onRetry: _load),
          )
        else if (_items.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: _EmptyState(label: t(lang, "packages.empty")),
          )
        else
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: ListView.separated(
              // IMPORTANT: stacked inside parent scroll (Explore page)
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final item = _items[i];
                final isFav = _favoriteIds.contains(item.id);

                // Stagger animation per item.
                final start = (i * 0.10).clamp(0.0, 0.60);
                final end = (start + 0.40).clamp(0.0, 1.0);

                final anim = CurvedAnimation(
                  parent: _introCtrl,
                  curve: Interval(start, end, curve: Curves.easeOutCubic),
                );

                return _StaggerIn(
                  animation: anim,
                  child: _VerticalListingCard(
                    listing: item,
                    isTablet: isTablet,
                    isFavorite: isFav,
                    onToggleFavorite: () => _toggleFavorite(item.id),
                    onOpen: () => Navigator.pushNamed(
                      context,
                      AppRoutes.listingDetails,
                      arguments: item.id,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _StaggerIn extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _StaggerIn({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final t = animation.value;
        final dy = (1 - t) * 18; // slide up
        final blur = (1 - t) * 6; // slight blur on entrance

        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, dy),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _VerticalListingCard extends StatefulWidget {
  final _Listing listing;
  final bool isTablet;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpen;

  const _VerticalListingCard({
    required this.listing,
    required this.isTablet,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onOpen,
  });

  @override
  State<_VerticalListingCard> createState() => _VerticalListingCardState();
}

class _VerticalListingCardState extends State<_VerticalListingCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _favPulseCtrl;

  @override
  void initState() {
    super.initState();
    _favPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _favPulseCtrl.dispose();
    super.dispose();
  }

  void _setPressed(bool v) => setState(() => _pressed = v);

  void _tapFavorite() {
    // pulse animation
    _favPulseCtrl.forward(from: 0);
    widget.onToggleFavorite();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final radius = BorderRadius.circular(widget.isTablet ? 26 : 22);
    final imgSize = widget.isTablet ? 118.0 : 104.0;

    final title = widget.listing.name.trim().isEmpty ? "Listing" : widget.listing.name.trim();
    final subtitle = _compactLocation(widget.listing.city, widget.listing.country);

    return GestureDetector(
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
              // Glass surface
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              scheme.surface.withOpacity(0.38),
                              scheme.surfaceVariant.withOpacity(0.16),
                            ]
                          : [
                              scheme.surface.withOpacity(0.75),
                              scheme.surfaceVariant.withOpacity(0.35),
                            ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(
                      color: Colors.white.withOpacity(isDark ? 0.12 : 0.16),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.30 : 0.10),
                        blurRadius: 26,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                ),
              ),

              // Specular highlight (different from the previous design)
              Positioned.fill(
                child: IgnorePointer(
                  child: _SoftSweepHighlight(radius: radius),
                ),
              ),

              // Content: left image + right details (completely different layout)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _Thumb(
                      size: imgSize,
                      radius: BorderRadius.circular(18),
                      imageUrl: widget.listing.imageUrl,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: widget.isTablet ? 15.5 : 14.3,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                              color: scheme.onSurface,
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
                                fontSize: widget.isTablet ? 12.5 : 12,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface.withOpacity(isDark ? 0.72 : 0.68),
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _RatingInline(
                                rating: widget.listing.avgRating,
                                reviews: widget.listing.reviewsCount,
                              ),
                              const Spacer(),
                              _OpenChip(
                                isTablet: widget.isTablet,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Favorite action (top-right) with pulse
              Positioned(
                top: 10,
                right: 10,
                child: AnimatedBuilder(
                  animation: _favPulseCtrl,
                  builder: (_, __) {
                    final t = Curves.easeOutBack.transform(_favPulseCtrl.value);
                    final s = 1.0 + (0.18 * t);
                    return Transform.scale(
                      scale: s,
                      child: _FavoriteGlassIcon(
                        active: widget.isFavorite,
                        onTap: _tapFavorite,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final double size;
  final BorderRadius radius;
  final String? imageUrl;

  const _Thumb({
    required this.size,
    required this.radius,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            Positioned.fill(
              child: imageUrl != null
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: scheme.surfaceVariant.withOpacity(0.7)),
                      loadingBuilder: (context, child, evt) {
                        if (evt == null) return child;
                        return Container(color: scheme.surfaceVariant.withOpacity(0.7));
                      },
                    )
                  : Container(color: scheme.surfaceVariant.withOpacity(0.7)),
            ),
            // subtle vignette on thumb
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.06),
                      Colors.black.withOpacity(0.26),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingInline extends StatelessWidget {
  final double rating;
  final int reviews;

  const _RatingInline({required this.rating, required this.reviews});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final displayRating = rating <= 0 ? "0.0" : rating.toStringAsFixed(1);
    final displayReviews = reviews < 0 ? 0 : reviews;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.onSurface.withOpacity(isDark ? 0.06 : 0.05),
        border: Border.all(color: scheme.onSurface.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedStar,
            size: 14,
            strokeWidth: 2,
            color: Colors.amber.shade400,
          ),
          const SizedBox(width: 6),
          Text(
            displayRating,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            "($displayReviews)",
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withOpacity(isDark ? 0.68 : 0.62),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenChip extends StatelessWidget {
  final bool isTablet;
  const _OpenChip({required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 12 : 10,
        vertical: isTablet ? 8 : 7,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withOpacity(0.22),
            scheme.primary.withOpacity(0.10),
          ],
        ),
        border: Border.all(color: scheme.primary.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_forward_rounded, size: 14, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            "Open",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteGlassIcon extends StatefulWidget {
  final bool active;
  final VoidCallback onTap;

  const _FavoriteGlassIcon({required this.active, required this.onTap});

  @override
  State<_FavoriteGlassIcon> createState() => _FavoriteGlassIconState();
}

class _FavoriteGlassIconState extends State<_FavoriteGlassIcon> {
  bool _pressed = false;
  void _set(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final bg = widget.active
        ? Colors.red
        : Colors.white.withOpacity(isDark ? 0.10 : 0.18);
    final border = widget.active
        ? Colors.red.withOpacity(0.9)
        : Colors.white.withOpacity(isDark ? 0.14 : 0.18);
    final iconColor = widget.active ? Colors.white : scheme.onSurface.withOpacity(0.88);

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
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: bg,
                border: Border.all(color: border),
                boxShadow: [
                  BoxShadow(
                    color: (widget.active ? Colors.red : scheme.primary).withOpacity(0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
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

class _SoftSweepHighlight extends StatelessWidget {
  final BorderRadius radius;
  const _SoftSweepHighlight({required this.radius});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: Transform.rotate(
              angle: -0.35,
              child: Container(
                width: 260,
                height: 190,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(90),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.16),
                      Colors.white.withOpacity(0.0),
                    ],
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

class _VerticalListingSkeleton extends StatelessWidget {
  const _VerticalListingSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final w = MediaQuery.sizeOf(context).width;
    final isTablet = w >= 700;

    final radius = BorderRadius.circular(isTablet ? 26 : 22);
    final imgSize = isTablet ? 118.0 : 104.0;

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: isTablet ? 140 : 128,
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
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: imgSize,
                      height: imgSize,
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: 200,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 12,
                          width: 160,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 28,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(999),
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
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: scheme.surfaceVariant.withOpacity(0.6),
        border: Border.all(color: scheme.onSurface.withOpacity(0.08)),
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
          const SizedBox(height: 6),
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
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.onSurface.withOpacity(0.08)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800),
        textAlign: TextAlign.center,
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
    final avg = (json["avg_rating"] as num?)?.toDouble() ?? 0.0;
    final reviews = (json["reviews_count"] as num?)?.toInt() ?? 0;

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

String _compactLocation(String city, String country) {
  final c = city.trim();
  final k = country.trim();
  if (c.isEmpty && k.isEmpty) return "";
  if (c.isEmpty) return k;
  if (k.isEmpty) return c;
  return "$c, $k";
}