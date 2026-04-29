import "dart:async";
import "dart:convert";
import "dart:math" as math;
import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;

import "../../../../core/config/api.dart";
import "../../../../core/config/app_routes.dart";
import "../../../../core/constants/api/package_endpoints.dart";
import "../../../../core/observers/audit_route_observer.dart";
import "../../../../core/services/audit_service.dart";
import "../../../../core/widgets/app_cached_image.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/listing_image_preview.dart";
import "../widgets/trip_packages/package_activities_tab.dart";
import "../widgets/trip_packages/package_gallery_tab.dart";
import "../widgets/trip_packages/package_models.dart";
import "../widgets/trip_packages/package_overview_tab.dart";

/* ─────────────────────────────────────────────────────────────────────────────
   PAGE
───────────────────────────────────────────────────────────────────────────── */

class TripPackageDetailsPage extends StatefulWidget {
  final String? packageId;
  const TripPackageDetailsPage({super.key, this.packageId});

  @override
  State<TripPackageDetailsPage> createState() => _TripPackageDetailsPageState();
}

class _TripPackageDetailsPageState extends State<TripPackageDetailsPage> {
  bool _loading = true;
  String? _error;
  PackageDetailData? _package;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch({bool forceRefresh = false}) async {
    if (forceRefresh) {
      // kept for retry handlers
    }
    final id =
        widget.packageId ??
        ModalRoute.of(context)?.settings.arguments as String?;
    if (id == null || id.isEmpty) {
      final langNow = currentLangSync();
      setState(() {
        _loading = false;
        _error = t(langNow, "common.coming_soon");
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Api.url(PackageEndpoints.detail(id));
      final resp = await http.get(uri, headers: {"Accept": "application/json"});
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        _package = PackageDetailData.fromJson(decoded);
        AuditService.instance.enrichEntityContext(
          routeName: AppRoutes.tripPackageDetails,
          entityType: "PACKAGE",
          entityId: _package!.id,
          entityLabel: _package!.title,
        );
      } else {
        _error = "Status ${resp.statusCode}";
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lang = currentLangSync();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          top: false,
          child: _loading
              ? const _PackageDetailsSkeleton()
              : (_error != null || _package == null)
              ? _ErrorState(
                  message: _error ?? t(lang, "common.coming_soon"),
                  onRetry: () => _fetch(forceRefresh: true),
                )
              : Stack(
                  children: [
                    Positioned.fill(
                      child: _HeroPager(images: _heroImageUrls(_package!)),
                    ),
                    Positioned(
                      left: 16,
                      top: MediaQuery.of(context).padding.top + 14,
                      child: _RoundIconButton(
                        icon: HugeIcons.strokeRoundedArrowLeft01,
                        onTap: () => Navigator.maybePop(context),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: _DetailsSheet(pkg: _package!, lang: lang),
                    ),
                  ],
                ),
        ),
        bottomNavigationBar: (_package != null && !_loading && _error == null)
            ? SafeArea(
                minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _BookCTAButton(
                  label: _package!.instantConfirmationAvailable
                      ? t(lang, "trips.book_now")
                      : t(lang, "trips.inquire"),
                  onTap: () {
                    // Booking flow integration goes here.
                  },
                ),
              )
            : null,
      ),
    );
  }
}

List<String> _heroImageUrls(PackageDetailData pkg) {
  final urls = <String>{};
  final ordered = <String>[];

  void add(String? url) {
    if (url == null) return;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    if (urls.add(trimmed)) ordered.add(trimmed);
  }

  add(pkg.coverUrl);
  for (final item in pkg.images) {
    add(item.url);
  }
  for (final item in pkg.gallery) {
    add(item.url);
  }
  return ordered;
}

/* ─────────────────────────────────────────────────────────────────────────────
   HERO PAGER — auto-rotating, dot indicators, tap to preview
───────────────────────────────────────────────────────────────────────────── */

class _HeroPager extends StatefulWidget {
  final List<String> images;
  const _HeroPager({required this.images});

