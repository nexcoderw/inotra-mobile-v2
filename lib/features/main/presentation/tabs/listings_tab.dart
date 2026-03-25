import "dart:async";
import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
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

class _ListingsTabState extends State<ListingsTab>
    with TickerProviderStateMixin {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  final ValueNotifier<bool> _showBackToTop = ValueNotifier(false);
  final List<_Listing> _items = [];
  final Set<String> _favorites = {};
  String? _selectedCategory;

  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  String _query = "";
  String? _error;
  Timer? _debounce;
  List<_CategoryFilter> _categoryFilters = [];

  late AnimationController _entranceCtrl;
  late Animation<double> _entranceFade;
  late Animation<Offset> _entranceSlide;

  static const _favKey = "explore_listing_favs";
  static const _expiryMs = 7 * 24 * 60 * 60 * 1000;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOut,
    );
    _entranceSlide =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic),
        );

    _init();
    _scrollCtrl.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _entranceCtrl.forward(),
    );
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
    } catch (_) {}
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final payload = _favorites.map((id) => {"id": id, "ts": now}).toList();
    await prefs.setString(_favKey, jsonEncode(payload));
  }

  void _onScroll() {
    final px = _scrollCtrl.position.pixels;

    if (px >= _scrollCtrl.position.maxScrollExtent - 240 &&
        !_loading &&
        _hasMore) {
      _fetchPage(reset: false);
    }

    final show = px > 320;
    if (show != _showBackToTop.value) _showBackToTop.value = show;
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
          final dynamic candidate =
              decoded["results"] ??
              decoded["data"] ??
              decoded.values.firstWhere(
                (v) => v is List,
                orElse: () => const [],
              );
          results = candidate is List ? candidate : const [];
        } else if (decoded is List) {
          results = decoded;
        }

        final incoming = results
            .whereType<Map>()
            .map((e) => _Listing.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        final catSet = <String>{};
        for (final l in [..._items, ...incoming]) {
          if (l.categoryName.isNotEmpty) catSet.add(l.categoryName);
        }
        _categoryFilters = [
          _CategoryFilter(
            label: t(currentLangSync(), "common.all"),
            value: null,
          ),
          ...catSet.map((c) => _CategoryFilter(label: c, value: c)),
        ];

        final existing = _items.map((e) => e.id).toSet();
        final unique = incoming.where((e) => !existing.contains(e.id)).toList();

        setState(() {
          _items.addAll(unique);
          final hasMoreByLen = incoming.length >= _pageSize;
          _hasMore = hasMoreByLen;
          if (_hasMore) _page += 1;
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
    setState(() {});
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
    HapticFeedback.lightImpact();
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

    toastification.show(
      context: context,
      type: added ? ToastificationType.success : ToastificationType.info,
      style: ToastificationStyle.fillColored,
      title: Text(added ? "Saved to favourites" : "Removed from favourites"),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _showBackToTop.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final w = MediaQuery.sizeOf(context).width;
    final isTablet = w >= 700;
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final hPad = isTablet ? 24.0 : 16.0;

    final visibleItems = _selectedCategory == null
        ? _items
        : _items.where((e) => e.categoryName == _selectedCategory).toList();

    final categories = _buildCategories(lang);

    return SafeArea(
      child: FadeTransition(
        opacity: _entranceFade,
        child: SlideTransition(
          position: _entranceSlide,
          child: Stack(
            children: [
              // ─── Main scrollable content ──────────────────────────────
              RefreshIndicator(
                onRefresh: _onRefresh,
                color: scheme.primary,
                child: CustomScrollView(
                  controller: _scrollCtrl,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── Sticky title + search header ──────────────────
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _ListingsHeaderDelegate(
                        isTablet: isTablet,
                        isDark: isDark,
                        scheme: scheme,
                        lang: lang,
                        searchCtrl: _searchCtrl,
                        onSearchChanged: _onSearchChanged,
                        onClear: () {
                          _searchCtrl.clear();
                          _onSearchChanged("");
                        },
                      ),
                    ),

                    // ── Sticky category rail ──────────────────────────
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _CategoryRailDelegate(
                        categories: categories,
                        selectedCategory: _selectedCategory,
                        onSelect: (v) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedCategory = v);
                        },
                        isTablet: isTablet,
                        isDark: isDark,
                        scheme: scheme,
                      ),
                    ),

                    // Skeletons
                    if (_loading && _items.isEmpty)
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _ListingCardSkeleton(index: i),
                            ),
                            childCount: 4,
                          ),
                        ),
                      ),

                    // Cards
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final showLoader = _loading && _items.isNotEmpty;
                            if (index >= visibleItems.length) {
                              return showLoader
                                  ? Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: _ListingCardSkeleton(index: index),
                                    )
                                  : const SizedBox.shrink();
                            }
                            final listing = visibleItems[index];
                            return _AnimatedListItem(
                              index: index,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _ListingCard(
                                  listing: listing,
                                  isTablet: isTablet,
                                  isFavorite: _favorites.contains(listing.id),
                                  onToggleFavorite: () =>
                                      _toggleFavorite(listing),
                                  onOpen: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.listingDetails,
                                    arguments: listing.id,
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount:
                              visibleItems.length +
                              ((_loading && _items.isNotEmpty) ? 1 : 0),
                        ),
                      ),
                    ),

                    // Error
                    if (_error != null)
                      SliverPadding(
                        padding: EdgeInsets.all(hPad),
                        sliver: SliverToBoxAdapter(
                          child: _ErrorPanel(
                            message: _error!,
                            onRetry: () => _fetchPage(reset: true),
                            retryText: t(lang, "common.try_again"),
                          ),
                        ),
                      ),

                    // Empty
                    if (!_loading && visibleItems.isEmpty && _error == null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 80),
                          child: _EmptyState(lang: lang),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 90)),
                  ],
                ),
              ),

              // ─── Back to top ──────────────────────────────────────────
              ValueListenableBuilder<bool>(
                valueListenable: _showBackToTop,
                child: _BackToTopButton(
                  onTap: () => _scrollCtrl.animateTo(
                    0,
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                  ),
                ),
                builder: (context, show, child) => AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  right: 18,
                  bottom: show ? 24 : -72,
                  child: child!,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_CategoryFilter> _buildCategories(String lang) {
    if (_categoryFilters.isNotEmpty) return _categoryFilters;
    final set = _items
        .map((e) => e.categoryName)
        .where((e) => e.isNotEmpty)
        .toSet();
    return [
      _CategoryFilter(label: t(lang, "common.all"), value: null),
      ...set.map((c) => _CategoryFilter(label: c, value: c)),
    ];
  }
}

