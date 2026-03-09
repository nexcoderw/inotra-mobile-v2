import "dart:convert";
import "dart:math" as math;
import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/package_endpoints.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/main_scaffold.dart";

class TripPackageDetailsPage extends StatefulWidget {
  final String? packageId;
  const TripPackageDetailsPage({super.key, this.packageId});

  @override
  State<TripPackageDetailsPage> createState() => _TripPackageDetailsPageState();
}

class _TripPackageDetailsPageState extends State<TripPackageDetailsPage> {
  bool _loading = true;
  String? _error;
  _PackageDetail? _package;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    final id =
        widget.packageId ?? ModalRoute.of(context)?.settings.arguments as String?;
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
        _package = _PackageDetail.fromJson(decoded);
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
                    onRetry: _fetch,
                  )
                : _PackageBody(
                    pkg: pkg,
                    lang: lang,
                    scheme: scheme,
                    onBack: () => Navigator.maybePop(context),
                    onRefresh: _fetch,
                  ),
      ),
    );
  }
}

/* ============================================================
   BODY
   ============================================================ */

class _PackageBody extends StatefulWidget {
  final _PackageDetail pkg;
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
        // ── Blurred ambient background ─────────────────────────
        if (pkg.allImages.isNotEmpty)
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Image.network(
                pkg.allImages.first,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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

        // ── Main scroll ────────────────────────────────────────
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
              _OverviewTab(pkg: pkg, lang: lang, scheme: scheme),
              _ItineraryTab(pkg: pkg, lang: lang, scheme: scheme),
              _GalleryTab(pkg: pkg, lang: lang, scheme: scheme),
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
  final _PackageDetail pkg;
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
          // ── Photo reel ──────────────────────────────────────
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
                            imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Image.network(
                              images[i],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _ImageFallback(scheme: scheme),
                            ),
                          ),
                          ColoredBox(
                              color: Colors.black.withValues(alpha: 0.28)),
                          Image.network(
                            images[i],
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                _ImageFallback(scheme: scheme),
                            loadingBuilder: (_, child, evt) =>
                                evt == null ? child : _ImageFallback(scheme: scheme),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // ── Bottom gradient ─────────────────────────────────
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

          // ── Top controls ────────────────────────────────────
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

          // ── Bottom info ──────────────────────────────────────
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status + page dots row
                Row(
                  children: [
                    _StatusBadge(
                      isActive: pkg.isActive,
                      lang: lang,
                    ),
                    const Spacer(),
                    if (images.length > 1)
                      _PageDots(
                        count: images.length,
                        current: heroPage,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Title
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
                // Quick stats row
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
      BuildContext context, double shrinkOffset, bool overlapsContent) {
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
            tabs: tabs.map((t) => Tab(text: t)).toList(),
          ),
        ),
      ),
    );
  }
}

/* ============================================================
   OVERVIEW TAB
   ============================================================ */

class _OverviewTab extends StatelessWidget {
  final _PackageDetail pkg;
  final String lang;
  final ColorScheme scheme;

