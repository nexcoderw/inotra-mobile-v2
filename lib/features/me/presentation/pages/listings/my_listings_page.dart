import "dart:async";
import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:http/http.dart" as http;

import "../../../../../core/config/api.dart";
import "../../../../../core/config/app_routes.dart";
import "../../../../../core/constants/api/my_listing_endpoints.dart";
import "../../../../../core/services/auth_session.dart";
import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({super.key});

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage>
    with TickerProviderStateMixin {
  static const int _pageSize = 10;

  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  final List<_MyListingItem> _items = [];

  Timer? _debounce;
  bool _loading = false;
  bool _hasMore = true;
  bool _hydrated = false;
  bool _showBackToTop = false;
  int _page = 1;
  String _query = "";
  String? _error;
  String? _selectedCategory;
  List<_CategoryFilter> _categoryFilters = const [];

  late final AnimationController _entranceCtrl;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  String get _lang => currentLangSync();

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

    _scrollCtrl.addListener(_onScroll);
    _fetchPage(reset: true);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _entranceCtrl.forward(),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;

    final px = _scrollCtrl.position.pixels;
    if (px >= _scrollCtrl.position.maxScrollExtent - 240 &&
        !_loading &&
        _hasMore) {
      _fetchPage(reset: false);
    }

    final show = px > 320;
    if (show != _showBackToTop && mounted) {
      setState(() => _showBackToTop = show);
    }
  }

  Future<void> _fetchPage({required bool reset}) async {
    final valid = await AuthSession.instance.ensureValid();
    if (!valid) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hydrated = true;
        _items.clear();
        _hasMore = false;
        _error = t(_lang, "my_listings.session_expired");
      });
      return;
    }

    final token = AuthSession.instance.value.accessToken;
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hydrated = true;
        _items.clear();
        _hasMore = false;
        _error = t(_lang, "my_listings.session_expired");
      });
      return;
    }

    setState(() {
      _loading = true;
      if (reset) {
        _page = 1;
        _hasMore = true;
        _items.clear();
      }
      _error = null;
    });

    final params = <String, String>{
      "page": "$_page",
      "page_size": "$_pageSize",
      "ordering": "updated_at",
      "sort": "desc",
    };
    if (_query.isNotEmpty) params["search"] = _query;

    try {
      final uri = Api.url(
        MyListingEndpoints.list,
      ).replace(queryParameters: params);
      final response = await http
          .get(
            uri,
            headers: {
              "Accept": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401 || response.statusCode == 403) {
        await AuthSession.instance.expireSession();
        if (!mounted) return;
        setState(() {
          _loading = false;
          _hydrated = true;
          _items.clear();
          _hasMore = false;
          _error = t(_lang, "my_listings.session_expired");
        });
        return;
      }

      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _ApiException(
          _extractMessage(decoded) ?? "Status ${response.statusCode}",
        );
      }

      List<dynamic> results = const [];
      int? count;
      if (decoded is Map) {
        count = (decoded["count"] as num?)?.toInt();
        results = (decoded["results"] ?? const []) as List? ?? const [];
      } else if (decoded is List) {
        results = decoded;
      }

      final incoming = results
          .whereType<Map>()
          .map(
            (item) => _MyListingItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();

      final existingIds = _items.map((item) => item.id).toSet();
      final unique = incoming.where((item) => !existingIds.contains(item.id));

      final merged = [..._items, ...unique];
      final categories =
          merged
              .map((item) => item.categoryName)
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

      if (!mounted) return;
      setState(() {
        _items.addAll(unique);
        _categoryFilters = [
          _CategoryFilter(label: t(_lang, "common.all"), value: null),
          ...categories.map(
            (value) => _CategoryFilter(label: value, value: value),
          ),
        ];
        final hasMoreByLength = incoming.length >= _pageSize;
        _hasMore = hasMoreByLength;
        if (_hasMore) _page += 1;
        if (count != null && _items.length >= count) _hasMore = false;
        _hydrated = true;
        _loading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hydrated = true;
        _error = t(_lang, "my_listings.timeout");
      });
    } on _ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hydrated = true;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hydrated = true;
        _error = t(_lang, "my_listings.load_failed");
      });
    }
  }

  String? _extractMessage(dynamic decoded) {
    if (decoded is Map && decoded["message"] != null) {
      return decoded["message"].toString();
    }
    return null;
  }

  Future<void> _onRefresh() async => _fetchPage(reset: true);

  void _onSearchChanged(String value) {
    setState(() {});
    _query = value.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (_query.isEmpty) {
        _fetchPage(reset: true);
        return;
      }
      if (_query.length < 3) {
        if (!mounted) return;
        setState(() {
          _items.clear();
          _hasMore = false;
          _error = null;
          _loading = false;
          _hydrated = true;
        });
        return;
      }
      _fetchPage(reset: true);
    });
  }

  void _clearSearch() {
    if (_searchCtrl.text.isEmpty) return;
    _searchCtrl.clear();
    _onSearchChanged("");
  }

  @override
  Widget build(BuildContext context) {
    final lang = _lang;
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 700;
    final hPad = isTablet ? 24.0 : 16.0;

    final visibleItems = _selectedCategory == null
        ? _items
        : _items
              .where((item) => item.categoryName == _selectedCategory)
              .toList();

    return SafeArea(
      child: FadeTransition(
        opacity: _entranceFade,
        child: SlideTransition(
          position: _entranceSlide,
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: _onRefresh,
                color: scheme.primary,
                child: CustomScrollView(
                  controller: _scrollCtrl,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _MyListingsHeaderDelegate(
                        isTablet: isTablet,
                        isDark: isDark,
                        scheme: scheme,
                        lang: lang,
                        searchCtrl: _searchCtrl,
                        onSearchChanged: _onSearchChanged,
                        onClear: _clearSearch,
                        onAddTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.myListingAdd,
                        ),
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _CategoryRailDelegate(
                        categories: _buildCategories(lang),
                        selectedCategory: _selectedCategory,
                        onSelect: (value) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedCategory = value);
                        },
                        isTablet: isTablet,
                        isDark: isDark,
                        scheme: scheme,
                      ),
                    ),
                    if (_loading && _items.isEmpty)
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _ListingCardSkeleton(index: index),
                            ),
                            childCount: 4,
                          ),
                        ),
                      ),
                    if (visibleItems.isNotEmpty)
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final showLoader =
                                  _loading && visibleItems.isNotEmpty;
                              if (index >= visibleItems.length) {
                                return showLoader
                                    ? Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        child: _ListingCardSkeleton(
                                          index: index,
                                        ),
                                      )
                                    : const SizedBox.shrink();
                              }

                              final item = visibleItems[index];
                              return _AnimatedListItem(
                                index: index,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _MyListingCard(
                                    item: item,
                                    isTablet: isTablet,
                                    lang: lang,
                                    onOpen: () => Navigator.pushNamed(
                                      context,
                                      AppRoutes.listingDetails,
                                      arguments: item.id,
                                    ),
                                    onEdit: () => Navigator.pushNamed(
                                      context,
                                      AppRoutes.myListingEdit,
                                      arguments: {
                                        "listingId": item.id,
                                        "title": item.name,
                                      },
                                    ),
                                    onDelete: () => Navigator.pushNamed(
                                      context,
                                      AppRoutes.myListingDelete,
                                      arguments: {
                                        "listingId": item.id,
                                        "title": item.name,
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount:
                                visibleItems.length +
                                ((_loading && visibleItems.isNotEmpty) ? 1 : 0),
                          ),
                        ),
                      ),
                    if (_error != null && _items.isNotEmpty)
                      SliverPadding(
                        padding: EdgeInsets.all(hPad),
                        sliver: SliverToBoxAdapter(
                          child: _ErrorPanel(
                            message: _error!,
                            onRetry: () => _fetchPage(reset: true),
                            retryText: t(lang, "common.try_again"),
                            scheme: scheme,
                          ),
                        ),
                      ),
                    if (!_loading && _items.isEmpty && _error != null)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(
                          lang: lang,
                          scheme: scheme,
                          title: t(lang, "my_listings.error_title"),
                          description: _error!,
                          actionLabel: t(lang, "common.try_again"),
                          onAction: () => _fetchPage(reset: true),
                        ),
                      ),
                    if (!_loading &&
                        visibleItems.isEmpty &&
                        _error == null &&
                        _hydrated)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(
                          lang: lang,
                          scheme: scheme,
                          title: t(lang, "my_listings.empty_title"),
                          description:
                              _query.isNotEmpty || _selectedCategory != null
                              ? t(lang, "my_listings.empty_filtered")
                              : t(lang, "my_listings.empty_default"),
                          actionLabel:
                              (_query.isNotEmpty || _selectedCategory != null)
                              ? t(lang, "my_listings.reset")
                              : null,
                          onAction:
                              (_query.isNotEmpty || _selectedCategory != null)
                              ? () {
                                  setState(() {
                                    _query = "";
                                    _selectedCategory = null;
                                    _searchCtrl.clear();
                                  });
                                  _fetchPage(reset: true);
                                }
                              : null,
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 96)),
                  ],
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                right: 18,
                bottom: _showBackToTop ? 24 : -72,
                child: FloatingActionButton.small(
                  heroTag: "my-listings-top",
                  backgroundColor: scheme.primary,
                  foregroundColor: Colors.white,
                  onPressed: () => _scrollCtrl.animateTo(
                    0,
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                  ),
                  child: const Icon(Icons.arrow_upward_rounded),
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
        .map((item) => item.categoryName)
        .where((value) => value.isNotEmpty)
        .toSet();
    return [
      _CategoryFilter(label: t(lang, "common.all"), value: null),
      ...set.map((value) => _CategoryFilter(label: value, value: value)),
    ];
  }
}