/* ─────────────────────────────────────────────────────────────────────────────
   LISTINGS HEADER DELEGATE (title + search, pinned)
───────────────────────────────────────────────────────────────────────────── */

class _ListingsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final bool isTablet;
  final bool isDark;
  final ColorScheme scheme;
  final String lang;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClear;

  const _ListingsHeaderDelegate({
    required this.isTablet,
    required this.isDark,
    required this.scheme,
    required this.lang,
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.onClear,
  });

  @override
  double get minExtent => 68.0;
  @override
  double get maxExtent => 132.0;

  @override
  bool shouldRebuild(_ListingsHeaderDelegate old) =>
      isTablet != old.isTablet ||
      isDark != old.isDark ||
      lang != old.lang ||
      searchCtrl.text != old.searchCtrl.text;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = maxExtent - minExtent;
    final shrinkT = range > 0 ? (shrinkOffset / range).clamp(0.0, 1.0) : 1.0;
    final hPad = isTablet ? 24.0 : 16.0;

    return SizedBox.expand(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: scheme.surface.withOpacity(isDark ? 0.85 : 0.92),
            padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: (28.0 * (1.0 - shrinkT)).clamp(0.0, 28.0),
                  child: AnimatedOpacity(
                    opacity: (1.0 - shrinkT * 1.6).clamp(0.0, 1.0),
                    duration: Duration.zero,
                    child: Transform.translate(
                      offset: Offset(0, -shrinkT * 14),
                      child: Text(
                        t(lang, "nav.listings"),
                        style: TextStyle(
                          fontSize: (28 - shrinkT * 6).clamp(22.0, 28.0),
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                          height: 1.0,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: (10.0 * (1.0 - shrinkT)).clamp(0.0, 10.0)),
                _PremiumSearchBar(
                  controller: searchCtrl,
                  hintText: t(lang, "packages.search_hint"),
                  onChanged: onSearchChanged,
                  onClear: onClear,
                  isDark: isDark,
                  scheme: scheme,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────────────
   CATEGORY RAIL DELEGATE (pinned)
───────────────────────────────────────────────────────────────────────────── */

class _CategoryRailDelegate extends SliverPersistentHeaderDelegate {
  final List<_CategoryFilter> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onSelect;
  final bool isTablet;
  final bool isDark;
  final ColorScheme scheme;

  const _CategoryRailDelegate({
    required this.categories,
    required this.selectedCategory,
    required this.onSelect,
    required this.isTablet,
    required this.isDark,
    required this.scheme,
  });

  @override
  double get minExtent => 54.0;
  @override
  double get maxExtent => 54.0;

  @override
  bool shouldRebuild(_CategoryRailDelegate old) =>
      selectedCategory != old.selectedCategory ||
      categories.length != old.categories.length;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final hPad = isTablet ? 24.0 : 16.0;

    return SizedBox.expand(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: scheme.surface.withOpacity(isDark ? 0.82 : 0.90),
            padding: EdgeInsets.only(left: hPad, right: hPad, bottom: 8),
            child: ScrollConfiguration(
              behavior: _NoGlowBehavior(),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(categories.length, (i) {
                    final cat = categories[i];
                    final selected = selectedCategory == cat.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        right: i < categories.length - 1 ? 8 : 0,
                      ),
                      child: _CategoryPill(
                        label: cat.label,
                        selected: selected,
                        isDark: isDark,
                        scheme: scheme,
                        onTap: () => onSelect(cat.value),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────────────
   ANIMATED LIST ITEM
───────────────────────────────────────────────────────────────────────────── */

class _AnimatedListItem extends StatefulWidget {
  final int index;
  final Widget child;
  const _AnimatedListItem({required this.index, required this.child});

  @override
  State<_AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    final delay = Duration(milliseconds: (widget.index * 60).clamp(0, 280));
    Future.delayed(delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}

/* ─────────────────────────────────────────────────────────────────────────────
   CATEGORY PILL
───────────────────────────────────────────────────────────────────────────── */

class _CategoryPill extends StatefulWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final ColorScheme scheme;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.scheme,
    required this.onTap,
  });

  @override
  State<_CategoryPill> createState() => _CategoryPillState();
}

class _CategoryPillState extends State<_CategoryPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.93,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.selected
                ? widget.scheme.primary
                : (widget.isDark
                      ? Colors.white.withOpacity(0.07)
                      : Colors.black.withOpacity(0.055)),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: widget.selected
                  ? widget.scheme.primary
                  : (widget.isDark
                        ? Colors.white.withOpacity(0.10)
                        : Colors.black.withOpacity(0.08)),
              width: 1.2,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: widget.scheme.primary.withOpacity(0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
              color: widget.selected
                  ? Colors.white
                  : (widget.isDark
                        ? Colors.white.withOpacity(0.70)
                        : Colors.black.withOpacity(0.60)),
            ),
          ),
        ),
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────────────
   LISTING CARD
───────────────────────────────────────────────────────────────────────────── */

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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(widget.isTablet ? 28 : 24);
    final h = widget.isTablet ? 260.0 : 242.0;
    final title = widget.listing.name.trim().isEmpty
        ? "Listing"
        : widget.listing.name.trim();
    final location = _compactLocation(
      widget.listing.city,
      widget.listing.country,
    );
    final category = widget.listing.categoryName.trim();

    return AnimatedScale(
      scale: _pressed ? 0.974 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _pressed = true);
        },
        onTapUp: (_) {
          setState(() => _pressed = false);
        },
        onTapCancel: () {
          setState(() => _pressed = false);
        },
        onTap: widget.onOpen,
        child: ClipRRect(
          borderRadius: radius,
          child: SizedBox(
            height: h,
            child: Stack(
              children: [
                // Image
                Positioned.fill(
                  child: _CardImage(
                    url: widget.listing.imageUrl,
                    scheme: scheme,
                  ),
                ),

                // Cinematic gradient
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.35, 1.0],
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.72),
                        ],
                      ),
                    ),
                  ),
                ),

                // Top-left ambient
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withOpacity(0.20),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Specular
                Positioned.fill(
                  child: IgnorePointer(
                    child: _SpecularHighlight(radius: radius),
                  ),
                ),

                // Border
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(
                        color: Colors.white.withOpacity(isDark ? 0.10 : 0.14),
                      ),
                    ),
                  ),
                ),

                // Category badge
                if (category.isNotEmpty)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: _GlassBadge(label: category),
                  ),

                // Favourite
                Positioned(
                  top: 12,
                  right: 12,
                  child: _FavoriteButton(
                    active: widget.isFavorite,
                    onTap: widget.onToggleFavorite,
                  ),
                ),

                // Footer
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
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
                                  fontSize: widget.isTablet ? 16.5 : 15,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                  height: 1.1,
                                ),
                              ),
                              if (location.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      size: 13,
                                      color: Colors.white.withOpacity(0.72),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        location,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withOpacity(0.72),
                                        ),
                                      ),
                                    ),
                                  ],
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
                        _ArrowButton(pressed: _pressed),
                      ],
                    ),
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