  const _OverviewTab({
    required this.pkg,
    required this.lang,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Stats chips row
        _StatsRow(pkg: pkg, lang: lang, scheme: scheme),
        const SizedBox(height: 16),

        // Description
        if (pkg.description.isNotEmpty) ...[
          _SectionHeader(
            icon: HugeIcons.strokeRoundedTextAlignLeft01,
            label: t(lang, "listings.overview_title"),
            scheme: scheme,
          ),
          const SizedBox(height: 10),
          _ContentCard(
            scheme: scheme,
            child: Text(
              pkg.description,
              style: TextStyle(
                fontSize: 12,
                height: 1.65,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface.withValues(alpha: 0.82),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Location
        if (pkg.location.isNotEmpty) ...[
          _SectionHeader(
            icon: HugeIcons.strokeRoundedMapsLocation02,
            label: t(lang, "listings.address"),
            scheme: scheme,
          ),
          const SizedBox(height: 10),
          _ContentCard(
            scheme: scheme,
            child: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedMapsLocation02,
                  size: 16,
                  color: scheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    pkg.location,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.86),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final _PackageDetail pkg;
  final String lang;
  final ColorScheme scheme;

  const _StatsRow({
    required this.pkg,
    required this.lang,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <({dynamic icon, String value})>[
      if (pkg.durationDays != null)
        (
          icon: HugeIcons.strokeRoundedClock01,
          value:
              "${pkg.durationDays} ${pkg.durationDays == 1 ? t(lang, "trips.day") : t(lang, "trips.days")}",
        ),
      if (pkg.activities.isNotEmpty)
        (
          icon: HugeIcons.strokeRoundedActivity01,
          value: "${pkg.activities.length} ${t(lang, "trips.activities")}",
        ),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (final chip in chips) ...[
          Expanded(
            child: _StatChip(
              icon: chip.icon,
              value: chip.value,
              scheme: scheme,
            ),
          ),
          if (chip != chips.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final dynamic icon;
  final String value;
  final ColorScheme scheme;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: scheme.primary.withValues(alpha: 0.08),
            border: Border.all(
                color: scheme.primary.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(icon: icon, size: 15, color: scheme.primary),
              const SizedBox(width: 7),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
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
   ITINERARY TAB  — vertical timeline
   ============================================================ */

class _ItineraryTab extends StatelessWidget {
  final _PackageDetail pkg;
  final String lang;
  final ColorScheme scheme;

  const _ItineraryTab({
    required this.pkg,
    required this.lang,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final activities = pkg.activities;

    if (activities.isEmpty) {
      return _EmptyState(
        icon: HugeIcons.strokeRoundedCalendar02,
        message: t(lang, "listings.no_data"),
        scheme: scheme,
      );
    }

    // Group by day
    final Map<int, List<_Activity>> grouped = {};
    for (final a in activities) {
      grouped.putIfAbsent(a.day, () => []).add(a);
    }
    final days = grouped.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        for (final day in days) ...[
          _DayHeader(day: day, lang: lang, scheme: scheme),
          const SizedBox(height: 8),
          for (int i = 0; i < grouped[day]!.length; i++)
            _TimelineActivityTile(
              activity: grouped[day]![i],
              isLast: i == grouped[day]!.length - 1 &&
                  day == days.last,
              scheme: scheme,
            ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  final int day;
  final String lang;
  final ColorScheme scheme;

  const _DayHeader({
    required this.day,
    required this.lang,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            "${t(lang, "trips.day_label")} $day",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: scheme.onPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Divider(
            color: scheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}

class _TimelineActivityTile extends StatelessWidget {
  final _Activity activity;
  final bool isLast;
  final ColorScheme scheme;

  const _TimelineActivityTile({
    required this.activity,
    required this.isLast,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 14),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scheme.surface,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.35),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            scheme.primary.withValues(alpha: 0.45),
                            scheme.primary.withValues(alpha: 0.10),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Tile content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: scheme.surfaceContainerHighest
                          .withValues(alpha: 0.22),
                      border: Border.all(
                        color: scheme.onSurface.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                          size: 15,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            activity.title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface.withValues(alpha: 0.90),
                            ),
                          ),
                        ),
                      ],
                    ),
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

/* ============================================================
   GALLERY TAB  — 2-column grid
   ============================================================ */

class _GalleryTab extends StatelessWidget {
  final _PackageDetail pkg;
  final String lang;
  final ColorScheme scheme;

  const _GalleryTab({
    required this.pkg,
    required this.lang,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final images = pkg.allImageItems;

    if (images.isEmpty) {
      return _EmptyState(
        icon: HugeIcons.strokeRoundedImage01,
        message: t(lang, "listings.no_data"),
        scheme: scheme,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: images.length,
      itemBuilder: (_, i) {
        final img = images[i];
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                img.url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _ImageFallback(scheme: scheme),
              ),
              // Gradient overlay at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(14),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.62),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Caption
              if (img.caption.isNotEmpty)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 7,
                  child: Text(
                    img.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              // Featured badge
              if (img.isFeatured)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade600,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedStar,
                          size: 11,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          t(lang, "trips.featured"),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
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

/* ============================================================
   REUSABLE WIDGETS
   ============================================================ */

class _ContentCard extends StatelessWidget {
  final Widget child;
  final ColorScheme scheme;

  const _ContentCard({required this.child, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
            border: Border.all(
              color: scheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final dynamic icon;
  final String label;
  final ColorScheme scheme;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HugeIcon(
          icon: icon,
          size: 15,
          color: scheme.onSurface.withValues(alpha: 0.65),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: scheme.onSurface.withValues(alpha: 0.85),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

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
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
          ),
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
            color: active
                ? Colors.white
                : Colors.white.withValues(alpha: 0.38),
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

class _EmptyState extends StatelessWidget {
  final dynamic icon;
  final String message;
  final ColorScheme scheme;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: icon,
            size: 34,
            color: scheme.onSurface.withValues(alpha: 0.30),
          ),
          const SizedBox(height: 10),
          Text(
            message,
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
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10)),
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
        final base =
            scheme.surfaceContainerHighest.withValues(alpha: 0.25);
        final hi =
            scheme.surfaceContainerHighest.withValues(alpha: 0.42);
        final c = Color.lerp(base, hi, _c.value)!;

        return Column(
          children: [
            // Hero
            _SkelBox(color: c, height: 340),
            // Tab bar
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
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _SkelBox(color: c, height: 60, radius: 14)),
                        const SizedBox(width: 10),
                        Expanded(child: _SkelBox(color: c, height: 60, radius: 14)),
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

/* ============================================================
   DATA MODELS
   ============================================================ */

class _ImageItem {
  final String url;
  final String caption;
  final bool isFeatured;

  const _ImageItem({
    required this.url,
    required this.caption,
    required this.isFeatured,
  });
}

class _Activity {
  final String id;
  final String title;
  final int day;

  const _Activity({
    required this.id,
    required this.title,
    required this.day,
  });

  factory _Activity.fromJson(Map<String, dynamic> j) {
    return _Activity(
      id: (j["id"] ?? "").toString(),
      title: (j["title"] ?? j["name"] ?? "").toString(),
      day: (j["time"] as num?)?.toInt() ?? 1,
    );
  }
}

class _PackageDetail {
  final String id;
  final String title;
  final String description;
  final String location;
  final String? coverUrl;
  final int? durationDays;
  final bool isActive;
  final List<_Activity> activities;
  final List<_ImageItem> images;

  const _PackageDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.coverUrl,
    required this.durationDays,
    required this.isActive,
    required this.activities,
    required this.images,
  });

  List<String> get allImages {
    final List<String> urls = [];
    if (coverUrl != null && coverUrl!.trim().isNotEmpty) {
      urls.add(coverUrl!.trim());
    }
    for (final img in images) {
      if (img.url.isNotEmpty && !urls.contains(img.url)) {
        urls.add(img.url);
      }
    }
    return urls;
  }

  List<_ImageItem> get allImageItems {
    final List<_ImageItem> items = [];
    if (coverUrl != null && coverUrl!.trim().isNotEmpty) {
      items.add(_ImageItem(
        url: coverUrl!.trim(),
        caption: title,
        isFeatured: true,
      ));
    }
    for (final img in images) {
      if (img.url.isNotEmpty) items.add(img);
    }
    return items;
  }

  factory _PackageDetail.fromJson(Map<String, dynamic> j) {
    final rawImages = (j["images"] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map((m) => _ImageItem(
                  url: (m["image_url"] ?? "").toString(),
                  caption: (m["caption"] ?? "").toString(),
                  isFeatured: m["is_featured"] == true,
                ))
            .toList() ??
        [];

    final rawActivities = (j["activities"] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(_Activity.fromJson)
            .toList() ??
        [];

    return _PackageDetail(
      id: (j["id"] ?? "").toString(),
      title: (j["title"] ?? j["name"] ?? "").toString(),
      description: (j["description"] ?? "").toString(),
      location: (j["location"] ?? j["city"] ?? "").toString(),
      coverUrl: (j["cover_url"] ?? j["image_url"] ?? "").toString(),
      durationDays: (j["duration_days"] as num?)?.toInt(),
      isActive: j["is_active"] == true,
      activities: rawActivities,
      images: rawImages,
    );
  }
}
