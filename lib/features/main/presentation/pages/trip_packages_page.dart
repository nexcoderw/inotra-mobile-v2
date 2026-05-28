import "dart:async";
import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;
import "package:provider/provider.dart";

import "../../../../core/config/api.dart";
import "../../../../core/config/app_routes.dart";
import "../../../../core/constants/api/package_endpoints.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../core/services/notification_service.dart";
import "../../../../core/widgets/app_cached_image.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/discovery_search_bar.dart";
import "../widgets/inotra_standalone_header.dart";

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

  final List<_Package> _packages = [];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  int _requestSerial = 0;
  int? _totalCount;
  String _query = "";
  String? _error;
  Timer? _searchDebounce;

  static const int _pageSize = 10;

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
  }

  Future<void> _fetchPage({
    required bool reset,
    bool forceRefresh = false,
  }) async {
    if (_loading && !reset) return;
    if (forceRefresh) {
      // Kept for compatibility with existing refresh/retry handlers.
    }
    final requestId = ++_requestSerial;
    setState(() {
      _loading = true;
      if (reset) {
        _page = 1;
        _hasMore = true;
        _totalCount = null;
        _packages.clear();
      }
      _error = null;
    });

    try {
      final uri = Api.url(
        "${PackageEndpoints.list}?page=$_page&page_size=$_pageSize"
        "${_query.isNotEmpty ? "&search=${Uri.encodeQueryComponent(_query)}" : ""}",
      );
      final resp = await http.get(uri);
      if (!mounted || requestId != _requestSerial) return;
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body);
        final results =
            (decoded is Map ? decoded["results"] : decoded) as List? ?? [];
        final items = results
            .whereType<Map<String, dynamic>>()
            .map(_Package.fromJson)
            .toList();
        setState(() {
          if (decoded is Map && decoded["count"] is num) {
            _totalCount = (decoded["count"] as num).toInt();
          }
          final existing = _packages.map((e) => e.dedupeKey).toSet();
          final unique = items
              .where((e) => !existing.contains(e.dedupeKey))
              .toList();
          _packages.addAll(unique);
          _hasMore = items.length >= _pageSize;
          if (_hasMore) _page += 1;
        });
      } else {
        setState(() => _error = "Status ${resp.statusCode}");
      }
    } catch (e) {
      if (!mounted || requestId != _requestSerial) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted && requestId == _requestSerial) {
        setState(() => _loading = false);
      }
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
        _requestSerial++;
        setState(() {
          _packages.clear();
          _hasMore = false;
          _totalCount = null;
          _error = null;
          _loading = false;
        });
        return;
      }
      _fetchPage(reset: true);
    });
  }

  String get _countLabel {
    if (_totalCount != null) return "${_packages.length}/$_totalCount";
    return "${_packages.length}${_hasMore ? "+" : ""}";
  }

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    final w = MediaQuery.sizeOf(context).width;
    final isTablet = w >= 700;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = isTablet ? 24.0 : 18.0;
    final session = AuthSession.instance.value;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: InotraStandaloneHeader(
        title: t(lang, "packages.title"),
        displayName: session.displayName,
        isAuthenticated: session.isAuthenticated,
        unreadCount: context.watch<NotificationService>().unreadCount,
        onBackTap: () => Navigator.maybePop(context),
        onNotificationsTap: () => Navigator.pushNamed(
          context,
          session.isAuthenticated ? AppRoutes.notifications : AppRoutes.login,
        ),
        onProfileTap: () => Navigator.pushNamed(
          context,
          session.isAuthenticated ? AppRoutes.profile : AppRoutes.login,
        ),
      ),
      body: SafeArea(
        top: false,
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
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _PackagesHeaderDelegate(
                          isTablet: isTablet,
                          isDark: isDark,
                          scheme: scheme,
                          title: t(lang, "packages.title"),
                          countLabel: _countLabel,
                          searchCtrl: _searchCtrl,
                          hintText: t(lang, "packages.search_hint"),
                          onSearchChanged: _onSearchChanged,
                          onClear: () {
                            _searchCtrl.clear();
                            _onSearchChanged("");
                          },
                          showCount:
                              !_loading &&
                              (_packages.isNotEmpty || _query.isNotEmpty),
                        ),
                      ),

                      // ── Skeletons ───────────────────────────────────
                      if (_loading && _packages.isEmpty)
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
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
                        padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
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
   PACKAGES HEADER — title, count, reusable search