/* ─────────────────────────────────────────────────────────────────────────────
   CARD SUB-WIDGETS
───────────────────────────────────────────────────────────────────────────── */

class _CardImage extends StatelessWidget {
  final String? url;
  final ColorScheme scheme;
  const _CardImage({required this.url, required this.scheme});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return Image.network(
        url!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _Placeholder(scheme: scheme),
        loadingBuilder: (context, child, evt) {
          if (evt == null) return child;
          return _Placeholder(scheme: scheme);
        },
      );
    }
    return _Placeholder(scheme: scheme);
  }
}

class _Placeholder extends StatelessWidget {
  final ColorScheme scheme;
  const _Placeholder({required this.scheme});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          scheme.surfaceVariant.withOpacity(0.8),
          scheme.surfaceVariant.withOpacity(0.5),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Icon(
        Icons.image_outlined,
        size: 42,
        color: scheme.onSurfaceVariant.withOpacity(0.22),
      ),
    ),
  );
}

class _GlassBadge extends StatelessWidget {
  final String label;
  const _GlassBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.28),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.16)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white.withOpacity(0.95),
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final bool pressed;
  const _ArrowButton({required this.pressed});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 160),
    curve: Curves.easeOutCubic,
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(pressed ? 0.22 : 0.13),
      border: Border.all(color: Colors.white.withOpacity(0.20)),
    ),
    child: const Center(
      child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
    ),
  );
}

