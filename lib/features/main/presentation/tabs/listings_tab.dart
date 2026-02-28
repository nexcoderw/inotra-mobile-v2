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

  static const int _pageSize = 10;

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
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 240 &&
        !_loading &&
        _hasMore) {
      _fetchPage(reset: false);
    }

    final show = _scrollCtrl.position.pixels > 320;
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
        "${PlaceEndpoints.list}"
        "?page=$_page&page_size=$_pageSize"
        "${_query.isNotEmpty ? "&search=$_query" : ""}",
      );

      final resp = await http.get(uri);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body);

        List<dynamic> results = const [];
        int? count;

        if (decoded is Map) {
          count = (decoded["count"] as num?)?.toInt();
          final dynamic candidate = decoded["results"] ??
              decoded["data"] ??
              decoded.values.firstWhere((v) => v is List, orElse: () => const []);
          results = candidate is List ? candidate : const [];
        } else if (decoded is List) {
          results = decoded;
        }

        final incoming = results
            .whereType<Map>()
            .map((e) => _Listing.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        final existing = _items.map((e) => e.id).toSet();
        final unique = incoming.where((e) => !existing.contains(e.id)).toList();

        setState(() {
          _items.addAll(unique);

          // Prefer API "next" if present, else use length/pageSize heuristic.
          final hasMoreByLen = incoming.length >= _pageSize;
          _hasMore = hasMoreByLen;

          if (_hasMore) _page += 1;

          // If count is known, we can be stricter.
          if (count != null && _items.length >= count) _hasMore = false;
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

    final w = MediaQuery.sizeOf(context).width;
    final isTablet = w >= 700;

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
                    padding: EdgeInsets.fromLTRB(isTablet ? 24 : 16, 16, isTablet ? 24 : 16, 12),
                    child: Text(
                      t(lang, "nav.listings"),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        fontFamily: "DM Sans",
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),

                // Search bar (glass)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(isTablet ? 24 : 16, 0, isTablet ? 24 : 16, 14),
                    child: _GlassSearchField(
                      controller: _searchCtrl,
                      hintText: t(lang, "packages.search_hint"),
                      onChanged: _onSearchChanged,
                      onClear: () {
                        _searchCtrl.clear();
                        _onSearchChanged("");
                      },
                    ),
                  ),
                ),

                // Initial load skeletons that match card design
                if (_loading && _items.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(isTablet ? 24 : 16, 0, isTablet ? 24 : 16, 14),
                      child: Column(
                        children: List.generate(
                          4,
                          (_) => const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: _ListingCardSkeleton(),
                          ),
                        ),
                      ),
                    ),
                  ),

                // List
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final showLoader = _loading && _items.isNotEmpty;

                      if (index >= _items.length) {
                        return showLoader
                            ? Padding(
                                padding: EdgeInsets.fromLTRB(
                                  isTablet ? 24 : 16,
                                  0,
                                  isTablet ? 24 : 16,
                                  14,
                                ),
                                child: const _ListingCardSkeleton(),
                              )
                            : const SizedBox.shrink();
                      }

                      final listing = _items[index];

                      return Padding(
                        padding: EdgeInsets.fromLTRB(isTablet ? 24 : 16, 0, isTablet ? 24 : 16, 14),
                        child: _ListingCard(
                          listing: listing,
                          isTablet: isTablet,
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

                // Error state
                if (_error != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(isTablet ? 24 : 16),
                      child: _ErrorPanel(
                        message: _error!,
                        onRetry: () => _fetchPage(reset: true),
                        retryText: t(lang, "common.try_again"),
                      ),
                    ),
                  ),

                // Empty state
                if (!_loading && _items.isEmpty && _error == null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(isTablet ? 24 : 16),
                      child: Center(
                        child: Text(
                          t(lang, "packages.empty"),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontFamily: "DM Sans",
                          ),
                        ),
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 70)),
              ],
            ),
          ),

          // Back to top
          if (_showBackToTop)
            Positioned(
              right: 16,
              bottom: 18,
              child: FloatingActionButton(
                mini: true,
                onPressed: () => _scrollCtrl.animateTo(
                  0,
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                ),
                child: const Icon(Icons.arrow_upward_rounded),
              ),
            ),
        ],
      ),
    );
  }
}