class _MyListingsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final bool isTablet;
  final bool isDark;
  final ColorScheme scheme;
  final String lang;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClear;
  final VoidCallback onAddTap;

  const _MyListingsHeaderDelegate({
    required this.isTablet,
    required this.isDark,
    required this.scheme,
    required this.lang,
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.onClear,
    required this.onAddTap,
  });

  @override
  double get minExtent => 68.0;

  @override
  double get maxExtent => 132.0;

  @override
  bool shouldRebuild(_MyListingsHeaderDelegate oldDelegate) =>
      isTablet != oldDelegate.isTablet ||
      isDark != oldDelegate.isDark ||
      lang != oldDelegate.lang ||
      searchCtrl.text != oldDelegate.searchCtrl.text;

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
            color: scheme.surface.withValues(alpha: isDark ? 0.85 : 0.92),
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
                        t(lang, "nav.my_listings"),
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
                Row(
                  children: [
                    Expanded(
                      child: _PremiumSearchBar(
                        controller: searchCtrl,
                        hintText: t(lang, "my_listings.search_hint"),
                        onChanged: onSearchChanged,
                        onClear: onClear,
                        isDark: isDark,
                        scheme: scheme,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _ToolbarActionButton(
                      label: t(lang, "my_listings.add_listing"),
                      scheme: scheme,
                      onTap: onAddTap,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
  bool shouldRebuild(_CategoryRailDelegate oldDelegate) =>
      selectedCategory != oldDelegate.selectedCategory ||
      categories.length != oldDelegate.categories.length;

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
            color: scheme.surface.withValues(alpha: isDark ? 0.82 : 0.90),
            padding: EdgeInsets.only(left: hPad, right: hPad, bottom: 8),
            child: ScrollConfiguration(
              behavior: _NoGlowBehavior(),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(categories.length, (index) {
                    final category = categories[index];
                    final selected = selectedCategory == category.value;
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < categories.length - 1 ? 8 : 0,
                      ),
                      child: _CategoryPill(
                        label: category.label,
                        selected: selected,
                        isDark: isDark,
                        scheme: scheme,
                        onTap: () => onSelect(category.value),
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

class _AnimatedListItem extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedListItem({required this.index, required this.child});

  @override
  State<_AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

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
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

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
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

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
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.black.withValues(alpha: 0.055)),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: widget.selected
                  ? widget.scheme.primary
                  : (widget.isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.black.withValues(alpha: 0.08)),
              width: 1.2,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: widget.scheme.primary.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : const [],
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
                        ? Colors.white.withValues(alpha: 0.70)
                        : Colors.black.withValues(alpha: 0.60)),
            ),
          ),
        ),
      ),
    );
  }
}

