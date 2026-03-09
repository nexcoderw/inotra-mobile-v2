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
                : _PackageDetailsBody(
                    package: pkg,
                    lang: lang,
                    scheme: scheme,
                    onBack: () => Navigator.maybePop(context),
                    onRefresh: _fetch,
                  ),
      ),
    );
  }
}

/* ----------------------------- Body ----------------------------- */

class _PackageDetailsBody extends StatefulWidget {
  final _PackageDetail package;
  final String lang;
  final ColorScheme scheme;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const _PackageDetailsBody({
    required this.package,
    required this.lang,
    required this.scheme,
    required this.onBack,
    required this.onRefresh,
  });

  @override
  State<_PackageDetailsBody> createState() => _PackageDetailsBodyState();
}

class _PackageDetailsBodyState extends State<_PackageDetailsBody> {
  int _galleryPage = 0;
  late final PageController _galleryCtrl;

  @override
  void initState() {
    super.initState();
    _galleryCtrl = PageController();
  }

  @override
  void dispose() {
    _galleryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pkg = widget.package;
    final lang = widget.lang;
    final scheme = widget.scheme;
    final allImages = [
      if (pkg.coverUrl != null && pkg.coverUrl!.trim().isNotEmpty) pkg.coverUrl!,
      ...pkg.images.map((i) => i.imageUrl).where((u) => u.trim().isNotEmpty),
    ];

    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Hero / gallery banner
            SliverToBoxAdapter(
              child: _HeroBanner(
                images: allImages,
                title: pkg.title,
                durationDays: pkg.durationDays,
                isActive: pkg.isActive,
                lang: lang,
                scheme: scheme,
                galleryPage: _galleryPage,
                galleryCtrl: _galleryCtrl,
                onPageChanged: (p) => setState(() => _galleryPage = p),
                onBack: widget.onBack,
                onRefresh: widget.onRefresh,
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Overview card
                  if (pkg.description.isNotEmpty) ...[
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle(t(lang, "listings.overview_title")),
                          const SizedBox(height: 8),
                          Text(
                            pkg.description,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurface.withValues(alpha: 0.82),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Quick stats row
                  _QuickStatsRow(pkg: pkg, lang: lang, scheme: scheme),
                  const SizedBox(height: 12),

                  // Activities card
                  if (pkg.activities.isNotEmpty) ...[
                    _ActivitiesCard(
                      activities: pkg.activities,
                      lang: lang,
                      scheme: scheme,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Image gallery thumbnails
                  if (pkg.images.isNotEmpty) ...[
                    _ImageGalleryCard(images: pkg.images, lang: lang, scheme: scheme),
                    const SizedBox(height: 12),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/* ----------------------------- Hero Banner ----------------------------- */

class _HeroBanner extends StatelessWidget {
  final List<String> images;
  final String title;
  final int? durationDays;
  final bool isActive;
  final String lang;
  final ColorScheme scheme;
  final int galleryPage;
  final PageController galleryCtrl;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const _HeroBanner({
    required this.images,
    required this.title,
    required this.durationDays,
    required this.isActive,
    required this.lang,
    required this.scheme,
    required this.galleryPage,
    required this.galleryCtrl,
    required this.onPageChanged,
    required this.onBack,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 300,
          child: Stack(
            children: [
              // Swipeable image gallery
              Positioned.fill(
                child: images.isEmpty
                    ? _BannerFallback(scheme: scheme)
                    : PageView.builder(
                        controller: galleryCtrl,
                        onPageChanged: onPageChanged,
                        itemCount: images.length,
                        itemBuilder: (_, i) => Stack(
                          fit: StackFit.expand,
                          children: [
                            ImageFiltered(
                              imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                              child: Image.network(
                                images[i],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                              ),
                            ),
                            ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
                            Image.network(
                              images[i],
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => _BannerFallback(scheme: scheme),
                              loadingBuilder: (_, child, evt) =>
                                  evt == null ? child : _BannerFallback(scheme: scheme),
                            ),
                          ],
                        ),
                      ),
              ),

              // Subtle darkening
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                  ),
                ),
              ),

              // Top controls
              Positioned(
                left: 12,
                right: 12,
                top: 12,
                child: Row(
                  children: [
                    _GlassIconButton(
                      icon: HugeIcons.strokeRoundedArrowLeft01,
                      onTap: onBack,
                    ),
                    const Spacer(),
                    if (images.length > 1)
                      _GlassPageIndicator(
                        current: galleryPage,
                        total: images.length,
                      ),
                    const Spacer(),
                    _GlassIconButton(
                      icon: HugeIcons.strokeRoundedRefresh,
                      onTap: onRefresh,
                    ),
                  ],
                ),
              ),

              // Bottom bar — title + pills
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: _GlassBar(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white.withValues(alpha: 0.96),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (durationDays != null)
                            _DurationPill(days: durationDays!),
                          const SizedBox(height: 4),
                          _ActivePill(isActive: isActive, lang: lang),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Swipe dots
              if (images.length > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 80,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(images.length, (i) {
                      final active = i == galleryPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: active
                              ? Colors.white.withValues(alpha: 0.92)
                              : Colors.white.withValues(alpha: 0.36),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ----------------------------- Quick Stats ----------------------------- */

class _QuickStatsRow extends StatelessWidget {
  final _PackageDetail pkg;
  final String lang;
  final ColorScheme scheme;

  const _QuickStatsRow({
    required this.pkg,
    required this.lang,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final stats = <({IconData icon, String label, String value})>[
      if (pkg.durationDays != null)
        (
          icon: HugeIcons.strokeRoundedClock01,
          label: t(lang, "trips.duration"),
          value: "${pkg.durationDays} ${pkg.durationDays == 1 ? t(lang, "trips.day") : t(lang, "trips.days")}",
        ),
      (
        icon: HugeIcons.strokeRoundedActivity01,
        label: t(lang, "trips.activities"),
        value: pkg.activitiesCount.toString(),
      ),
    ];

    if (stats.isEmpty) return const SizedBox.shrink();

    return Row(
      children: stats.map((s) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: s == stats.last ? 0 : 8,
            ),
            child: _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HugeIcon(
                    icon: s.icon,
                    size: 20,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withValues(alpha: 0.60),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/* ----------------------------- Activities Card ----------------------------- */

class _ActivitiesCard extends StatelessWidget {
  final List<_Activity> activities;
  final String lang;
  final ColorScheme scheme;

  const _ActivitiesCard({
    required this.activities,
    required this.lang,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    // Group activities by day
    final byDay = <int, List<_Activity>>{};
    for (final a in activities) {
      final day = a.day ?? 1;
      byDay.putIfAbsent(day, () => []).add(a);
    }
    final sortedDays = byDay.keys.toList()..sort();

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(t(lang, "trips.activities_title")),
          const SizedBox(height: 12),
          ...sortedDays.map((day) {
            final dayActivities = byDay[day]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: scheme.primary.withValues(alpha: 0.20)),
                    ),
                    child: Text(
                      "${t(lang, "trips.day")} $day",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Activity items for this day
                  ...dayActivities.map((a) => _ActivityTile(
                        activity: a,
                        scheme: scheme,
                        lang: lang,
                      )),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final _Activity activity;
  final ColorScheme scheme;
  final String lang;

  const _ActivityTile({
    required this.activity,
    required this.scheme,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                  size: 16,
                  color: scheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                activity.activityName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.88),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ----------------------------- Image Gallery ----------------------------- */

class _ImageGalleryCard extends StatelessWidget {
  final List<_PackageImage> images;
  final String lang;
  final ColorScheme scheme;

  const _ImageGalleryCard({
    required this.images,
    required this.lang,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(t(lang, "trips.gallery_title")),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final img = images[i];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      SizedBox(
                        width: 160,
                        height: 130,
                        child: Image.network(
                          img.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                            child: Center(
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedImageNotFound01,
                                size: 28,
                                color: scheme.onSurface.withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (img.isFeatured)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, size: 10, color: Colors.white),
                                const SizedBox(width: 3),
                                Text(
                                  t(lang, "trips.featured"),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (img.caption.isNotEmpty)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.70),
                                  Colors.transparent,
                                ],
                              ),
                            ),
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
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- Glass Primitives ----------------------------- */

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 10),
                color: Colors.black.withValues(alpha: 0.10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassBar extends StatelessWidget {
  final Widget child;
  const _GlassBar({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final dynamic icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: HugeIcon(icon: icon, size: 20, color: Colors.white),
      ),
    );
  }
}

class _GlassPageIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _GlassPageIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Text(
            "${current + 1} / $total",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: scheme.onSurface.withValues(alpha: 0.92),
      ),
    );
  }
}

/* ----------------------------- Pill widgets ----------------------------- */

class _DurationPill extends StatelessWidget {
  final int days;
  const _DurationPill({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            "$days d",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivePill extends StatelessWidget {
  final bool isActive;
  final String lang;
  const _ActivePill({required this.isActive, required this.lang});

  @override
  Widget build(BuildContext context) {
    final bg = isActive
        ? Colors.green.withValues(alpha: 0.20)
        : Colors.red.withValues(alpha: 0.20);
    final border = isActive
        ? Colors.green.withValues(alpha: 0.35)
        : Colors.red.withValues(alpha: 0.35);
    final label = isActive
        ? t(lang, "trips.status_active")
        : t(lang, "trips.status_inactive");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

/* ----------------------------- Banner Fallback ----------------------------- */

class _BannerFallback extends StatelessWidget {
  final ColorScheme scheme;
  const _BannerFallback({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedImageNotFound01,
          size: 36,
          color: scheme.onSurface.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

/* ----------------------------- Error State ----------------------------- */

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
        child: _GlassCard(
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
              const SizedBox(height: 10),
              TextButton(
                onPressed: onRetry,
                child: Text(t(lang, "common.try_again")),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ----------------------------- Skeleton Loader ----------------------------- */

class _PackageDetailsSkeleton extends StatefulWidget {
  const _PackageDetailsSkeleton();

  @override
  State<_PackageDetailsSkeleton> createState() => _PackageDetailsSkeletonState();
}

class _PackageDetailsSkeletonState extends State<_PackageDetailsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
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
        final base = scheme.surfaceContainerHighest.withValues(alpha: 0.28);
        final hi = scheme.surfaceContainerHighest.withValues(alpha: 0.45);
        final c = Color.lerp(base, hi, _c.value)!;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Hero skeleton
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: SizedBox(
                    height: 300,
                    child: Stack(
                      children: [
                        Positioned.fill(child: _SkelBox(color: c)),
                        Positioned(
                          left: 12,
                          top: 12,
                          child: _SkelCircle(color: c, size: 44),
                        ),
                        Positioned(
                          right: 12,
                          top: 12,
                          child: _SkelCircle(color: c, size: 44),
                        ),
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 14,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _SkelLine(color: c, w: double.infinity, h: 14),
                                          const SizedBox(height: 8),
                                          _SkelLine(color: c, w: 140, h: 12),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    _SkelPill(color: c, w: 60),
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
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Overview skel
                  _SkelCard(
                    color: c,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkelLine(color: c, w: 120, h: 12),
                        const SizedBox(height: 12),
                        _SkelLine(color: c, w: double.infinity, h: 12),
                        const SizedBox(height: 8),
                        _SkelLine(color: c, w: double.infinity, h: 12),
                        const SizedBox(height: 8),
                        _SkelLine(color: c, w: 220, h: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Stats row skel
                  Row(
                    children: [
                      Expanded(
                        child: _SkelCard(
                          color: c,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SkelCircle(color: c, size: 24),
                              const SizedBox(height: 10),
                              _SkelLine(color: c, w: 60, h: 12),
                              const SizedBox(height: 6),
                              _SkelLine(color: c, w: 80, h: 10),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SkelCard(
                          color: c,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SkelCircle(color: c, size: 24),
                              const SizedBox(height: 10),
                              _SkelLine(color: c, w: 40, h: 12),
                              const SizedBox(height: 6),
                              _SkelLine(color: c, w: 80, h: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Activities skel
                  _SkelCard(
                    color: c,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkelLine(color: c, w: 130, h: 12),
                        const SizedBox(height: 12),
                        _SkelPill(color: c, w: 60),
                        const SizedBox(height: 10),
                        _SkelBox(color: c, h: 42, r: 14),
                        const SizedBox(height: 6),
                        _SkelBox(color: c, h: 42, r: 14),
                        const SizedBox(height: 6),
                        _SkelBox(color: c, h: 42, r: 14),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Gallery skel
                  _SkelCard(
                    color: c,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkelLine(color: c, w: 80, h: 12),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 130,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: 3,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (_, __) => _SkelBox(color: c, h: 130, r: 14, w: 160),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

/* ----------------------------- Skeleton Atoms ----------------------------- */

class _SkelCard extends StatelessWidget {
  final Color color;
  final Widget child;
  const _SkelCard({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SkelBox extends StatelessWidget {
  final Color color;
  final double h;
  final double r;
  final double? w;
  const _SkelBox({required this.color, this.h = double.infinity, this.r = 12, this.w});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w,
      height: h == double.infinity ? null : h,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(r)),
    );
  }
}

class _SkelLine extends StatelessWidget {
  final Color color;
  final double w;
  final double h;
  const _SkelLine({required this.color, required this.w, required this.h});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w == double.infinity ? null : w,
      height: h,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
    );
  }
}

class _SkelCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _SkelCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SkelPill extends StatelessWidget {
  final Color color;
  final double w;
  const _SkelPill({required this.color, required this.w});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w,
      height: 26,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
    );
  }
}

/* ----------------------------- Data Models ----------------------------- */

class _PackageImage {
  final String id;
  final String imageUrl;
  final String caption;
  final bool isFeatured;

  _PackageImage({
    required this.id,
    required this.imageUrl,
    required this.caption,
    required this.isFeatured,
  });

  factory _PackageImage.fromJson(Map<String, dynamic> json) {
    return _PackageImage(
      id: (json["id"] ?? "").toString(),
      imageUrl: (json["image_url"] ?? "").toString(),
      caption: (json["caption"] ?? "").toString(),
      isFeatured: json["is_featured"] == true,
    );
  }
}

class _Activity {
  final String id;
  final String activityName;
  final int? day;

  _Activity({
    required this.id,
    required this.activityName,
    required this.day,
  });

  factory _Activity.fromJson(Map<String, dynamic> json) {
    int? parseDay(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return _Activity(
      id: (json["id"] ?? "").toString(),
      activityName: (json["activity_name"] ?? "").toString(),
      day: parseDay(json["time"]),
    );
  }
}

class _PackageDetail {
  final String id;
  final String title;
  final String description;
  final int? durationDays;
  final String? coverUrl;
  final List<_PackageImage> images;
  final List<_Activity> activities;
  final int activitiesCount;
  final bool isActive;

  _PackageDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.durationDays,
    required this.coverUrl,
    required this.images,
    required this.activities,
    required this.activitiesCount,
    required this.isActive,
  });

  factory _PackageDetail.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    final images = (json["images"] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(_PackageImage.fromJson)
            .toList() ??
        [];

    final activities = (json["activities"] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(_Activity.fromJson)
            .toList() ??
        [];

    return _PackageDetail(
      id: (json["id"] ?? "").toString(),
      title: (json["title"] ?? json["name"] ?? "").toString(),
      description: (json["description"] ?? "").toString(),
      durationDays: toInt(json["duration_days"]),
      coverUrl: (json["cover_url"] ?? "").toString(),
      images: images,
      activities: activities,
      activitiesCount: toInt(json["activities_count"]) ?? activities.length,
      isActive: json["is_active"] == true,
    );
  }
}
