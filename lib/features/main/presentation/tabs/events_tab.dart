import "dart:async";
import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:http/http.dart" as http;
import "package:intl/intl.dart";

import "../../../../core/config/api.dart";
import "../../../../core/config/app_routes.dart";
import "../../../../core/constants/api/event_endpoints.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class EventsTab extends StatefulWidget {
  const EventsTab({super.key});

  @override
  State<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<EventsTab> with TickerProviderStateMixin {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();

  final List<_EventItem> _events = [];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  String _query = "";
  String? _statusFilter;
  String? _error;
  bool _showBackToTop = false;
  Timer? _debounce;
  double _scrollOffset = 0;

  // Entrance animation
  late AnimationController _entranceCtrl;
  late Animation<double> _entranceFade;
  late Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _entranceFade =
        CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _entranceSlide =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
            CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic));

    _fetchPage(reset: true);
    _scrollCtrl.addListener(_onScroll);

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _entranceCtrl.forward());
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
    final px = _scrollCtrl.position.pixels;

    if (px >= _scrollCtrl.position.maxScrollExtent - 200 &&
        !_loading &&
        _hasMore) {
      _fetchPage(reset: false);
    }

    final show = px > 300;
    if (show != _showBackToTop) setState(() => _showBackToTop = show);

    setState(() => _scrollOffset = px);
  }

  Future<void> _fetchPage({required bool reset}) async {
    setState(() {
      _loading = true;
      if (reset) {
        _page = 1;
        _hasMore = true;
        _events.clear();
      }
      _error = null;
    });

    try {
      final uri = Api.url(
        "${EventEndpoints.list}?page=$_page&page_size=10${_query.isNotEmpty ? "&search=$_query" : ""}",
      );
      final resp = await http.get(uri);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body);
        List results = const [];
        if (decoded is Map) {
          results =
              (decoded["results"] ?? decoded["data"] ?? const []) as List? ??
                  const [];
        } else if (decoded is List) {
          results = decoded;
        }
        final incoming = results
            .whereType<Map>()
            .map((m) => _EventItem.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        final existing = _events.map((e) => e.id).toSet();
        final unique =
            incoming.where((e) => !existing.contains(e.id)).toList();
        setState(() {
          _events.addAll(unique);
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
          _events.clear();
          _hasMore = false;
          _error = null;
          _loading = false;
        });
        return;
      }
      _fetchPage(reset: true);
    });
  }

  List<_EventItem> _applyFilter(List<_EventItem> list) {
    if (_statusFilter == null) return list;
    return list.where((e) => _statusBucket(e) == _statusFilter).toList();
  }

  String _statusBucket(_EventItem e) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (e.endAt != null && e.endAt!.isBefore(now)) return "ended";
    if (e.startAt != null) {
      final startDay =
          DateTime(e.startAt!.year, e.startAt!.month, e.startAt!.day);
      final tomorrow = today.add(const Duration(days: 1));
      if (startDay == today) return "happening";
      if (startDay == tomorrow) return "tomorrow";
      if (startDay.isAfter(tomorrow)) return "future";
    }
    return "future";
  }

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= 700;
    final hPad = isTablet ? 24.0 : 18.0;
    final filtered = _applyFilter(_events);

    // Header shrink factor
    final shrink = (_scrollOffset / 80.0).clamp(0.0, 1.0);

    // Grid: 1-col phone, 2-col tablet, portrait cards
    final crossCount = isTablet ? 2 : 1;
    final cardAspect = isTablet ? 0.64 : 0.68;

    final filters = <String?, String>{
      null: t(lang, "common.all"),
      "happening": t(lang, "events.status_happening"),
      "tomorrow": t(lang, "events.status_tomorrow"),
      "future": t(lang, "events.status_future"),
    };

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
                    // ── Sticky header ─────────────────────────────────
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _EventsHeaderDelegate(
                        shrink: shrink,
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

                    // ── Status filter rail ────────────────────────────
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _FilterRailDelegate(
                        filters: filters,
                        selectedFilter: _statusFilter,
                        onSelect: (v) {
                          HapticFeedback.selectionClick();
                          setState(() =>
                              _statusFilter = _statusFilter == v ? null : v);
                        },
                        isTablet: isTablet,
                        isDark: isDark,
                        scheme: scheme,
                      ),
                    ),

                    // ── Loading skeletons ─────────────────────────────
                    if (_loading && _events.isEmpty)
                      SliverPadding(
                        padding:
                            EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossCount,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: cardAspect,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _EventCardSkeleton(index: i),
                            childCount: 4,
                          ),
                        ),
                      ),

                    // ── Event grid ────────────────────────────────────
                    if (filtered.isNotEmpty)
                      SliverPadding(
                        padding:
                            EdgeInsets.fromLTRB(hPad, 10, hPad, 0),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossCount,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: cardAspect,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final showLoader =
                                  _loading && _events.isNotEmpty;
                              if (index >= filtered.length) {
                                return showLoader
                                    ? _EventCardSkeleton(index: index)
                                    : const SizedBox.shrink();
                              }
                              final evt = filtered[index];
                              return _AnimatedGridItem(
                                index: index,
                                child: _EventPosterCard(
                                  event: evt,
                                  lang: lang,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.eventDetails,
                                    arguments: evt.id,
                                  ),
                                ),
                              );
                            },
                            childCount: filtered.length +
                                ((_loading && _events.isNotEmpty) ? 2 : 0),
                          ),
                        ),
                      ),

                    // ── Error ─────────────────────────────────────────
                    if (_error != null)
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

                    // ── Empty ─────────────────────────────────────────
                    if (!_loading && filtered.isEmpty && _error == null)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(
                          lang: lang,
                          scheme: scheme,
                          hasFilter: _statusFilter != null,
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 90)),
                  ],
                ),
              ),

              // ── Back to top ──────────────────────────────────────────
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                right: 18,
                bottom: _showBackToTop ? 24 : -72,
                child: _BackToTopButton(
                  scheme: scheme,
                  onTap: () => _scrollCtrl.animateTo(
                    0,
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────────────
   STICKY HEADER DELEGATE
───────────────────────────────────────────────────────────────────────────── */

class _EventsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double shrink;
  final bool isTablet;
  final bool isDark;
  final ColorScheme scheme;
  final String lang;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClear;

  const _EventsHeaderDelegate({
    required this.shrink,
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
  bool shouldRebuild(_EventsHeaderDelegate old) =>
      shrink != old.shrink || searchCtrl.text != old.searchCtrl.text;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final range = maxExtent - minExtent;
    final t_ = range > 0 ? (shrinkOffset / range).clamp(0.0, 1.0) : 1.0;
    final hPad = isTablet ? 24.0 : 18.0;

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
                AnimatedOpacity(
                  opacity: (1.0 - t_ * 1.6).clamp(0.0, 1.0),
                  duration: Duration.zero,
                  child: Transform.translate(
                    offset: Offset(0, -t_ * 14),
                    child: Text(
                      t(lang, "nav.events"),
                      style: TextStyle(
                        fontSize: (28 - t_ * 6).clamp(22.0, 28.0),
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                        height: 1.0,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: (10 - t_ * 4).clamp(2.0, 10.0)),
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
   FILTER RAIL DELEGATE
───────────────────────────────────────────────────────────────────────────── */

class _FilterRailDelegate extends SliverPersistentHeaderDelegate {
  final Map<String?, String> filters;
  final String? selectedFilter;
  final ValueChanged<String?> onSelect;
  final bool isTablet;
  final bool isDark;
  final ColorScheme scheme;

  const _FilterRailDelegate({
    required this.filters,
    required this.selectedFilter,
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
  bool shouldRebuild(_FilterRailDelegate old) =>
      selectedFilter != old.selectedFilter ||
      filters.length != old.filters.length;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final hPad = isTablet ? 24.0 : 16.0;
    final entries = filters.entries.toList();

    return SizedBox.expand(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: scheme.surface.withOpacity(isDark ? 0.82 : 0.90),
            padding: EdgeInsets.only(
              left: hPad,
              right: hPad,
              bottom: 8,
            ),
            child: ScrollConfiguration(
              behavior: _NoGlowBehavior(),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(entries.length, (i) {
                    final entry = entries[i];
                    final selected = selectedFilter == entry.key;
                    return Padding(
                      padding: EdgeInsets.only(
                          right: i < entries.length - 1 ? 8 : 0),
                      child: _FilterPill(
                        label: entry.value,
                        selected: selected,
                        isDark: isDark,
                        scheme: scheme,
                        accent: _filterAccent(entry.key),
                        onTap: () => onSelect(entry.key),
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

  Color _filterAccent(String? key) {
    switch (key) {
      case "happening":
        return Colors.green;
      case "tomorrow":
        return Colors.orange;
      case "future":
        return Colors.blue;
      default:
        return Colors.transparent; // null = "all", uses primary
    }
  }
}

class _FilterPill extends StatefulWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final ColorScheme scheme;
  final Color accent;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.scheme,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_FilterPill> createState() => _FilterPillState();
}

class _FilterPillState extends State<_FilterPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _activeColor =>
      widget.accent == Colors.transparent ? widget.scheme.primary : widget.accent;

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
                ? _activeColor
                : (widget.isDark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.black.withOpacity(0.055)),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: widget.selected
                  ? _activeColor
                  : (widget.isDark
                      ? Colors.white.withOpacity(0.10)
                      : Colors.black.withOpacity(0.08)),
              width: 1.2,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: _activeColor.withOpacity(0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
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
   ANIMATED GRID ITEM
───────────────────────────────────────────────────────────────────────────── */

class _AnimatedGridItem extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedGridItem({required this.index, required this.child});

  @override
  State<_AnimatedGridItem> createState() => _AnimatedGridItemState();
}

class _AnimatedGridItemState extends State<_AnimatedGridItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    final delay = Duration(milliseconds: (widget.index * 55).clamp(0, 280));
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
   EVENT POSTER CARD
───────────────────────────────────────────────────────────────────────────── */

class _EventPosterCard extends StatefulWidget {
  final _EventItem event;
  final String lang;
  final VoidCallback onTap;

  const _EventPosterCard({
    required this.event,
    required this.lang,
    required this.onTap,
  });

  @override
  State<_EventPosterCard> createState() => _EventPosterCardState();
}

class _EventPosterCardState extends State<_EventPosterCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 130));
    _pressScale = Tween<double>(begin: 1.0, end: 0.974)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(24);
    final statusInfo = _resolveStatus(widget.event, widget.lang, scheme);
    final priceLabel = widget.event.minPrice <= 0
        ? t(widget.lang, "events.free")
        : "Rwf ${_formatPrice(widget.event.minPrice)}";
    final locationLabel = widget.event.location().isNotEmpty
        ? widget.event.location()
        : "—";

    return ScaleTransition(
      scale: _pressScale,
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp: (_) => _pressCtrl.reverse(),
        onTapCancel: () => _pressCtrl.reverse(),
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Full-bleed image ──────────────────────────────────
              _BannerImage(
                url: widget.event.bannerUrl,
                grayscale: statusInfo.isEnded,
                scheme: scheme,
              ),

              // ── Cinematic gradient overlay ────────────────────────
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
                        Colors.black.withOpacity(0.78),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Top ambient tint ──────────────────────────────────
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.center,
                      colors: [
                        Colors.black.withOpacity(0.20),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Specular highlight ────────────────────────────────
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
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
                                    Colors.white.withOpacity(0.10),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Card border ───────────────────────────────────────
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(
                      color: Colors.white.withOpacity(isDark ? 0.10 : 0.14),
                      width: 1,
                    ),
                  ),
                ),
              ),

              // ── Status badge (top-left) ───────────────────────────
              Positioned(
                top: 14,
                left: 14,
                child: _StatusBadge(info: statusInfo),
              ),

              // ── Bottom glass footer ───────────────────────────────
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: _EventGlassFooter(
                  title: widget.event.title,
                  locationLabel: locationLabel,
                  priceLabel: priceLabel,
                  isFree: widget.event.minPrice <= 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(double v) {
    if (v >= 1000000) return "${(v / 1000000).toStringAsFixed(1)}M";
    if (v >= 1000) return "${(v / 1000).toStringAsFixed(0)}k";
    return v.toStringAsFixed(0);
  }
}

/* ─────────────────────────────────────────────────────────────────────────────
   BANNER IMAGE
───────────────────────────────────────────────────────────────────────────── */

class _BannerImage extends StatelessWidget {
  final String? url;
  final bool grayscale;
  final ColorScheme scheme;

  const _BannerImage(
      {required this.url,
      required this.grayscale,
      required this.scheme});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.trim().isNotEmpty) {
      return ColorFiltered(
        colorFilter: grayscale
            ? const ColorFilter.mode(Colors.white, BlendMode.saturation)
            : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
        child: Image.network(
          url!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _ImagePlaceholder(scheme: scheme),
          loadingBuilder: (_, child, evt) =>
              evt == null ? child : _ImagePlaceholder(scheme: scheme),
        ),
      );
    }
    return _ImagePlaceholder(scheme: scheme);
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final ColorScheme scheme;
  const _ImagePlaceholder({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.surfaceVariant.withOpacity(0.80),
            scheme.surfaceVariant.withOpacity(0.50),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.event_outlined,
          size: 44,
          color: scheme.onSurfaceVariant.withOpacity(0.22),
        ),
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────────────
   STATUS BADGE
───────────────────────────────────────────────────────────────────────────── */

class _StatusBadge extends StatelessWidget {
  final _StatusInfo info;
  const _StatusBadge({required this.info});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: info.bgColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: info.borderColor, width: 1),
          ),
          child: Text(
            info.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: info.textColor,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────────────
   EVENT GLASS FOOTER
───────────────────────────────────────────────────────────────────────────── */

class _EventGlassFooter extends StatelessWidget {
  final String title;
  final String locationLabel;
  final String priceLabel;
  final bool isFree;

  const _EventGlassFooter({
    required this.title,
    required this.locationLabel,
    required this.priceLabel,
    required this.isFree,
  });

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
                color: Colors.white.withOpacity(isDark ? 0.12 : 0.17)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.3,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 9),

              // Location + price row
              Row(
                children: [
                  // Location pill
                  Expanded(
                    child: _MetaPill(
                      icon: Icons.location_on_rounded,
                      label: locationLabel,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Price pill
                  _MetaPill(
                    icon: isFree
                        ? Icons.celebration_rounded
                        : Icons.confirmation_number_outlined,
                    label: priceLabel,
                    highlight: isFree,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;

  const _MetaPill({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = highlight
        ? Colors.green.withOpacity(0.28)
        : Colors.black.withOpacity(0.26);
    final border = highlight
        ? Colors.green.withOpacity(0.40)
        : Colors.white.withOpacity(0.15);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withOpacity(0.90)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────────────
   SKELETON
───────────────────────────────────────────────────────────────────────────── */

class _EventCardSkeleton extends StatefulWidget {
  final int index;
  const _EventCardSkeleton({required this.index});

  @override
  State<_EventCardSkeleton> createState() => _EventCardSkeletonState();
}

class _EventCardSkeletonState extends State<_EventCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(24);

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Shimmer base
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1.5 + _shimmer.value * 3, 0),
                    end: Alignment(-0.5 + _shimmer.value * 3, 0),
                    colors: [
                      scheme.surfaceVariant.withOpacity(0.55),
                      scheme.surfaceVariant.withOpacity(0.75),
                      scheme.surfaceVariant.withOpacity(0.55),
                    ],
                  ),
                ),
              ),

              // Vignette
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.04),
                        Colors.black.withOpacity(0.20),
                      ],
                    ),
                  ),
                ),
              ),

              // Border
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(
                        color: scheme.onSurface.withOpacity(0.07)),
                  ),
                ),
              ),

              // Status pill placeholder
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  width: 96,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.09)),
                  ),
                ),
              ),

              // Glass footer skeleton
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
                            color: Colors.white.withOpacity(0.11)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 14,
                            width: double.infinity,
                            margin: const EdgeInsets.only(right: 48),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.13),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.10),
                                    borderRadius:
                                        BorderRadius.circular(999),
                                    border: Border.all(
                                        color: Colors.white
                                            .withOpacity(0.09)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 80,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color:
                                          Colors.white.withOpacity(0.09)),
                                ),
                              ),
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
        );
      },
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────────────
   SEARCH BAR