class _MyListingCard extends StatelessWidget {
  final _MyListingItem item;
  final bool isTablet;
  final String lang;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MyListingCard({
    required this.item,
    required this.isTablet,
    required this.lang,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(isTablet ? 28 : 24);
    final height = isTablet ? 260.0 : 242.0;
    final title = item.name.trim().isEmpty
        ? t(lang, "my_listings.fallback_title")
        : item.name.trim();
    final location = _compactLocation(item.city, item.country);
    final category = item.categoryName.trim();

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: _CardImage(url: item.imageUrl, scheme: scheme),
            ),
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
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(child: _SpecularHighlight(radius: radius)),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.14),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: onOpen),
              ),
            ),
            if (category.isNotEmpty)
              Positioned(
                top: 14,
                left: 14,
                child: _GlassBadge(label: category),
              ),
            Positioned(
              top: 12,
              right: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ManagementIconButton(
                    icon: Icons.edit_outlined,
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 8),
                  _ManagementIconButton(
                    icon: Icons.delete_outline_rounded,
                    destructive: true,
                    onTap: onDelete,
                  ),
                ],
              ),
            ),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: isTablet ? 16.5 : 15,
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
                                  color: Colors.white.withValues(alpha: 0.72),
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
                                      color: Colors.white.withValues(
                                        alpha: 0.72,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _StatusPill(
                                label: item.isActive
                                    ? t(lang, "my_listings.status_active")
                                    : t(lang, "my_listings.status_inactive"),
                                color: item.isActive
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF6B7280),
                              ),
                              _StatusPill(
                                label: item.isVerified
                                    ? t(lang, "my_listings.status_verified")
                                    : t(lang, "my_listings.status_unverified"),
                                color: item.isVerified
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFFF59E0B),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _ArrowButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
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
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.surfaceContainerHighest.withValues(alpha: 0.8),
            scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 42,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.22),
        ),
      ),
    );
  }
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
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.95),
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _ManagementIconButton extends StatelessWidget {
  final IconData icon;
  final bool destructive;
  final VoidCallback onTap;

  const _ManagementIconButton({
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = destructive ? scheme.error : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: destructive
                  ? bg.withValues(alpha: 0.88)
                  : bg.withValues(alpha: 0.18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Icon(
              icon,
              size: 16,
              color: destructive ? Colors.white : Colors.white,
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
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isDark ? 0.09 : 0.13),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.17),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.13),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: const Center(
        child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
      ),
    );
  }
}

