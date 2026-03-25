import "dart:async";
import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:http/http.dart" as http;

import "../../../../core/config/api.dart";
import "../../../../core/config/app_routes.dart";
import "../../../../core/constants/api/package_endpoints.dart";
import "../../../../core/widgets/app_cached_image.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/page_header.dart";

class TripPackagesPage extends StatefulWidget {
  const TripPackagesPage({super.key});

  @override
  State<TripPackagesPage> createState() => _TripPackagesPageState();
}

class _TripPackagesPageState extends State<TripPackagesPage>
    with TickerProviderStateMixin {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();

  final List<_Package> _packages = [];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  String _query = "";
  String? _error;
  bool _showBackToTop = false;
  Timer? _searchDebounce;
  double _scrollOffset = 0;

  // Entrance animation
  late AnimationController _entranceCtrl;
  late Animation<double> _entranceFade;
  late Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOut,
    );
    _entranceSlide =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic),
        );

    _fetchPage(reset: true);
    _scrollCtrl.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _entranceCtrl.forward(),
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    _entranceCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async => _fetchPage(reset: true);

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
        _packages.clear();
      }
      _error = null;
    });

    try {
      final uri = Api.url(
        "${PackageEndpoints.list}?page=$_page&page_size=10${_query.isNotEmpty ? "&search=$_query" : ""}",
      );
      final resp = await http.get(uri);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body);
        final results =
            (decoded is Map ? decoded["results"] : decoded) as List? ?? [];
        final items = results
            .whereType<Map<String, dynamic>>()
            .map(_Package.fromJson)
            .toList();
        setState(() {
          final existing = _packages.map((e) => e.id).toSet();
          final unique = items.where((e) => !existing.contains(e.id)).toList();
          _packages.addAll(unique);
          _hasMore = items.length >= 10;
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

  void _onSearchChanged(String v) {
    setState(() {});
    _query = v.trim();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (_query.isEmpty) {
        _fetchPage(reset: true);
        return;
      }
      if (_query.length < 3) {
        setState(() {
          _packages.clear();
          _hasMore = false;
          _error = null;
          _loading = false;
        });
        return;
      }
      _fetchPage(reset: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final w = MediaQuery.sizeOf(context).width;
    final isTablet = w >= 700;
    final hPad = isTablet ? 24.0 : 18.0;
    final titleT = (_scrollOffset / 72.0).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _entranceFade,
          child: SlideTransition(
            position: _entranceSlide,
            child: Stack(
              children: [
                // ── Main content ─────────────────────────────────────
                RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: scheme.primary,
                  child: CustomScrollView(
                    controller: _scrollCtrl,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // ── Page header ─────────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(hPad - 4, 12, hPad, 0),
                          child: PageHeader(title: t(lang, "packages.title")),
                        ),
                      ),

                      // ── Search bar ──────────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 14),
                          child: _PremiumSearchBar(
                            controller: _searchCtrl,
                            hintText: t(lang, "packages.search_hint"),
                            onChanged: _onSearchChanged,
                            onClear: () {
                              _searchCtrl.clear();
                              _onSearchChanged("");
                            },
                            isDark: isDark,
                            scheme: scheme,
                          ),
                        ),
                      ),

                      // ── Result count label ──────────────────────────
                      if (!_loading && _packages.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 10),
                            child: Text(
                              "${_packages.length}${_hasMore ? "+" : ""} ${t(lang, "packages.title").toLowerCase()}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface.withOpacity(0.40),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),

                      // ── Skeletons ───────────────────────────────────
                      if (_loading && _packages.isEmpty)
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _PackageSkeleton(index: i),
                              ),
                              childCount: 3,
                            ),
                          ),
                        ),

                      // ── Package cards ───────────────────────────────
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final showLoader =
                                  _loading && _packages.isNotEmpty;
                              if (index >= _packages.length) {
                                return showLoader
                                    ? Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        child: _PackageSkeleton(index: index),
                                      )
                                    : const SizedBox.shrink();
                              }
                              final p = _packages[index];
                              return _AnimatedListItem(
                                index: index,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _PackageCard(
                                    pkg: p,
                                    lang: lang,
                                    scheme: scheme,
                                    isTablet: isTablet,
                                    isDark: isDark,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      AppRoutes.tripPackageDetails,
                                      arguments: p.id,
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount:
                                _packages.length +
                                ((_loading && _packages.isNotEmpty) ? 1 : 0),
                          ),
                        ),
                      ),

                      // ── Error ───────────────────────────────────────
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

                      // ── Empty ───────────────────────────────────────
                      if (!_loading && _packages.isEmpty && _error == null)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyState(lang: lang, scheme: scheme),
                        ),

                      const SliverToBoxAdapter(child: SizedBox(height: 90)),
                    ],
                  ),
                ),

                // ── Floating search bar (appears after scroll) ────────
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  top: titleT >= 1.0 ? 0 : -72,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: titleT < 1.0,
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          color: scheme.surface.withOpacity(
                            isDark ? 0.88 : 0.93,
                          ),
                          padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 10),
                          child: _PremiumSearchBar(
                            controller: _searchCtrl,
                            hintText: t(lang, "packages.search_hint"),
                            onChanged: _onSearchChanged,
                            onClear: () {
                              _searchCtrl.clear();
                              _onSearchChanged("");
                            },
                            isDark: isDark,
                            scheme: scheme,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Back to top ───────────────────────────────────────
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
      duration: const Duration(milliseconds: 480),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    final delay = Duration(milliseconds: (widget.index * 65).clamp(0, 300));
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
   PACKAGE CARD
───────────────────────────────────────────────────────────────────────────── */

class _PackageCard extends StatefulWidget {
  final _Package pkg;
  final String lang;
  final ColorScheme scheme;
  final bool isTablet;
  final bool isDark;
  final VoidCallback onTap;

  const _PackageCard({
    required this.pkg,
    required this.lang,
    required this.scheme,
    required this.isTablet,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<_PackageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _pressScale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _pressScale = Tween<double>(
      begin: 1.0,
      end: 0.975,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.isTablet ? 28 : 24);
    final h = widget.isTablet ? 246.0 : 224.0;
    final title = (widget.pkg.title?.trim().isNotEmpty ?? false)
        ? widget.pkg.title!.trim()
        : t(widget.lang, "packages.title");
    final subtitle = (widget.pkg.subtitle?.trim().isNotEmpty ?? false)
        ? widget.pkg.subtitle!.trim()
        : "";

    return ScaleTransition(
      scale: _pressScale,
      child: GestureDetector(
        onTapDown: (_) {
          _pressCtrl.forward();
          setState(() => _pressed = true);
        },
        onTapUp: (_) {
          _pressCtrl.reverse();
          setState(() => _pressed = false);
        },
        onTapCancel: () {
          _pressCtrl.reverse();
          setState(() => _pressed = false);
        },
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: radius,
          child: SizedBox(
            height: h,
            child: Stack(
              children: [
                // ── Image ─────────────────────────────────────────────
                Positioned.fill(
                  child: _CardImage(
                    url: widget.pkg.imageUrl,
                    scheme: widget.scheme,
                  ),
                ),

                // ── Cinematic gradient ────────────────────────────────
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.38, 1.0],
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.74),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Top-left ambient ──────────────────────────────────
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
                        color: Colors.white.withOpacity(
                          widget.isDark ? 0.10 : 0.14,
                        ),
                        width: 1,
                      ),
                    ),
                  ),
                ),

                // ── Duration badge (top-right) ────────────────────────
                if (widget.pkg.durationDays > 0)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: _DurationBadge(
                      days: widget.pkg.durationDays,
                      lang: widget.lang,
                    ),
                  ),

                // ── Bottom glass footer ───────────────────────────────
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: _GlassFooter(
                    isDark: widget.isDark,
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
                                  fontSize: widget.isTablet ? 16.5 : 15,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                  height: 1.1,
                                ),
                              ),
                              if (subtitle.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Text(
                                  subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: widget.isTablet ? 12 : 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.72),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Arrow CTA
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOutCubic,
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(
                              _pressed ? 0.22 : 0.14,
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.20),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
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
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────────────
   CARD IMAGE
───────────────────────────────────────────────────────────────────────────── */

class _CardImage extends StatelessWidget {
  final String? url;
  final ColorScheme scheme;
  const _CardImage({required this.url, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return AppCachedImage(
      imageUrl: url,
      fit: BoxFit.cover,
      memCacheWidth: 1200,
      memCacheHeight: 900,
      maxWidthDiskCache: 1600,
      maxHeightDiskCache: 1200,
      placeholderBuilder: (_) => _Placeholder(scheme: scheme),
      errorBuilder: (_) => _Placeholder(scheme: scheme),
    );
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
            scheme.surfaceVariant.withOpacity(0.80),
            scheme.surfaceVariant.withOpacity(0.50),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.landscape_outlined,
          size: 44,
          color: scheme.onSurfaceVariant.withOpacity(0.22),
        ),
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────────────
   DURATION BADGE
───────────────────────────────────────────────────────────────────────────── */

class _DurationBadge extends StatelessWidget {
  final int days;
  final String lang;
  const _DurationBadge({required this.days, required this.lang});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.30),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 12,
                color: Colors.white.withOpacity(0.85),
              ),
              const SizedBox(width: 5),
              Text(
                "$days ${t(lang, "packages.days")}",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withOpacity(0.95),
                  letterSpacing: 0.1,
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
   GLASS FOOTER
───────────────────────────────────────────────────────────────────────────── */

class _GlassFooter extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _GlassFooter({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
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

/* ─────────────────────────────────────────────────────────────────────────────
   SKELETON (shimmer)
───────────────────────────────────────────────────────────────────────────── */

class _PackageSkeleton extends StatefulWidget {
  final int index;
  const _PackageSkeleton({required this.index});

  @override
  State<_PackageSkeleton> createState() => _PackageSkeletonState();
}

class _PackageSkeletonState extends State<_PackageSkeleton>
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
    final h = isTablet ? 246.0 : 224.0;

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: radius,
          child: SizedBox(
            height: h,
            child: Stack(
              children: [
                // Shimmer base
                Positioned.fill(
                  child: Container(
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
                ),

                // Vignette
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.03),
                          Colors.black.withOpacity(0.18),
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
                        color: scheme.onSurface.withOpacity(0.07),
                      ),
                    ),
                  ),
                ),

                // Top-right duration badge placeholder
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    width: 80,
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
                            color: Colors.white.withOpacity(0.11),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    height: 14,
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(right: 60),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.13),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 11,
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(right: 100),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.09),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.09),
                                ),
                              ),
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
  final ColorScheme scheme;
  const _EmptyState({required this.lang, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.luggage_outlined,
            size: 48,
            color: scheme.onSurface.withOpacity(0.20),
          ),
          const SizedBox(height: 14),
          Text(
            t(lang, "packages.empty"),
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
   DATA MODEL
───────────────────────────────────────────────────────────────────────────── */

class _Package {
  final String id;
  final String? title;
  final String? subtitle;
  final String? imageUrl;
  final int durationDays;

  _Package({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.durationDays,
  });

  static _Package fromJson(Map<String, dynamic> json) {
    return _Package(
      id: json["id"]?.toString() ?? "",
      title: json["title"] as String? ?? json["name"] as String?,
      subtitle: json["location"] as String? ?? json["description"] as String?,
      imageUrl:
          (json["cover_url"] ?? json["image"] ?? json["cover_image"])
              as String?,
      durationDays: (json["duration_days"] as num?)?.toInt() ?? 0,
    );
  }
}
