import "dart:async";
import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;
import "package:shared_preferences/shared_preferences.dart";
import "package:toastification/toastification.dart";

import "../../../../core/config/api.dart";
import "../../../../core/config/app_routes.dart";
import "../../../../core/constants/api/place_endpoints.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class ListingsTab extends StatefulWidget {
  const ListingsTab({super.key});

  @override
  State<ListingsTab> createState() => _ListingsTabState();
}

class _ListingsTabState extends State<ListingsTab> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  final List<_Listing> _items = [];
  final Set<String> _favorites = {};

  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  String _query = "";
  String? _error;
  bool _showBackToTop = false;
  Timer? _debounce;

  static const _favKey = "explore_listing_favs";
  static const _expiryMs = 7 * 24 * 60 * 60 * 1000;

  @override
  void initState() {
    super.initState();
    _init();
    _scrollCtrl.addListener(_onScroll);
  }

  Future<void> _init() async {
    await _loadFavorites();
    await _fetchPage(reset: true);
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
        _favorites
          ..clear()
          ..addAll(kept.map((m) => (m["id"] ?? "").toString()));
        await prefs.setString(_favKey, jsonEncode(kept));
        if (mounted) setState(() {});
      }
    } catch (_) {
      // ignore cache errors
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final payload = _favorites.map((id) => {"id": id, "ts": now}).toList();
    await prefs.setString(_favKey, jsonEncode(payload));
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_loading &&
        _hasMore) {
      _fetchPage(reset: false);
    }
    final show = _scrollCtrl.position.pixels > 300;
    if (show != _showBackToTop) setState(() => _showBackToTop = show);
  }

  Future<void> _fetchPage({required bool reset}) async {
    setState(() {
      _loading = true;
      if (reset) {
        _page = 1;
        _hasMore = true;
        _items.clear();
      }
      _error = null;
    });

    try {
      final uri = Api.url(
        "${PlaceEndpoints.list}?page=$_page&page_size=10&limit=10${_query.isNotEmpty ? "&search=$_query" : ""}",
      );
      final resp = await http.get(uri);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body);
        List<dynamic> results = const [];
        if (decoded is Map) {
          final dynamic candidate =
              decoded["results"] ?? decoded["data"] ?? decoded.values.firstWhere(
                  (v) => v is List,
                  orElse: () => const []);
          results = candidate is List ? candidate : const [];
        } else if (decoded is List) {
          results = decoded;
        }
        final incoming =
            results.whereType<Map>().map((e) => _Listing.fromJson(e)).toList();
        final existing = _items.map((e) => e.id).toSet();
        final unique = incoming.where((e) => !existing.contains(e.id)).toList();
        setState(() {
          _items.addAll(unique);
          _hasMore = incoming.length >= 10;
          if (_hasMore) _page += 1;
        });
      } else {
        setState(() => _error = "Status ${resp.statusCode}");
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onRefresh() async => _fetchPage(reset: true);

  void _onSearchChanged(String v) {
    setState(() {}); // refresh clear icon visibility
    _query = v.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (_query.isEmpty) {
        _fetchPage(reset: true);
        return;
      }
      if (_query.length < 3) {
        setState(() {
          _items.clear();
          _hasMore = false;
          _error = null;
          _loading = false;
        });
        return;
      }
      _fetchPage(reset: true);
    });
  }

  void _toggleFavorite(_Listing listing) async {
    final added = !_favorites.contains(listing.id);
    setState(() {
      if (added) {
        _favorites.add(listing.id);
      } else {
        _favorites.remove(listing.id);
      }
    });
    await _saveFavorites();
    if (!mounted) return;
    final msg =
        added ? "Listing added to favorites" : "Listing removed from favorites";
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
  void dispose() {
    _debounce?.cancel();
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _onRefresh,
            child: CustomScrollView(
              controller: _scrollCtrl,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Text(
                      t(lang, "nav.listings"),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: t(lang, "packages.search_hint"),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 10, right: 6),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedSearch01,
                            size: 14,
                            strokeWidth: 2,
                          ),
                        ),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _onSearchChanged("");
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: scheme.surfaceVariant.withOpacity(0.6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: "DM Sans",
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                if (_loading && _items.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Column(
                        children: List.generate(
                          3,
                          (_) => const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: _ListingSkeleton(),
                          ),
                        ),
                      ),
                    ),
                  ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final showLoader = _loading && _items.isNotEmpty;
                      if (index >= _items.length) {
                        return showLoader
                            ? const Padding(
                                padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                                child: _ListingSkeleton(),
                              )
                            : const SizedBox.shrink();
                      }
                      final listing = _items[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: _ListingCard(
                          listing: listing,
                          isTablet: MediaQuery.sizeOf(context).width >= 700,
                          isFavorite: _favorites.contains(listing.id),
                          onToggleFavorite: () => _toggleFavorite(listing),
                          onOpen: () => Navigator.pushNamed(
                            context,
                            AppRoutes.listingDetails,
                            arguments: listing.id,
                          ),
                        ),
                      );
                    },
                    childCount: _items.length + ((_loading && _items.isNotEmpty) ? 1 : 0),
                  ),
                ),
                if (_error != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            _error!,
                            style: TextStyle(
                              color: scheme.error,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => _fetchPage(reset: true),
                            child: Text(t(lang, "common.try_again")),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!_loading && _items.isEmpty && _error == null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          t(lang, "packages.empty"),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 60)),
              ],
            ),
          ),
          if (_showBackToTop)
            Positioned(
              right: 16,
              bottom: 18,
              child: FloatingActionButton(
                mini: true,
                onPressed: () => _scrollCtrl.animateTo(
                  0,
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOut,
                ),
                child: const Icon(Icons.arrow_upward_rounded),
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
  final String? imageUrl;
  final double avgRating;
  final int reviewsCount;

  const _Listing({
    required this.id,
    required this.name,
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
      imageUrl: json["first_image_url"] as String?,
      avgRating: avg,
      reviewsCount: reviews,
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
  void _set(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final cardW = widget.isTablet ? 260.0 : 200.0;
    final cardH = widget.isTablet ? 230.0 : 210.0;
    final radius = BorderRadius.circular(widget.isTablet ? 26 : 22);

    final title = widget.listing.name.trim().isEmpty ? "Listing" : widget.listing.name.trim();

    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onOpen,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.992 : 1.0,
        child: SizedBox(
          width: cardW,
          height: cardH,
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              children: [
                Positioned.fill(
                  child: widget.listing.imageUrl != null && widget.listing.imageUrl!.isNotEmpty
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
                Positioned(
                  top: 10,
                  right: 10,
                  child: _FavoriteButton(
                    active: widget.isFavorite,
                    onTap: widget.onToggleFavorite,
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: _SpecularHighlight(radius: radius),
                  ),
                ),
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

  const _FavoriteButton({
    required this.active,
    required this.onTap,
  });

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

    final bg = widget.active ? Colors.red : Colors.white.withOpacity(isDark ? 0.10 : 0.16);
    final border =
        widget.active ? Colors.red.withOpacity(0.9) : Colors.white.withOpacity(isDark ? 0.14 : 0.18);
    final iconColor =
        widget.active ? Colors.white : scheme.onSurface.withOpacity(isDark ? 0.92 : 0.86);

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
            border: Border.all(color: Colors.white.withOpacity(isDark ? 0.14 : 0.18)),
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

  const _RatingPill({
    required this.rating,
    required this.reviews,
  });

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