class _ToolbarActionButton extends StatelessWidget {
  final String label;
  final ColorScheme scheme;
  final VoidCallback onTap;

  const _ToolbarActionButton({
    required this.label,
    required this.scheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ListingCardSkeleton extends StatefulWidget {
  final int index;

  const _ListingCardSkeleton({required this.index});

  @override
  State<_ListingCardSkeleton> createState() => _ListingCardSkeletonState();
}

class _ListingCardSkeletonState extends State<_ListingCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

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
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 700;
    final radius = BorderRadius.circular(isTablet ? 28 : 24);
    final height = isTablet ? 260.0 : 242.0;

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        final value = _shimmer.value;
        return ClipRRect(
          borderRadius: radius,
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-1.5 + value * 3, 0),
                        end: Alignment(-0.5 + value * 3, 0),
                        colors: [
                          scheme.surfaceContainerHighest.withValues(
                            alpha: 0.55,
                          ),
                          scheme.surfaceContainerHighest.withValues(
                            alpha: 0.78,
                          ),
                          scheme.surfaceContainerHighest.withValues(
                            alpha: 0.55,
                          ),
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
                          Colors.black.withValues(alpha: 0.04),
                          Colors.black.withValues(alpha: 0.16),
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
                        color: scheme.onSurface.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  top: 14,
                  left: 14,
                  child: _SkeletonPill(width: 90, height: 30),
                ),
                const Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      _SkeletonCircle(size: 38),
                      SizedBox(width: 8),
                      _SkeletonCircle(size: 38),
                    ],
                  ),
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
                          color: Colors.white.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            _SkeletonLine(width: 200, height: 14),
                            SizedBox(height: 8),
                            _SkeletonLine(width: 140, height: 11),
                            SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _SkeletonPill(width: 88, height: 26),
                                _SkeletonPill(width: 96, height: 26),
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
                      Colors.white.withValues(alpha: 0.12),
                      Colors.white.withValues(alpha: 0.0),
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
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.search_rounded,
            size: 17,
            color: scheme.onSurface.withValues(alpha: 0.42),
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
                  color: scheme.onSurface.withValues(alpha: 0.36),
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
                    color: scheme.onSurface.withValues(alpha: 0.14),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 12,
                    color: scheme.onSurface.withValues(alpha: 0.70),
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
  final ColorScheme scheme;