/* ----------------------------- DATA MODEL ----------------------------- */

class _Listing {
  final String id;
  final String name;

  // More listing information (from swagger)
  final String categoryId;
  final String categoryName;
  final String categoryIcon;

  final String city;
  final String country;
  final double? latitude;
  final double? longitude;

  final double avgRating;
  final int reviewsCount;

  final String? imageUrl;
  final DateTime? createdAt;

  const _Listing({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.avgRating,
    required this.reviewsCount,
    required this.imageUrl,
    required this.createdAt,
  });

  factory _Listing.fromJson(Map<String, dynamic> json) {
    final avg = (json["avg_rating"] as num?)?.toDouble() ?? 0.0;
    final reviews = (json["reviews_count"] as num?)?.toInt() ?? 0;

    DateTime? createdAt;
    final rawCreated = json["created_at"];
    if (rawCreated is String && rawCreated.isNotEmpty) {
      createdAt = DateTime.tryParse(rawCreated);
    }

    return _Listing(
      id: (json["id"] ?? "").toString(),
      name: (json["name"] ?? json["title"] ?? "").toString(),
      categoryId: (json["category_id"] ?? "").toString(),
      categoryName: (json["category_name"] ?? "").toString(),
      categoryIcon: (json["category_icon"] ?? "").toString(),
      city: (json["city"] ?? "").toString(),
      country: (json["country"] ?? "").toString(),
      latitude: _toDoubleOrNull(json["latitude"]),
      longitude: _toDoubleOrNull(json["longitude"]),
      avgRating: avg,
      reviewsCount: reviews,
      imageUrl: (json["first_image_url"] ?? json["image"] ?? json["cover_image"]) as String?,
      createdAt: createdAt,
    );
  }
}

double? _toDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

/* ----------------------------- UI WIDGETS ----------------------------- */

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

    final radius = BorderRadius.circular(widget.isTablet ? 26 : 22);
    final h = widget.isTablet ? 254.0 : 236.0;

    final title = widget.listing.name.trim().isEmpty ? "Listing" : widget.listing.name.trim();
    final location = _compactLocation(widget.listing.city, widget.listing.country);

    final category = widget.listing.categoryName.trim();
    final hasCategory = category.isNotEmpty;

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
            child: SizedBox(
              height: h,
              child: Stack(
                children: [
                  // Image
                  Positioned.fill(
                    child: widget.listing.imageUrl != null && widget.listing.imageUrl!.isNotEmpty
                        ? Image.network(
                            widget.listing.imageUrl!,
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

                  // Vignette
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.10),
                            Colors.black.withOpacity(0.60),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Border + depth
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
                            blurRadius: 30,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Specular highlight
                  Positioned.fill(
                    child: IgnorePointer(child: _SpecularHighlight(radius: radius)),
                  ),

                  // Top-left category chip
                  if (hasCategory)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _GlassChip(
                        icon: _mapCategoryIcon(widget.listing.categoryIcon),
                        label: widget.listing.categoryName,
                      ),
                    ),

                  // Top-right favorite
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _FavoriteButton(
                      active: widget.isFavorite,
                      onTap: widget.onToggleFavorite,
                    ),
                  ),

                  // Bottom content
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
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: widget.isTablet ? 16 : 14.5,
                                    color: Colors.white,
                                    letterSpacing: -0.25,
                                    height: 1.05,
                                    fontFamily: "DM Sans",
                                  ),
                                ),
                                if (location.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_rounded,
                                        size: 14,
                                        color: Colors.white.withOpacity(0.82),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          location,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: widget.isTablet ? 12.5 : 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white.withOpacity(0.82),
                                            fontFamily: "DM Sans",
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    _RatingPill(
                                      rating: widget.listing.avgRating,
                                      reviews: widget.listing.reviewsCount,
                                    ),
                                    if (widget.listing.latitude != null && widget.listing.longitude != null)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: _MiniMeta(
                                          icon: Icons.map_rounded,
                                          label: "Map",
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            curve: Curves.easeOutCubic,
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity((_hover || _pressed) ? 0.18 : 0.12),
                              border: Border.all(color: Colors.white.withOpacity(0.16)),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ----------------------------- SKELETON ----------------------------- */

class _ListingCardSkeleton extends StatelessWidget {
  const _ListingCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final w = MediaQuery.sizeOf(context).width;
    final isTablet = w >= 700;

    final radius = BorderRadius.circular(isTablet ? 26 : 22);
    final h = isTablet ? 254.0 : 236.0;

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: h,
        child: Stack(
          children: [
            // Base image-ish block
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant.withOpacity(0.60),
                ),
              ),
            ),

            // Vignette like the real card
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.06),
                      Colors.black.withOpacity(0.20),
                    ],
                  ),
                ),
              ),
            ),

            // Frosted glass layer
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: const SizedBox.expand(),
              ),
            ),

            // Border + depth like the card
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: scheme.onSurface.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 28,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
              ),
            ),

            // Category chip placeholder
            Positioned(
              top: 12,
              left: 12,
              child: _SkeletonPill(width: 110, height: 30),
            ),

            // Favorite circle placeholder
            Positioned(
              top: 10,
              right: 10,
              child: _SkeletonCircle(size: 36),
            ),

            // Bottom glass footer placeholder (matches real footer position & size)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonLine(width: 220, height: 14),
                        const SizedBox(height: 8),
                        _SkeletonLine(width: 160, height: 12),
                        const SizedBox(height: 12),
                        Row(
                          children: const [
                            _SkeletonPill(width: 92, height: 26),
                            SizedBox(width: 8),
                            _SkeletonPill(width: 62, height: 26),
                            Spacer(),
                            _SkeletonCircle(size: 40),
                          ],
                        ),
                      ],
                    ),
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

