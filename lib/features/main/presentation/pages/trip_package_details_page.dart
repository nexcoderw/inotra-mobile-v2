import "dart:convert";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;

import "../../../../core/config/api.dart";
import "../../../../core/config/app_routes.dart";
import "../../../../core/constants/api/package_endpoints.dart";
import "../../../../core/services/audit_service.dart";
import "../../../../core/widgets/app_cached_image.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/main_scaffold.dart";
import "../widgets/trip_packages/package_models.dart";
import "../widgets/trip_packages/package_overview_tab.dart";
import "../widgets/trip_packages/package_activities_tab.dart";
import "../widgets/trip_packages/package_gallery_tab.dart";

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
      // Kept for compatibility with retry handlers.
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
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    final pkg = _package;

    return MainScaffold(
      title: t(lang, "trips.details_title"),
      showAppBar: false,
      child: SafeArea(
        child: _loading
            ? const _PackageDetailsSkeleton()
            : (_error != null || pkg == null)
            ? _ErrorState(
                message: _error ?? t(lang, "common.coming_soon"),
                onRetry: () => _fetch(forceRefresh: true),
              )
            : _PackageBody(
                pkg: pkg,
                lang: lang,
                scheme: scheme,
                onBack: () => Navigator.maybePop(context),
                onRefresh: () => _fetch(forceRefresh: true),
              ),
      ),
    );
  }
}

/* ============================================================
   BODY
   ============================================================ */

class _PackageBody extends StatefulWidget {
  final PackageDetailData pkg;
  final String lang;
  final ColorScheme scheme;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const _PackageBody({
    required this.pkg,
    required this.lang,
    required this.scheme,
    required this.onBack,
    required this.onRefresh,
  });

  @override
  State<_PackageBody> createState() => _PackageBodyState();
}

class _PackageBodyState extends State<_PackageBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _heroPage = 0;
  late final PageController _heroCtrl;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _heroCtrl = PageController();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _heroCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pkg = widget.pkg;
    final lang = widget.lang;
    final scheme = widget.scheme;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 700;
    final sidePad = isWide ? 24.0 : 16.0;
    final heroHeight = width <= 360
        ? 356.0
        : width <= 430
        ? 392.0
        : 430.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.surface,
            scheme.surfaceContainerLowest,
            scheme.surface,
          ],
        ),
      ),
      child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(sidePad, 12, sidePad, 0),
              child: _HeroSection(
                pkg: pkg,
                lang: lang,
                scheme: scheme,
                heroPage: _heroPage,
                heroCtrl: _heroCtrl,
                height: heroHeight,
                onPageChanged: (i) => setState(() => _heroPage = i),
                onBack: widget.onBack,
                onRefresh: widget.onRefresh,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(sidePad, 14, sidePad, 18),
              child: _TripCommandPanel(
                pkg: pkg,
                lang: lang,
                scheme: scheme,
                onActivitiesTap: () => _tabs.animateTo(1),
                onGalleryTap: () => _tabs.animateTo(2),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              tabs: [
                t(lang, "trips.overview"),
                t(lang, "trips.activities_title"),
                t(lang, "trips.gallery_title"),
              ],
              controller: _tabs,
              scheme: scheme,
              horizontalPadding: sidePad,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            PackageOverviewTab(pkg: pkg),
            PackageActivitiesTab(
              days: pkg.days,
              fallbackActivities: pkg.flattenedActivities,
            ),
            PackageGalleryTab(images: pkg.allImageItems),
          ],
        ),
      ),
    );
  }
}

/* ============================================================
   HERO SECTION
   ============================================================ */

