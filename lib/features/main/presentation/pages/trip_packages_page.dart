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
  final ValueNotifier<bool> _showBackToTop = ValueNotifier(false);
  final ValueNotifier<bool> _showFloatingSearch = ValueNotifier(false);

  final List<_Package> _packages = [];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  String _query = "";
  String? _error;
  Timer? _searchDebounce;

  // Entrance animation
  late AnimationController _entranceCtrl;
  late Animation<double> _entranceFade;
  late Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOut,
    );
    _entranceSlide =
        Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(
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
    _showBackToTop.dispose();
    _showFloatingSearch.dispose();
    _searchDebounce?.cancel();
    _entranceCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async =>
      _fetchPage(reset: true, forceRefresh: true);

  void _onScroll() {
    final px = _scrollCtrl.position.pixels;
    if (px >= _scrollCtrl.position.maxScrollExtent - 200 &&
        !_loading &&
        _hasMore) {
      _fetchPage(reset: false);
    }

    final showBackToTop = px > 300;
    if (showBackToTop != _showBackToTop.value) {
      _showBackToTop.value = showBackToTop;
    }

    final showFloatingSearch = px >= 72;
    if (showFloatingSearch != _showFloatingSearch.value) {
      _showFloatingSearch.value = showFloatingSearch;
    }
  }

  Future<void> _fetchPage({
    required bool reset,
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      // Kept for compatibility with existing refresh/retry handlers.
    }
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
        "${PackageEndpoints.list}?page=$_page&page_size=10"
        "${_query.isNotEmpty ? "&search=$_query" : ""}",
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
    final w = MediaQuery.sizeOf(context).width;
    final isTablet = w >= 700;
    final hPad = isTablet ? 24.0 : 18.0;

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
                          child: _SearchBar(
                            controller: _searchCtrl,
                            hintText: t(lang, "packages.search_hint"),
                            onChanged: _onSearchChanged,
                            onClear: () {
                              _searchCtrl.clear();
                              _onSearchChanged("");
                            },
                            scheme: scheme,
                          ),
                        ),
                      ),

                      // ── Result count label ──────────────────────────
                      if (!_loading && _packages.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 12),
                            child: Text(
                              "${_packages.length}${_hasMore ? "+" : ""} ${t(lang, "packages.title").toLowerCase()}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface.withValues(alpha: 0.50),
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
                                padding: const EdgeInsets.only(bottom: 14),
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
                                          bottom: 14,
                                        ),
                                        child: _PackageSkeleton(index: index),
                                      )
                                    : const SizedBox.shrink();
                              }
                              final p = _packages[index];
                              return _AnimatedListItem(
                                index: index,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _PackageCard(
                                    pkg: p,
                                    lang: lang,
                                    scheme: scheme,
                                    isTablet: isTablet,
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
                              onRetry: () =>
                                  _fetchPage(reset: true, forceRefresh: true),
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
                ValueListenableBuilder<bool>(
                  valueListenable: _showFloatingSearch,
                  builder: (context, show, child) => AnimatedPositioned(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    top: show ? 0 : -72,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      ignoring: !show,
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            color: scheme.surface.withValues(alpha: 0.92),
                            padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 10),
                            child: _SearchBar(
                              controller: _searchCtrl,
                              hintText: t(lang, "packages.search_hint"),
                              onChanged: _onSearchChanged,
                              onClear: () {
                                _searchCtrl.clear();
                                _onSearchChanged("");
                              },
                              scheme: scheme,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Back to top ───────────────────────────────────────
                ValueListenableBuilder<bool>(
                  valueListenable: _showBackToTop,
                  child: _BackToTopButton(
                    scheme: scheme,
                    onTap: () => _scrollCtrl.animateTo(
                      0,
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  builder: (context, show, child) => AnimatedPositioned(
                    duration: const Duration(milliseconds: 280),
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
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────────────
   ANIMATED LIST ITEM — fade + slight lift, staggered by index
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
      duration: const Duration(milliseconds: 360),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    final delay = Duration(milliseconds: (widget.index * 50).clamp(0, 240));
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
   PACKAGE CARD — image on top, info below, no gradient overlays
───────────────────────────────────────────────────────────────────────────── */

class _PackageCard extends StatefulWidget {
  final _Package pkg;
  final String lang;
  final ColorScheme scheme;
  final bool isTablet;
  final VoidCallback onTap;

  const _PackageCard({
    required this.pkg,
    required this.lang,
    required this.scheme,
    required this.isTablet,
    required this.onTap,
  });

  @override
  State<_PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<_PackageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _pressScale = Tween<double>(
      begin: 1.0,
      end: 0.985,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.isTablet ? 22 : 18);
    final imageRadius = BorderRadius.only(
      topLeft: Radius.circular(widget.isTablet ? 22 : 18),
      topRight: Radius.circular(widget.isTablet ? 22 : 18),
    );
    final scheme = widget.scheme;
    final title = (widget.pkg.title?.trim().isNotEmpty ?? false)
        ? widget.pkg.title!.trim()
        : t(widget.lang, "packages.title");
    final subtitle = (widget.pkg.subtitle?.trim().isNotEmpty ?? false)
        ? widget.pkg.subtitle!.trim()
        : "";

    return ScaleTransition(
      scale: _pressScale,
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp: (_) => _pressCtrl.reverse(),
        onTapCancel: () => _pressCtrl.reverse(),
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: radius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: radius,
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image with duration pill ─────────────────────────
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: imageRadius,
                          child: _CardImage(
                            url: widget.pkg.imageUrl,
                            scheme: scheme,
                          ),
                        ),
                      ),
                      if (widget.pkg.durationDays > 0)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: _DurationPill(
                            days: widget.pkg.durationDays,
                            lang: widget.lang,
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Info section ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                                fontSize: widget.isTablet ? 16 : 15,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                                letterSpacing: -0.2,
                                height: 1.25,
                              ),
                            ),
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: widget.isTablet ? 12.5 : 12,
                                  fontWeight: FontWeight.w500,
                                  color: scheme.onSurfaceVariant.withValues(
                                    alpha: 0.85,
                                  ),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.surface,
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(
                              alpha: 0.45,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: scheme.onSurface.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
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
   CARD IMAGE — plain cached image, no overlays
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
      memCacheHeight: 700,
      maxWidthDiskCache: 1600,
      maxHeightDiskCache: 1000,
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
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.landscape_outlined,
          size: 36,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.30),
        ),
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────────────
   DURATION PILL — solid surface, no gradient
───────────────────────────────────────────────────────────────────────────── */

class _DurationPill extends StatelessWidget {
  final int days;
  final String lang;
  const _DurationPill({required this.days, required this.lang});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.50),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 11,
            color: scheme.onSurface.withValues(alpha: 0.75),
          ),
          const SizedBox(width: 4),
          Text(
            "$days ${t(lang, "packages.days")}",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.85),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────────────
   SKELETON — minimal shimmer (gradient kept here as it IS the animation)
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
      duration: const Duration(milliseconds: 1300),
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
    final radius = BorderRadius.circular(isTablet ? 22 : 18);
    final imageRadius = BorderRadius.only(
      topLeft: Radius.circular(isTablet ? 22 : 18),
      topRight: Radius.circular(isTablet ? 22 : 18),
    );

    return ClipRRect(
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: radius,
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image shimmer
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: imageRadius,
                child: _ShimmerBox(controller: _shimmer, scheme: scheme),
              ),
            ),
            // Info shimmer
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ShimmerBar(
                          controller: _shimmer,
                          scheme: scheme,
                          height: 12,
                          widthFraction: 0.7,
                        ),
                        const SizedBox(height: 8),
                        _ShimmerBar(
                          controller: _shimmer,
                          scheme: scheme,
                          height: 10,
                          widthFraction: 0.5,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.55,
                      ),
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

class _ShimmerBox extends StatelessWidget {
  final AnimationController controller;
  final ColorScheme scheme;
  const _ShimmerBox({required this.controller, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.5 + controller.value * 3, 0),
              end: Alignment(-0.5 + controller.value * 3, 0),
              colors: [
                scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                scheme.surfaceContainerHighest.withValues(alpha: 0.80),
                scheme.surfaceContainerHighest.withValues(alpha: 0.55),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerBar extends StatelessWidget {
  final AnimationController controller;
  final ColorScheme scheme;
  final double height;
  final double widthFraction;

  const _ShimmerBar({
    required this.controller,
    required this.scheme,
    required this.height,
    required this.widthFraction,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Container(
            height: height,
            width: constraints.maxWidth * widthFraction,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                begin: Alignment(-1.5 + controller.value * 3, 0),
                end: Alignment(-0.5 + controller.value * 3, 0),
                colors: [
                  scheme.surfaceContainerHighest.withValues(alpha: 0.50),
                  scheme.surfaceContainerHighest.withValues(alpha: 0.80),
                  scheme.surfaceContainerHighest.withValues(alpha: 0.50),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────────────
   SEARCH BAR — minimal, theme-aware
───────────────────────────────────────────────────────────────────────────── */

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ColorScheme scheme;

  const _SearchBar({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.50),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 13),
          Icon(
            Icons.search_rounded,
            size: 17,
            color: scheme.onSurface.withValues(alpha: 0.50),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface.withValues(alpha: 0.40),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) {
                return const SizedBox.shrink();
              }
              return GestureDetector(
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.onSurface.withValues(alpha: 0.10),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 12,
                      color: scheme.onSurface.withValues(alpha: 0.70),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────────────
   ERROR PANEL — solid surface, no excess decoration
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
        borderRadius: BorderRadius.circular(16),
        color: scheme.errorContainer.withValues(alpha: 0.30),
        border: Border.all(color: scheme.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, color: scheme.error, size: 28),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.error,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              backgroundColor: scheme.error.withValues(alpha: 0.10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: Text(
              retryText,
              style: TextStyle(
                color: scheme.error,
                fontWeight: FontWeight.w600,
                fontSize: 13,
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
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.50),
            ),
            child: Icon(
              Icons.luggage_outlined,
              size: 28,
              color: scheme.onSurface.withValues(alpha: 0.40),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            t(lang, "packages.empty"),
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.55),
              fontWeight: FontWeight.w600,
              fontSize: 13,
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
              color: scheme.primary.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.keyboard_arrow_up_rounded,
            color: scheme.onPrimary,
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
  final int activitiesCount;

  _Package({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.durationDays,
    required this.activitiesCount,
  });

  static _Package fromJson(Map<String, dynamic> json) {
    final route = (json["route_summary"] ?? "").toString().trim();
    final origin = (json["origin_label"] ?? "").toString().trim();
    final destination = (json["destination_label"] ?? "").toString().trim();
    final summary = (json["summary"] ?? json["description"] ?? "")
        .toString()
        .trim();
    final routeLabel = route.isNotEmpty
        ? route
        : (origin.isNotEmpty && destination.isNotEmpty
              ? "$origin -> $destination"
              : "");
    return _Package(
      id: json["id"]?.toString() ?? "",
      title: json["title"] as String? ?? json["name"] as String?,
      subtitle: routeLabel.isNotEmpty ? routeLabel : summary,
      imageUrl:
          (json["cover_url"] ?? json["image"] ?? json["cover_image"])
              as String?,
      durationDays:
          (json["duration_days"] as num?)?.toInt() ??
          (json["days_count"] as num?)?.toInt() ??
          0,
      activitiesCount: (json["activities_count"] as num?)?.toInt() ?? 0,
    );
  }
}