class _SkeletonLine extends StatelessWidget {
  final double width;
  final double height;
  const _SkeletonLine({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _SkeletonPill extends StatelessWidget {
  final double width;
  final double height;
  const _SkeletonPill({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  final double size;
  const _SkeletonCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.12),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
    );
  }
}

/* ----------------------------- SMALL UI HELPERS ----------------------------- */

class _GlassSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _GlassSearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 10, right: 6),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedSearch01,
                size: 14,
                strokeWidth: 2,
              ),
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: onClear,
                  )
                : null,
            filled: true,
            fillColor: scheme.surfaceVariant.withOpacity(isDark ? 0.35 : 0.55),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(
            fontFamily: "DM Sans",
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _GlassChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isDark ? 0.10 : 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(isDark ? 0.14 : 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white.withOpacity(0.92)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withOpacity(0.92),
                  fontFamily: "DM Sans",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniMeta extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniMeta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
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
          Icon(icon, size: 14, color: Colors.white.withOpacity(0.90)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white.withOpacity(0.92),
              fontFamily: "DM Sans",
            ),
          ),
        ],
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

    final bg = widget.active ? Colors.red : Colors.white.withOpacity(isDark ? 0.10 : 0.16);
    final border = widget.active
        ? Colors.red.withOpacity(0.9)
        : Colors.white.withOpacity(isDark ? 0.14 : 0.18);
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
              fontFamily: "DM Sans",
            ),
          ),
          const SizedBox(width: 6),
          Text(
            "($displayReviews)",
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.80),
              fontFamily: "DM Sans",
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

class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String retryText;

  const _ErrorPanel({
    required this.message,
    required this.onRetry,
    required this.retryText,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: scheme.surfaceVariant.withOpacity(0.6),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, color: scheme.error),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.error,
              fontWeight: FontWeight.w800,
              fontFamily: "DM Sans",
            ),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: onRetry, child: Text(retryText)),
        ],
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

IconData _mapCategoryIcon(String raw) {
  final v = raw.trim().toLowerCase();
  if (v.contains("hotel") || v.contains("accomod")) return Icons.hotel_rounded;
  if (v.contains("restaurant") || v.contains("food") || v.contains("cooking")) return Icons.restaurant_rounded;
  if (v.contains("park") || v.contains("attract") || v.contains("nature")) return Icons.park_rounded;
  if (v.contains("museum") || v.contains("memorial")) return Icons.museum_rounded;
  return Icons.place_rounded;
}