class _HeroSection extends StatelessWidget {
  final PackageDetailData pkg;
  final String lang;
  final ColorScheme scheme;
  final int heroPage;
  final PageController heroCtrl;
  final double height;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const _HeroSection({
    required this.pkg,
    required this.lang,
    required this.scheme,
    required this.heroPage,
    required this.heroCtrl,
    required this.height,
    required this.onPageChanged,
    required this.onBack,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final images = pkg.allImages;
    final routeLabel = pkg.routeLabel;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: images.isEmpty
                  ? _ImageFallback(scheme: scheme)
                  : PageView.builder(
                      controller: heroCtrl,
                      onPageChanged: onPageChanged,
                      itemCount: images.length,
                      itemBuilder: (_, i) => AppCachedImage(
                        imageUrl: images[i],
                        fit: BoxFit.cover,
                        memCacheWidth: 1500,
                        memCacheHeight: 1200,
                        maxWidthDiskCache: 1800,
                        maxHeightDiskCache: 1400,
                        errorBuilder: (_) => _ImageFallback(scheme: scheme),
                        placeholderBuilder: (_) =>
                            _ImageFallback(scheme: scheme),
                      ),
                    ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.38, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.46),
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  _HeroControl(
                    icon: HugeIcons.strokeRoundedArrowLeft01,
                    onTap: onBack,
                  ),
                  const Spacer(),
                  if (images.length > 1)
                    _HeroBadge(
                      icon: HugeIcons.strokeRoundedImage01,
                      label: "${heroPage + 1}/${images.length}",
                    ),
                  const SizedBox(width: 8),
                  _HeroControl(
                    icon: HugeIcons.strokeRoundedRefresh,
                    onTap: onRefresh,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _StatusBadge(isActive: pkg.isActive, lang: lang),
                      if (pkg.resolvedDaysCount > 0)
                        _HeroBadge(
                          icon: HugeIcons.strokeRoundedClock01,
                          label:
                              "${pkg.resolvedDaysCount} ${pkg.resolvedDaysCount == 1 ? t(lang, "trips.day") : t(lang, "trips.days")}",
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pkg.title.trim().isEmpty
                        ? t(lang, "trips.details_title")
                        : pkg.title.trim(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      height: 1.04,
                      shadows: [
                        Shadow(
                          blurRadius: 18,
                          color: Colors.black54,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  if (routeLabel.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedMapsLocation02,
                          size: 15,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            routeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.84),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (images.length > 1) ...[
                    const SizedBox(height: 14),
                    _PageDots(count: images.length, current: heroPage),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================================================
   TRIP COMMAND PANEL
   ============================================================ */

class _TripCommandPanel extends StatelessWidget {
  final PackageDetailData pkg;
  final String lang;
  final ColorScheme scheme;
  final VoidCallback onActivitiesTap;
  final VoidCallback onGalleryTap;

  const _TripCommandPanel({
    required this.pkg,
    required this.lang,
    required this.scheme,
    required this.onActivitiesTap,
    required this.onGalleryTap,
  });

  @override
  Widget build(BuildContext context) {
    final description = pkg.displayDescription.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SurfacePanel(
          scheme: scheme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MiniMark(scheme: scheme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t(lang, "trips.details_title"),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: scheme.primary,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          description.isEmpty
                              ? t(lang, "banner.subtitle")
                              : description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.55,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 360;
                  final facts = <Widget>[
                    _FactTile(
                      icon: HugeIcons.strokeRoundedClock01,
                      label: t(lang, "trips.duration"),
                      value: pkg.resolvedDaysCount <= 0
                          ? t(lang, "listings.no_data")
                          : "${pkg.resolvedDaysCount} ${pkg.resolvedDaysCount == 1 ? t(lang, "trips.day") : t(lang, "trips.days")}",
                      scheme: scheme,
                    ),
                    _FactTile(
                      icon: HugeIcons.strokeRoundedActivity01,
                      label: t(lang, "trips.activities_title"),
                      value: "${pkg.resolvedActivitiesCount}",
                      scheme: scheme,
                    ),
                    _FactTile(
                      icon: HugeIcons.strokeRoundedImage01,
                      label: t(lang, "trips.gallery_title"),
                      value: "${pkg.allImageItems.length}",
                      scheme: scheme,
                    ),
                  ];

                  if (compact) {
                    return Column(
                      children: [
                        for (int i = 0; i < facts.length; i++) ...[
                          facts[i],
                          if (i < facts.length - 1) const SizedBox(height: 8),
                        ],
                      ],
                    );
                  }

                  return Row(
                    children: [
                      for (int i = 0; i < facts.length; i++) ...[
                        Expanded(child: facts[i]),
                        if (i < facts.length - 1) const SizedBox(width: 8),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _PanelAction(
                      label: t(lang, "trips.activities_title"),
                      icon: HugeIcons.strokeRoundedCalendar02,
                      filled: true,
                      scheme: scheme,
                      onTap: onActivitiesTap,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PanelAction(
                      label: t(lang, "trips.gallery_title"),
                      icon: HugeIcons.strokeRoundedImage01,
                      filled: false,
                      scheme: scheme,
                      onTap: onGalleryTap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* ============================================================
   STICKY TAB BAR DELEGATE
   ============================================================ */

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final List<String> tabs;
  final TabController controller;
  final ColorScheme scheme;
  final double horizontalPadding;

  const _TabBarDelegate({
    required this.tabs,
    required this.controller,
    required this.scheme,
    required this.horizontalPadding,
  });

  @override
  double get minExtent => 70;
  @override
  double get maxExtent => 70;

  @override
  bool shouldRebuild(_TabBarDelegate old) =>
      old.tabs != tabs ||
      old.controller != controller ||
      old.horizontalPadding != horizontalPadding;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: scheme.surface.withValues(alpha: 0.98),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          8,
          horizontalPadding,
          10,
        ),
        child: Container(
          height: 52,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.10)),
          ),
          child: TabBar(
            controller: controller,
            isScrollable: false,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(13),
            ),
            labelColor: scheme.onPrimary,
            unselectedLabelColor: scheme.onSurface.withValues(alpha: 0.58),
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            tabs: tabs.map((label) => Tab(text: label)).toList(),
          ),
        ),
      ),
    );
  }
}

/* ============================================================
   SHARED UI PRIMITIVES
   ============================================================ */

class _SurfacePanel extends StatelessWidget {
  final Widget child;
  final ColorScheme scheme;

  const _SurfacePanel({required this.child, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final isDark = scheme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.055) : scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MiniMark extends StatelessWidget {
  final ColorScheme scheme;

  const _MiniMark({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedRoute01,
          size: 19,
          color: scheme.onPrimary,
        ),
      ),
    );
  }
}

class _FactTile extends StatelessWidget {
  final dynamic icon;
  final String label;
  final String value;
  final ColorScheme scheme;

  const _FactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          HugeIcon(icon: icon, size: 15, color: scheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.50),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelAction extends StatelessWidget {
  final String label;
  final dynamic icon;
  final bool filled;
  final ColorScheme scheme;
  final VoidCallback onTap;

  const _PanelAction({
    required this.label,
    required this.icon,
    required this.filled,
    required this.scheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? scheme.onPrimary : scheme.primary;
    return Material(
      color: filled ? scheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: filled
                  ? scheme.primary
                  : scheme.primary.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(icon: icon, size: 15, color: foreground),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: foreground,
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

class _HeroControl extends StatelessWidget {
  final dynamic icon;
  final VoidCallback onTap;

  const _HeroControl({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.34),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: HugeIcon(icon: icon, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final dynamic icon;
  final String label;

  const _HeroBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: icon,
            size: 13,
            color: Colors.white.withValues(alpha: 0.90),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.94),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  final String lang;

  const _StatusBadge({required this.isActive, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.20)
            : Colors.red.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isActive
              ? Colors.green.withValues(alpha: 0.45)
              : Colors.red.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        isActive
            ? t(lang, "trips.status_active")
            : t(lang, "trips.status_inactive"),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: isActive ? Colors.green.shade300 : Colors.red.shade300,
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int current;

  const _PageDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          width: active ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final ColorScheme scheme;
  const _ImageFallback({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedImageNotFound01,
          size: 34,
          color: scheme.onSurface.withValues(alpha: 0.30),
        ),
      ),
    );
  }
}

/* ============================================================
   ERROR STATE
   ============================================================ */

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lang = currentLangSync();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: scheme.error.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: 0.60),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedWifiError01,
                    size: 24,
                    color: scheme.error,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.error,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    t(lang, "common.try_again"),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
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

/* ============================================================
   SKELETON LOADER
   ============================================================ */

class _PackageDetailsSkeleton extends StatefulWidget {
  const _PackageDetailsSkeleton();

  @override
  State<_PackageDetailsSkeleton> createState() =>
      _PackageDetailsSkeletonState();
}

class _PackageDetailsSkeletonState extends State<_PackageDetailsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final sidePad = width >= 700 ? 24.0 : 16.0;
    final heroHeight = width <= 360
        ? 356.0
        : width <= 430
        ? 392.0
        : 430.0;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final base = scheme.surfaceContainerHighest.withValues(alpha: 0.25);
        final hi = scheme.surfaceContainerHighest.withValues(alpha: 0.42);
        final c = Color.lerp(base, hi, _c.value)!;

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(sidePad, 12, sidePad, 0),
              child: _SkelBox(color: c, height: heroHeight, radius: 28),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(sidePad, 14, sidePad, 18),
              child: _SkelBox(
                color: c.withValues(alpha: 0.72),
                height: 220,
                radius: 22,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(sidePad, 8, sidePad, 10),
              child: _SkelBox(color: c, height: 52, radius: 18),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(sidePad, 16, sidePad, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _SkelBox(color: c, height: 60, radius: 14),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SkelBox(color: c, height: 60, radius: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SkelLine(color: c, width: 120, height: 12),
                    const SizedBox(height: 10),
                    _SkelBox(color: c, height: 90, radius: 14),
                    const SizedBox(height: 16),
                    _SkelLine(color: c, width: 90, height: 12),
                    const SizedBox(height: 10),
                    _SkelBox(color: c, height: 52, radius: 14),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SkelBox extends StatelessWidget {
  final Color color;
  final double height;
  final double radius;

  const _SkelBox({
    required this.color,
    this.height = double.infinity,
    this.radius = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height == double.infinity ? null : height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SkelLine extends StatelessWidget {
  final Color color;
  final double width;
  final double height;

  const _SkelLine({
    required this.color,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