───────────────────────────────────────────────────────────────────────────── */

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
          const SizedBox(width: 13),
          Icon(
            Icons.search_rounded,
            size: 17,
            color: scheme.onSurface.withOpacity(0.45),
          ),
          const SizedBox(width: 9),
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
                  color: scheme.onSurface.withOpacity(0.38),
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
                    color: scheme.onSurface.withOpacity(0.15),
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

/* ─────────────────────────────────────────────────────────────────────────────
   ERROR / EMPTY / BACK-TO-TOP
───────────────────────────────────────────────────────────────────────────── */

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
                color: scheme.error, fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              backgroundColor: scheme.error.withOpacity(0.12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(retryText,
                style: TextStyle(
                    color: scheme.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String lang;
  final ColorScheme scheme;
  final bool hasFilter;

  const _EmptyState(
      {required this.lang,
      required this.scheme,
      required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilter
                ? Icons.filter_list_off_rounded
                : Icons.event_busy_outlined,
            size: 48,
            color: scheme.onSurface.withOpacity(0.20),
          ),
          const SizedBox(height: 14),
          Text(
            t(lang, "events.filter_empty"),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurface.withOpacity(0.40),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackToTopButton extends StatelessWidget {
  final ColorScheme scheme;
  final VoidCallback onTap;

  const _BackToTopButton({required this.scheme, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
          child: Icon(Icons.keyboard_arrow_up_rounded,
              color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────────────
   MISC
───────────────────────────────────────────────────────────────────────────── */

class _NoGlowBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;
}

/* ─────────────────────────────────────────────────────────────────────────────
   DATA MODEL
───────────────────────────────────────────────────────────────────────────── */

class _EventItem {
  final String id;
  final String title;
  final String? bannerUrl;
  final DateTime? startAt;
  final DateTime? endAt;
  final String venue;
  final String city;
  final String country;
  final double minPrice;

  _EventItem({
    required this.id,
    required this.title,
    required this.bannerUrl,
    required this.startAt,
    required this.endAt,
    required this.venue,
    required this.city,
    required this.country,
    required this.minPrice,
  });

  String location() {
    final parts =
        [venue, city, country].where((e) => e.trim().isNotEmpty).toList();
    return parts.join(" · ");
  }

  factory _EventItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      try {
        return DateTime.parse(raw).toLocal();
      } catch (_) {
        return null;
      }
    }

    final start = parseDt(
        json["start_at"]?.toString() ?? json["start_date"]?.toString());
    final end = parseDt(
        json["end_at"]?.toString() ?? json["end_date"]?.toString());

    return _EventItem(
      id: (json["id"] ?? "").toString(),
      title: (json["title"] ?? json["name"] ?? "Event").toString(),
      bannerUrl: (json["banner_url"] ??
          json["cover_url"] ??
          json["image"] ??
          json["first_image_url"]) as String?,
      startAt: start,
      endAt: end,
      venue: (json["venue_name"] ?? "").toString(),
      city: (json["city"] ?? "").toString(),
      country: (json["country"] ?? "").toString(),
      minPrice: (json["min_ticket_price"] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────────────
   STATUS HELPERS
───────────────────────────────────────────────────────────────────────────── */

class _StatusInfo {
  final String label;
  final Color bgColor;
  final Color textColor;
  final Color borderColor;
  final bool isEnded;

  const _StatusInfo({
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
    this.isEnded = false,
  });
}

_StatusInfo _resolveStatus(
    _EventItem e, String lang, ColorScheme scheme) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  if (e.endAt != null && e.endAt!.isBefore(now)) {
    return _StatusInfo(
      label: t(lang, "events.status_ended"),
      bgColor: Colors.red.withOpacity(0.52),
      textColor: Colors.white,
      borderColor: Colors.red.withOpacity(0.38),
      isEnded: true,
    );
  }

  if (e.startAt != null) {
    final startDay =
        DateTime(e.startAt!.year, e.startAt!.month, e.startAt!.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (startDay == today) {
      return _StatusInfo(
        label: t(lang, "events.status_happening"),
        bgColor: Colors.green.withOpacity(0.52),
        textColor: Colors.white,
        borderColor: Colors.green.withOpacity(0.38),
      );
    }

    if (startDay == tomorrow) {
      return _StatusInfo(
        label: t(lang, "events.status_tomorrow"),
        bgColor: Colors.white.withOpacity(0.18),
        textColor: Colors.white,
        borderColor: Colors.white.withOpacity(0.30),
      );
    }

    final diff = startDay.difference(today).inDays;
    final label = diff <= 30
        ? "In $diff day${diff == 1 ? '' : 's'}"
        : DateFormat("dd MMM").format(e.startAt!);

    return _StatusInfo(
      label: label,
      bgColor: Colors.black.withOpacity(0.36),
      textColor: Colors.white,
      borderColor: Colors.white.withOpacity(0.20),
    );
  }

  return _StatusInfo(
    label: t(lang, "events.status_ended"),
    bgColor: Colors.red.withOpacity(0.52),
    textColor: Colors.white,
    borderColor: Colors.red.withOpacity(0.38),
    isEnded: true,
  );
}