───────────────────────────────────────────────────────────────────────────── */

class _PackagesHeaderDelegate extends SliverPersistentHeaderDelegate {
  final bool isTablet;
  final bool isDark;
  final ColorScheme scheme;
  final String title;
  final String countLabel;
  final TextEditingController searchCtrl;
  final String hintText;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClear;
  final bool showCount;

  const _PackagesHeaderDelegate({
    required this.isTablet,
    required this.isDark,
    required this.scheme,
    required this.title,
    required this.countLabel,
    required this.searchCtrl,
    required this.hintText,
    required this.onSearchChanged,
    required this.onClear,
    required this.showCount,
  });

  @override
  double get minExtent => 78.0;

  @override
  double get maxExtent => 154.0;

  @override
  bool shouldRebuild(_PackagesHeaderDelegate old) =>
      isTablet != old.isTablet ||
      isDark != old.isDark ||
      scheme != old.scheme ||
      title != old.title ||
      countLabel != old.countLabel ||
      searchCtrl.text != old.searchCtrl.text ||
      hintText != old.hintText ||
      showCount != old.showCount;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = maxExtent - minExtent;
    final shrinkT = range > 0 ? (shrinkOffset / range).clamp(0.0, 1.0) : 1.0;
    final hPad = isTablet ? 24.0 : 18.0;
    final titleHeight = (44.0 * (1.0 - shrinkT)).clamp(0.0, 44.0);

