import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:http/http.dart" as http;

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/package_endpoints.dart";
import "../../../../core/config/app_routes.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

/// Premium glassmorphism carousel preview of top trip packages (3 items).
/// - Responsive sizing (phone/tablet)
/// - Smooth page snapping + animated indicators
/// - Glass header + glass cards + shimmer-like loading skeleton
class TripPackagesPreview extends StatefulWidget {
  const TripPackagesPreview({super.key});

  @override
  State<TripPackagesPreview> createState() => _TripPackagesPreviewState();
}

class _TripPackagesPreviewState extends State<TripPackagesPreview>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  List<_Package> _items = const [];

  late final PageController _pageCtrl;
  double _page = 0.0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.86);
    _pageCtrl.addListener(() {
      final p = _pageCtrl.page ?? 0.0;
      if (p != _page && mounted) setState(() => _page = p);
    });
    _load();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Api.url("${PackageEndpoints.list}?limit=3");
      final resp = await http.get(uri);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body);
        final results = (decoded is Map ? decoded["results"] : decoded) as List? ?? [];
        _items = results
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .map(_Package.fromJson)
            .toList();
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

    final w = MediaQuery.sizeOf(context).width;
    final isTablet = w >= 700;

    final double height = isTablet ? 250 : 210;
    final double headerHPad = isTablet ? 24 : 16;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: headerHPad),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t(lang, "packages.title"),
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
              _GlassButton(
                label: t(lang, "packages.see_all"),
                onTap: () => Navigator.pushNamed(context, AppRoutes.tripPackages),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: height,
          child: _loading
              ? _LoadingCarousel(height: height, isTablet: isTablet)
              : _error != null
                  ? _ErrorState(
                      message: _error!,
                      onRetry: _load,
                      tryAgainText: t(lang, "common.try_again"),
                    )
                  : _items.isEmpty
                      ? _EmptyState(
                          label: t(lang, "packages.title"),
                        )
                      : _Carousel(
                          pageCtrl: _pageCtrl,
                          page: _page,
                          items: _items,
                          isTablet: isTablet,
                          onOpen: (id) => Navigator.pushNamed(
                            context,
                            AppRoutes.tripPackageDetails,
                            arguments: id,
                          ),
                          lang: lang,
                        ),
        ),
        if (!_loading && _error == null && _items.isNotEmpty) ...[
          const SizedBox(height: 10),
          _Dots(
            count: _items.length,
            activeIndex: _page.round().clamp(0, _items.length - 1),
          ),
        ],
      ],
    );
  }
}

class _Carousel extends StatelessWidget {
  final PageController pageCtrl;
  final double page;
  final List<_Package> items;
  final bool isTablet;
  final void Function(String id) onOpen;
  final String lang;

  const _Carousel({
    required this.pageCtrl,
    required this.page,
    required this.items,
    required this.isTablet,
    required this.onOpen,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hPad = isTablet ? 24.0 : 16.0;

    return PageView.builder(
      controller: pageCtrl,
      padEnds: false,
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final p = items[i];
        final delta = (page - i).abs().clamp(0.0, 1.0);

        // A more premium feel: slight tilt + scale + parallax.
        final scale = 1.0 - (0.06 * delta);
        final translateY = 10.0 * delta;
        final rotate = (0.04 * (page - i)).clamp(-0.06, 0.06);

        return Padding(
          padding: EdgeInsets.only(
            left: i == 0 ? hPad : 10,
            right: i == items.length - 1 ? hPad : 10,
          ),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translate(0.0, translateY)
              ..scale(scale)
              ..rotateZ(rotate),
            child: _PackageCard(
              key: ValueKey("pkg_${p.id}"),
              pkg: p,
              isTablet: isTablet,
              onTap: () => onOpen(p.id),
              titleFallback: t(lang, "packages.title"),
              daysLabel: t(lang, "packages.days"),
              activitiesLabel: t(lang, "packages.activities"),
              scheme: scheme,
              parallax: (page - i).clamp(-1.0, 1.0),
            ),
          ),
        );
      },
    );
  }
}

class _PackageCard extends StatelessWidget {
  final _Package pkg;
  final bool isTablet;
  final VoidCallback onTap;
  final String titleFallback;
  final String daysLabel;
  final String activitiesLabel;
  final ColorScheme scheme;
  final double parallax;