  const _ErrorPanel({
    required this.message,
    required this.onRetry,
    required this.retryText,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: scheme.errorContainer.withValues(alpha: 0.30),
        border: Border.all(color: scheme.error.withValues(alpha: 0.20)),
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
              backgroundColor: scheme.error.withValues(alpha: 0.12),
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
  final ColorScheme scheme;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.lang,
    required this.scheme,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: scheme.onSurface.withValues(alpha: 0.20),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.88),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.56),
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
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
        color: Colors.white.withValues(alpha: 0.13),
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
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
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
        color: Colors.white.withValues(alpha: 0.10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
    );
  }
}

class _NoGlowBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class _MyListingItem {
  final String id;
  final String name;
  final String categoryName;
  final String city;
  final String country;
  final bool isActive;
  final bool isVerified;
  final String? imageUrl;
  final DateTime? updatedAt;

  const _MyListingItem({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.city,
    required this.country,
    required this.isActive,
    required this.isVerified,
    required this.imageUrl,
    required this.updatedAt,
  });

  factory _MyListingItem.fromJson(Map<String, dynamic> json) {
    return _MyListingItem(
      id: (json["id"] ?? "").toString(),
      name: (json["name"] ?? "").toString(),
      categoryName: (json["category_name"] ?? "").toString(),
      city: (json["city"] ?? "").toString(),
      country: (json["country"] ?? "").toString(),
      isActive: json["is_active"] == true,
      isVerified: json["is_verified"] == true,
      imageUrl:
          _stringOrNull(json["first_image_url"]) ??
          _stringOrNull(json["logo_url"]),
      updatedAt: _parseDate(json["updated_at"]),
    );
  }
}

class _CategoryFilter {
  final String label;
  final String? value;

  const _CategoryFilter({required this.label, required this.value});
}

class _ApiException implements Exception {
  final String message;

  const _ApiException(this.message);
}

DateTime? _parseDate(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

String? _stringOrNull(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String _compactLocation(String city, String country) {
  final parts = [city.trim(), country.trim()].where((part) => part.isNotEmpty);
  return parts.join(", ");
}