  @override
  State<_HeroPager> createState() => _HeroPagerState();
}

class _HeroPagerState extends State<_HeroPager>
    with WidgetsBindingObserver, RouteAware {
  int _index = 0;
  late final PageController _pageCtrl;
  Timer? _auto;
  ModalRoute<dynamic>? _route;
  bool _isAppInForeground = true;
  bool _isRouteVisible = true;

  bool get _canAutoRotate =>
      _isAppInForeground && _isRouteVisible && widget.images.length > 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageCtrl = PageController();
    _syncAutoRotation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route == null || identical(route, _route)) return;
    AuditRouteObserver.instance.unsubscribe(this);
    _route = route;
    AuditRouteObserver.instance.subscribe(this, route as dynamic);
    _isRouteVisible = route.isCurrent;
    _syncAutoRotation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppInForeground = state == AppLifecycleState.resumed;
    _syncAutoRotation();
  }

  void _startAuto() {
    _auto?.cancel();
    if (!_canAutoRotate) {
      _auto = null;
      return;
    }
    _auto = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_canAutoRotate) return;
      final total = widget.images.isEmpty ? 1 : widget.images.length;
      if (total <= 1) return;
      final next = (_index + 1) % total;
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _syncAutoRotation() {
    if (_canAutoRotate) {
      _startAuto();
      return;
    }
    _auto?.cancel();
    _auto = null;
  }

  @override
  void didPush() {
    _isRouteVisible = true;
    _syncAutoRotation();
  }

  @override
  void didPopNext() {
    _isRouteVisible = true;
    _syncAutoRotation();
  }

  @override
  void didPushNext() {
    _isRouteVisible = false;
    _syncAutoRotation();
  }

  @override
  void didPop() {
    _isRouteVisible = false;
    _syncAutoRotation();
  }

  void _openPreview(BuildContext context, List<String> imgs) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => ListingImagePreview(images: imgs, initialIndex: _index),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AuditRouteObserver.instance.unsubscribe(this);
    _auto?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final imgs = widget.images.isNotEmpty ? widget.images : [""];
    final media = MediaQuery.of(context);
    final topPad = media.padding.top;
    final heroHeight = media.size.height * 0.52;

    return Stack(
      children: [
        Container(color: scheme.surface),
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: heroHeight,
            width: double.infinity,
            child: GestureDetector(
              onTap: () => _openPreview(context, imgs),
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: imgs.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final url = imgs[i].trim();
                  if (url.isEmpty) return _HeroPlaceholder(scheme: scheme);
                  return AppCachedImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    memCacheWidth: 1800,
                    memCacheHeight: 1400,
                    maxWidthDiskCache: 2400,
                    maxHeightDiskCache: 1800,
                    placeholderBuilder: (_) => _HeroPlaceholder(scheme: scheme),
                    errorBuilder: (_) => _HeroPlaceholder(scheme: scheme),
                  );
                },
              ),
            ),
          ),
        ),

        // Soft bottom fade — functional, helps the sheet read against the image
        Positioned(
          left: 0,
          right: 0,
          top: heroHeight - 180,
          height: 180,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.18),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Dot indicators
        if (imgs.length > 1)
          Positioned(
            left: 0,
            right: 0,
            top: topPad + 64,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  imgs.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: _index == i ? 18 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: _index == i
                          ? Colors.white.withValues(alpha: 0.95)
                          : Colors.white.withValues(alpha: 0.40),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  final ColorScheme scheme;
  const _HeroPlaceholder({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedImageNotFound01,
          color: scheme.onSurface.withValues(alpha: 0.35),
          size: 34,
        ),
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────────────
   DETAILS SHEET — title, meta row, tab bar, tab content
───────────────────────────────────────────────────────────────────────────── */

class _DetailsSheet extends StatelessWidget {
  final PackageDetailData pkg;
  final String lang;
  const _DetailsSheet({required this.pkg, required this.lang});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final isTablet = media.size.width >= 700;
    final sheetHeight = media.size.height * (isTablet ? 0.60 : 0.62);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, t, _) {
        return Transform.translate(
          offset: Offset(0, (1 - t) * 24),
          child: Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: SizedBox(
              height: sheetHeight,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.92),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 26,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                    child: _SheetBody(
                      pkg: pkg,
                      lang: lang,
                      scheme: scheme,
                      isTablet: isTablet,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SheetBody extends StatelessWidget {
  final PackageDetailData pkg;
  final String lang;
  final ColorScheme scheme;
  final bool isTablet;

  const _SheetBody({
    required this.pkg,
    required this.lang,
    required this.scheme,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = isTablet ? 24.0 : 16.0;
    final priceLabel = _formatPrice(pkg);
    final routeLabel = pkg.routeLabel.trim();
    final durationDays = pkg.durationDays ?? pkg.resolvedDaysCount;

    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 44,
          height: 5,
          decoration: BoxDecoration(
            color: scheme.onSurface.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 14),

        // Title + duration pill
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  pkg.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isTablet ? 22 : 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    height: 1.05,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if (durationDays > 0) ...[
                const SizedBox(width: 10),
                _DurationChip(days: durationDays, lang: lang, scheme: scheme),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Route + price row
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Row(
            children: [
              if (routeLabel.isNotEmpty)
                Expanded(
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedMapsLocation02,
                        size: 16,
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          routeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface.withValues(alpha: 0.62),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Spacer(),
              if (priceLabel != null) ...[
                const SizedBox(width: 10),
                _PriceChip(label: priceLabel, scheme: scheme),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Pill tab bar
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: _PillTabBar(
            labels: [
              t(lang, "trips.tab_overview"),
              t(lang, "trips.tab_itinerary"),
              t(lang, "trips.tab_gallery"),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Tab content
        Expanded(
          child: TabBarView(
            physics: const BouncingScrollPhysics(),
            children: [
              PackageOverviewTab(pkg: pkg),
              PackageActivitiesTab(
                days: pkg.days,
                fallbackActivities: pkg.activities,
              ),
              PackageGalleryTab(images: _galleryImages(pkg)),
            ],
          ),
        ),
      ],
    );
  }
}

List<PackageImageItem> _galleryImages(PackageDetailData pkg) {
  final seen = <String>{};
  final merged = <PackageImageItem>[];
  for (final list in [pkg.gallery, pkg.images]) {
    for (final item in list) {
      if (item.url.trim().isEmpty) continue;
      if (seen.add(item.url)) merged.add(item);
    }
  }
  return merged;
}

String? _formatPrice(PackageDetailData pkg) {
  final raw = pkg.priceAmount?.trim();
  if (raw == null || raw.isEmpty) return null;
  final n = num.tryParse(raw);
  if (n == null) return null;
  final cur = (pkg.priceCurrency ?? "USD").toUpperCase();
  final formatted = n is int || n == n.toInt()
      ? n.toInt().toString()
      : n.toStringAsFixed(2);
  return "$cur $formatted";
}

/* ─────────────────────────────────────────────────────────────────────────────
   PILL TAB BAR — same look as listing details
───────────────────────────────────────────────────────────────────────────── */

class _PillTabBar extends StatelessWidget {
  final List<String> labels;
  const _PillTabBar({required this.labels});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: TabBar(
        isScrollable: true,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurface.withValues(alpha: 0.55),
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        tabAlignment: TabAlignment.start,
        tabs: labels
            .map(
              (label) => Tab(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(label),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────────────
   CHIPS
───────────────────────────────────────────────────────────────────────────── */

class _DurationChip extends StatelessWidget {
  final int days;
  final String lang;
  final ColorScheme scheme;
  const _DurationChip({
    required this.days,
    required this.lang,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.50),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedClock01,
            size: 12,
            color: scheme.onSurface.withValues(alpha: 0.75),
          ),
          const SizedBox(width: 5),
          Text(
            "$days ${t(lang, "packages.days")}",
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface.withValues(alpha: 0.85),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String label;
  final ColorScheme scheme;
  const _PriceChip({required this.label, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: scheme.primary,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────────────
   ROUND ICON BUTTON — back button (same look as listing details)
───────────────────────────────────────────────────────────────────────────── */

class _RoundIconButton extends StatelessWidget {
  final dynamic icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface.withValues(alpha: 0.86),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: HugeIcon(
            icon: icon,
            size: 22,
            color: scheme.onSurface.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────────────
   STICKY BOOK CTA — press scale animation
───────────────────────────────────────────────────────────────────────────── */

class _BookCTAButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  const _BookCTAButton({required this.label, required this.onTap});

  @override
  State<_BookCTAButton> createState() => _BookCTAButtonState();
}

class _BookCTAButtonState extends State<_BookCTAButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) => _ctrl.reverse(),
        onTapCancel: () => _ctrl.reverse(),
        onTap: widget.onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: scheme.onPrimary,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(width: 8),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 18,
                color: scheme.onPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────────────
   ERROR + SKELETON
───────────────────────────────────────────────────────────────────────────── */

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lang = currentLangSync();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.errorContainer.withValues(alpha: 0.40),
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                color: scheme.error,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.75),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                backgroundColor: scheme.primary.withValues(alpha: 0.10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: Text(
                t(lang, "common.try_again"),
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageDetailsSkeleton extends StatefulWidget {
  const _PackageDetailsSkeleton();

  @override
  State<_PackageDetailsSkeleton> createState() =>
      _PackageDetailsSkeletonState();
}

class _PackageDetailsSkeletonState extends State<_PackageDetailsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

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
    final media = MediaQuery.of(context);
    final heroHeight = media.size.height * 0.52;
    final sheetHeight = media.size.height * 0.62;

    return Stack(
      children: [
        // Hero shimmer
        Positioned.fill(
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: heroHeight,
              width: double.infinity,
              child: _ShimmerBox(controller: _shimmer, scheme: scheme),
            ),
          ),
        ),

        // Back button placeholder
        Positioned(
          left: 16,
          top: media.padding.top + 14,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.86),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // Sheet shimmer
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: sheetHeight,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _ShimmerBar(
                  controller: _shimmer,
                  scheme: scheme,
                  height: 22,
                  widthFraction: 0.7,
                ),
                const SizedBox(height: 12),
                _ShimmerBar(
                  controller: _shimmer,
                  scheme: scheme,
                  height: 14,
                  widthFraction: 0.5,
                ),
                const SizedBox(height: 22),
                _ShimmerBar(
                  controller: _shimmer,
                  scheme: scheme,
                  height: 40,
                  widthFraction: 0.85,
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: Column(
                    children: List.generate(
                      4,
                      (_) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ShimmerBar(
                          controller: _shimmer,
                          scheme: scheme,
                          height: 16,
                          widthFraction: 0.95,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
            width: math.max(40, constraints.maxWidth * widthFraction),
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