  const _PackageCard({
    super.key,
    required this.pkg,
    required this.isTablet,
    required this.onTap,
    required this.titleFallback,
    required this.daysLabel,
    required this.activitiesLabel,
    required this.scheme,
    required this.parallax,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(isTablet ? 26 : 22);

    final title = (pkg.title?.trim().isNotEmpty ?? false) ? pkg.title!.trim() : titleFallback;
    final subtitle = (pkg.subtitle?.trim().isNotEmpty ?? false) ? pkg.subtitle!.trim() : "";

    return GestureDetector(
      onTap: onTap,
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              // Base surface with subtle gradient.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.surface,
                      scheme.surface.withOpacity(0.8),
                    ],
                  ),
                ),
                child: const SizedBox.expand(),
              ),

              // Image with parallax.
              if (pkg.imageUrl != null)
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(parallax * 18, 0),
                    child: Image.network(
                      pkg.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: scheme.surfaceVariant.withOpacity(0.7),
                      ),
                      loadingBuilder: (context, child, evt) {
                        if (evt == null) return child;
                        return Container(
                          color: scheme.surfaceVariant.withOpacity(0.7),
                        );
                      },
                    ),
                  ),
                )
              else
                Positioned.fill(
                  child: Container(
                    color: scheme.surfaceVariant.withOpacity(0.7),
                  ),
                ),

              // Soft bottom gradient only for text legibility.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.5, 1.0],
                      colors: [
                        Colors.black.withOpacity(0.40),
                        Colors.black.withOpacity(0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Content.
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: _GlassFooter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: isTablet ? 16 : 14,
                          color: Colors.white,
                          letterSpacing: -0.2,
                          height: 1.05,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isTablet ? 12.5 : 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.86),
                            height: 1.15,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _MetaChip(
                            icon: Icons.schedule_rounded,
                            label: "${pkg.durationDays} $daysLabel",
                          ),
                          const Spacer(),
                          _MiniCTA(),
                        ],
                      ),
                    ],
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

class _GlassOverlay extends StatelessWidget {
  final BorderRadius radius;
  const _GlassOverlay({required this.radius});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Frosted glass pass.
        ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
        ),

        // Border + subtle inner light.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: Colors.white.withOpacity(0.16),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 26,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
          ),
        ),

        // Specular highlight
        Positioned(
          top: -60,
          left: -60,
          child: Transform.rotate(
            angle: -0.35,
            child: Container(
              width: 220,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.20),
                    Colors.white.withOpacity(0.0),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassFooter extends StatelessWidget {
  final Widget child;
  const _GlassFooter({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.14),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withOpacity(0.9)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white.withOpacity(0.92),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCTA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.16),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Icon(
        Icons.arrow_forward_rounded,
        size: 18,
        color: Colors.white.withOpacity(0.95),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int activeIndex;
  const _Dots({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final active = i == activeIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: active ? 22 : 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: active ? scheme.primary : scheme.onSurface.withOpacity(0.18),
            ),
          );
        }),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final Widget child;
  const _GlassPill({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: scheme.surface.withOpacity(0.55),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: scheme.onSurface.withOpacity(0.10)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GlassButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: scheme.surface.withOpacity(0.50),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: scheme.onSurface.withOpacity(0.10)),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String tryAgainText;

  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.tryAgainText,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: _GlassPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, color: scheme.error, size: 30),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              TextButton(onPressed: onRetry, child: Text(tryAgainText)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: _GlassPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox_rounded, size: 30),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                "No packages yet",
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surface.withOpacity(0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.onSurface.withOpacity(0.10)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _LoadingCarousel extends StatelessWidget {
  final double height;
  final bool isTablet;

  const _LoadingCarousel({required this.height, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final hPad = isTablet ? 24.0 : 16.0;

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, i) {
        return _SkeletonCard(height: height);
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double height;
  const _SkeletonCard({required this.height});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final w = MediaQuery.sizeOf(context).width;
    final isTablet = w >= 700;
    final cardW = isTablet ? 360.0 : 280.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(isTablet ? 26 : 22),
      child: Container(
        width: cardW,
        decoration: BoxDecoration(
          color: scheme.surfaceVariant.withOpacity(0.55),
          borderRadius: BorderRadius.circular(isTablet ? 26 : 22),
          border: Border.all(color: scheme.onSurface.withOpacity(0.08)),
        ),
        child: Stack(
          children: [
            // Frost blur to match the overall style.
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 76,
                  color: Colors.white.withOpacity(0.10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
      imageUrl: (json["cover_url"] ?? json["image"] ?? json["cover_image"]) as String?,
      durationDays: (json["duration_days"] as num?)?.toInt() ?? 0,
    );
  }
}
