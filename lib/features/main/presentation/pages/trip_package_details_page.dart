import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../core/repositories/public_discovery_repository.dart";
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
      final resp = await PublicDiscoveryRepository.instance.fetchPackageDetail(
        id,
        forceRefresh: forceRefresh,
      );
      if (resp.isSuccess) {
        final decoded = resp.decodeJson() as Map<String, dynamic>;
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

    return Stack(
      children: [
        if (pkg.allImages.isNotEmpty)
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: AppCachedImage(
                imageUrl: pkg.allImages.first,
                fit: BoxFit.cover,
                memCacheWidth: 1800,
                memCacheHeight: 1400,
                maxWidthDiskCache: 2400,
                maxHeightDiskCache: 1800,
                errorBuilder: (_) => const SizedBox.shrink(),
                placeholderBuilder: (_) => const SizedBox.shrink(),
              ),
            ),
          ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.72),
            ),
          ),
        ),

        NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: _HeroSection(
                pkg: pkg,
                lang: lang,
                scheme: scheme,
                heroPage: _heroPage,
                heroCtrl: _heroCtrl,
                onPageChanged: (i) => setState(() => _heroPage = i),
                onBack: widget.onBack,
                onRefresh: widget.onRefresh,
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
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabs,
            children: [
              PackageOverviewTab(pkg: pkg),
              PackageActivitiesTab(activities: pkg.activities),
              PackageGalleryTab(images: pkg.allImageItems),
            ],
          ),
        ),
      ],
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
  final ValueChanged<int> onPageChanged;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const _HeroSection({
    required this.pkg,
    required this.lang,
    required this.scheme,
    required this.heroPage,
    required this.heroCtrl,
    required this.onPageChanged,
    required this.onBack,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final images = pkg.allImages;

    return SizedBox(
      height: 340,
      child: Stack(
        children: [
          Positioned.fill(
            child: images.isEmpty
                ? _ImageFallback(scheme: scheme)
                : PageView.builder(
                    controller: heroCtrl,
                    onPageChanged: onPageChanged,
                    itemCount: images.length,
                    itemBuilder: (_, i) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: 20,
                              sigmaY: 20,
                            ),
                            child: AppCachedImage(
                              imageUrl: images[i],
                              fit: BoxFit.cover,
                              memCacheWidth: 1800,
                              memCacheHeight: 1400,
                              maxWidthDiskCache: 2400,
                              maxHeightDiskCache: 1800,
                              errorBuilder: (_) =>
                                  _ImageFallback(scheme: scheme),
                              placeholderBuilder: (_) =>
                                  _ImageFallback(scheme: scheme),
                            ),
                          ),
                          ColoredBox(
                            color: Colors.black.withValues(alpha: 0.28),
                          ),
                          AppCachedImage(
                            imageUrl: images[i],
                            fit: BoxFit.contain,
                            memCacheWidth: 1800,
                            memCacheHeight: 1400,
                            maxWidthDiskCache: 2400,
                            maxHeightDiskCache: 1800,
                            errorBuilder: (_) => _ImageFallback(scheme: scheme),
                            placeholderBuilder: (_) =>
                                _ImageFallback(scheme: scheme),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 130,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.72),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _GlassRoundButton(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  onTap: onBack,
                ),
                const Spacer(),
                _GlassRoundButton(
                  icon: HugeIcons.strokeRoundedRefresh,
                  onTap: onRefresh,
                ),
              ],
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _StatusBadge(isActive: pkg.isActive, lang: lang),
                    const Spacer(),
                    if (images.length > 1)
                      _PageDots(count: images.length, current: heroPage),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  pkg.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                    shadows: [
                      Shadow(
                        blurRadius: 12,
                        color: Colors.black54,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (pkg.durationDays != null) ...[
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedClock01,
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.80),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${pkg.durationDays} ${pkg.durationDays == 1 ? t(lang, "trips.day") : t(lang, "trips.days")}",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (pkg.activities.isNotEmpty) ...[
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedActivity01,
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.80),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${pkg.activities.length} ${t(lang, "trips.activities")}",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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

  const _TabBarDelegate({
    required this.tabs,
    required this.controller,
    required this.scheme,
  });

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  bool shouldRebuild(_TabBarDelegate old) =>
      old.tabs != tabs || old.controller != controller;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 56,
          color: scheme.surface.withValues(alpha: 0.82),
          alignment: Alignment.center,
          child: TabBar(
            controller: controller,
            isScrollable: false,
            dividerColor: Colors.transparent,
            indicatorColor: scheme.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: scheme.primary,
            unselectedLabelColor: scheme.onSurface.withValues(alpha: 0.55),
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
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

class _GlassRoundButton extends StatelessWidget {
  final dynamic icon;
  final VoidCallback onTap;

  const _GlassRoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: HugeIcon(icon: icon, size: 20, color: Colors.white),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: scheme.surface.withValues(alpha: 0.10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedWifiError01,
                    size: 30,
                    color: scheme.error,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.error,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: onRetry,
                    child: Text(
                      t(lang, "common.try_again"),
                      style: const TextStyle(fontSize: 12),
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

    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final base = scheme.surfaceContainerHighest.withValues(alpha: 0.25);
        final hi = scheme.surfaceContainerHighest.withValues(alpha: 0.42);
        final c = Color.lerp(base, hi, _c.value)!;

        return Column(
          children: [
            _SkelBox(color: c, height: 340),
            Container(
              height: 56,
              color: scheme.surface.withValues(alpha: 0.82),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SkelLine(color: c, width: 60, height: 12),
                  _SkelLine(color: c, width: 60, height: 12),
                  _SkelLine(color: c, width: 60, height: 12),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