class _GlassFooter extends StatelessWidget {
  final Widget child;
  const _GlassFooter({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isDark ? 0.09 : 0.13),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.12 : 0.17),
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
    final r = rating <= 0 ? "0.0" : rating.toStringAsFixed(1);
    final rc = reviews < 0 ? 0 : reviews;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.26),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 13, color: Colors.amber.shade300),
          const SizedBox(width: 5),
          Text(
            r,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            "($rc)",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.70),
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

class _FavoriteButtonState extends State<_FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.28), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.28, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_FavoriteButton old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active && widget.active) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.active
                    ? Colors.red.shade500
                    : Colors.white.withOpacity(isDark ? 0.10 : 0.16),
                border: Border.all(
                  color: widget.active
                      ? Colors.red.shade300.withOpacity(0.7)
                      : Colors.white.withOpacity(0.16),
                ),
                boxShadow: widget.active
                    ? [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.32),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Icon(
                  widget.active
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  size: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackToTopButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackToTopButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.primary,
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withOpacity(0.38),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.keyboard_arrow_up_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────────────
   SKELETON
───────────────────────────────────────────────────────────────────────────── */

class _ListingCardSkeleton extends StatefulWidget {
  final int index;
  const _ListingCardSkeleton({required this.index});

  @override
  State<_ListingCardSkeleton> createState() => _ListingCardSkeletonState();
}

class _ListingCardSkeletonState extends State<_ListingCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final w = MediaQuery.sizeOf(context).width;
    final isTablet = w >= 700;
    final radius = BorderRadius.circular(isTablet ? 28 : 24);
    final h = isTablet ? 260.0 : 242.0;

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        final v = _shimmer.value;
        return ClipRRect(
          borderRadius: radius,
          child: SizedBox(
            height: h,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-1.5 + v * 3, 0),
                        end: Alignment(-0.5 + v * 3, 0),
                        colors: [
                          scheme.surfaceVariant.withOpacity(0.55),
                          scheme.surfaceVariant.withOpacity(0.78),
                          scheme.surfaceVariant.withOpacity(0.55),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.04),
                          Colors.black.withOpacity(0.16),
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
                        color: scheme.onSurface.withOpacity(0.07),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: _SkeletonPill(width: 90, height: 30),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _SkeletonCircle(size: 38),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.09),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.10),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SkeletonLine(width: 200, height: 14),
                            const SizedBox(height: 8),
                            _SkeletonLine(width: 140, height: 11),
                            const SizedBox(height: 12),
                            const Row(
                              children: [
                                _SkeletonPill(width: 88, height: 26),
                                Spacer(),
                                _SkeletonCircle(size: 42),
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
      },
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────────────
   MISC
───────────────────────────────────────────────────────────────────────────── */

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
            top: -50,
            left: -30,
            child: Transform.rotate(
              angle: -0.3,
              child: Container(
                width: 200,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(80),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.12),
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

class _PremiumSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool isDark;
  final ColorScheme scheme;

  const _PremiumSearchBar({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
    required this.isDark,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.07)
            : Colors.black.withOpacity(0.055),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.10)
              : Colors.black.withOpacity(0.08),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.search_rounded,
            size: 17,
            color: scheme.onSurface.withOpacity(0.42),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface.withOpacity(0.36),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.onSurface.withOpacity(0.14),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 12,
                    color: scheme.onSurface.withOpacity(0.7),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: scheme.errorContainer.withOpacity(0.3),
        border: Border.all(color: scheme.error.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, color: scheme.error, size: 32),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.error,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              backgroundColor: scheme.error.withOpacity(0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              retryText,
              style: TextStyle(
                color: scheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String lang;
  const _EmptyState({required this.lang});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: scheme.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 14),
          Text(
            t(lang, "packages.empty"),
            style: TextStyle(
              color: scheme.onSurface.withOpacity(0.4),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double width;
  final double height;
  const _SkeletonLine({required this.width, required this.height});

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.13),
      borderRadius: BorderRadius.circular(999),
    ),
  );
}

class _SkeletonPill extends StatelessWidget {
  final double width;
  final double height;
  const _SkeletonPill({required this.width, required this.height});

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.10),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withOpacity(0.09)),
    ),
  );
}

class _SkeletonCircle extends StatelessWidget {
  final double size;
  const _SkeletonCircle({required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(0.10),
      border: Border.all(color: Colors.white.withOpacity(0.09)),
    ),
  );
}

class _NoGlowBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

/* ─────────────────────────────────────────────────────────────────────────────
   DATA MODEL
───────────────────────────────────────────────────────────────────────────── */

class _Listing {
  final String id;
  final String name;
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
    final avg = _toDoubleOrNull(json["avg_rating"]) ?? 0.0;
    final reviews = _toIntOrZero(json["reviews_count"]);
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
      imageUrl:
          (json["first_image_url"] ?? json["image"] ?? json["cover_image"])
              as String?,
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

int _toIntOrZero(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? 0;
  return 0;
}

class _CategoryFilter {
  final String label;
  final String? value;
  const _CategoryFilter({required this.label, required this.value});
}

String _compactLocation(String city, String country) {
  final c = city.trim();
  final k = country.trim();
  if (c.isEmpty && k.isEmpty) return "";
  if (c.isEmpty) return k;
  if (k.isEmpty) return c;
  return "$c, $k";
}