    return SizedBox.expand(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: scheme.surface.withValues(alpha: isDark ? 0.86 : 0.94),
            padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: titleHeight,
                  child: AnimatedOpacity(
                    duration: Duration.zero,
                    opacity: (1.0 - shrinkT * 1.5).clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, -shrinkT * 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: (30 - shrinkT * 6).clamp(24.0, 30.0),
                                fontWeight: FontWeight.w900,
                                color: scheme.onSurface,
                                height: 1.05,
                              ),
                            ),
                          ),
                          if (showCount) ...[
                            const SizedBox(width: 10),
                            _CountBadge(label: countLabel, scheme: scheme),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: (12.0 * (1.0 - shrinkT)).clamp(0.0, 12.0)),
                DiscoverySearchBar(
                  controller: searchCtrl,
                  hintText: hintText,
                  onChanged: onSearchChanged,
                  onClear: onClear,
                  scheme: scheme,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String label;
  final ColorScheme scheme;

  const _CountBadge({required this.label, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 138),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: scheme.primary,
          height: 1,
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
    final radius = BorderRadius.circular(widget.isTablet ? 30 : 26);
    final scheme = widget.scheme;
    final title = (widget.pkg.title?.trim().isNotEmpty ?? false)
        ? widget.pkg.title!.trim()
        : t(widget.lang, "packages.title");
    final hasDuration = widget.pkg.durationDays > 0;
    final hasActivities = widget.pkg.activitiesCount > 0;

    return ScaleTransition(
      scale: _pressScale,
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp: (_) => _pressCtrl.reverse(),
        onTapCancel: () => _pressCtrl.reverse(),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.34
                      : 0.18,
                ),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: AspectRatio(
            aspectRatio: widget.isTablet ? 1.18 : 0.82,
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _CardImage(url: widget.pkg.imageUrl, scheme: scheme),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.34),
                          width: 1,
                        ),
                        borderRadius: radius,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.02),
                            Colors.black.withValues(alpha: 0.10),
                            Colors.black.withValues(alpha: 0.72),
                          ],
                          stops: const [0.0, 0.48, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.32),
                        ),
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: widget.isTablet ? 25 : 21,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.04,
                          ),
                        ),
                        if (hasDuration || hasActivities) ...[
                          const SizedBox(height: 9),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (hasDuration)
                                _MetaPill(
                                  icon: HugeIcons.strokeRoundedClock01,
                                  label:
                                      "${widget.pkg.durationDays} ${t(widget.lang, "packages.days")}",
                                  isOnImage: true,
                                ),
                              if (hasActivities)
                                _MetaPill(
                                  icon: HugeIcons.strokeRoundedRoute03,
                                  label:
                                      "${widget.pkg.activitiesCount} ${t(widget.lang, "packages.activities")}",
                                  isOnImage: true,
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.58),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.09),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Center(
                                  child: Text(
                                    "See more",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 46,
                                height: 46,
                                margin: const EdgeInsets.only(right: 5),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 28,
                                  color: Colors.black,
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

class _MetaPill extends StatelessWidget {
  final dynamic icon;
  final String label;
  final bool isOnImage;

  const _MetaPill({
    required this.icon,
    required this.label,
    this.isOnImage = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOnImage
            ? Colors.white.withValues(alpha: 0.18)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isOnImage
              ? Colors.white.withValues(alpha: 0.22)
              : scheme.outlineVariant.withValues(alpha: 0.40),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: icon,
            size: 12,
            strokeWidth: 2,
            color: isOnImage ? Colors.white : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: isOnImage ? Colors.white : scheme.onSurfaceVariant,
              height: 1,
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
    final radius = BorderRadius.circular(isTablet ? 30 : 26);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.24
                  : 0.10,
            ),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
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
          child: AspectRatio(
            aspectRatio: isTablet ? 1.18 : 0.82,
            child: Stack(
              children: [
                Positioned.fill(
                  child: _ShimmerBox(controller: _shimmer, scheme: scheme),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.00),
                          Colors.black.withValues(alpha: 0.12),
                          Colors.black.withValues(alpha: 0.48),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBar(
                        controller: _shimmer,
                        scheme: scheme,
                        height: 18,
                        widthFraction: 0.68,
                        isDarkSurface: true,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _ShimmerPill(controller: _shimmer, scheme: scheme),
                          const SizedBox(width: 8),
                          _ShimmerPill(controller: _shimmer, scheme: scheme),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.34),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ShimmerBar(
                              controller: _shimmer,
                              scheme: scheme,
                              height: 12,
                              widthFraction: 0.30,
                              isDarkSurface: true,
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
  final bool isDarkSurface;

  const _ShimmerBar({
    required this.controller,
    required this.scheme,
    required this.height,
    required this.widthFraction,
    this.isDarkSurface = false,
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
                  (isDarkSurface
                          ? Colors.white
                          : scheme.surfaceContainerHighest)
                      .withValues(alpha: isDarkSurface ? 0.12 : 0.50),
                  (isDarkSurface
                          ? Colors.white
                          : scheme.surfaceContainerHighest)
                      .withValues(alpha: isDarkSurface ? 0.28 : 0.80),
                  (isDarkSurface
                          ? Colors.white
                          : scheme.surfaceContainerHighest)
                      .withValues(alpha: isDarkSurface ? 0.12 : 0.50),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShimmerPill extends StatelessWidget {
  final AnimationController controller;
  final ColorScheme scheme;

  const _ShimmerPill({required this.controller, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: _ShimmerBar(
        controller: controller,
        scheme: scheme,
        height: 24,
        widthFraction: 1,
        isDarkSurface: true,
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

  String get dedupeKey =>
      id.isNotEmpty ? id : "${title ?? ""}|${subtitle ?? ""}|${imageUrl ?? ""}";

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
