import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;
import "package:intl/intl.dart";

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/event_endpoints.dart";
import "../../../../core/config/app_routes.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "explore_listings_feature.dart" show _ErrorState, _EmptyState, _GlassPill, _GlassLink, _GlassFooter, _SpecularHighlight, _ListingSkeleton;

class ExploreEventsFeature extends StatefulWidget {
  const ExploreEventsFeature({super.key});

  @override
  State<ExploreEventsFeature> createState() => _ExploreEventsFeatureState();
}

class _ExploreEventsFeatureState extends State<ExploreEventsFeature> {
  bool _loading = true;
  String? _error;
  List<_EventItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Api.url("${EventEndpoints.list}?page=1&page_size=4");
      final resp = await http.get(uri);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body);

        List<dynamic> results = const [];
        if (decoded is Map) {
          results = (decoded["results"] ?? decoded["data"] ?? const []) as List? ?? const [];
        } else if (decoded is List) {
          results = decoded;
        }

        _items = results
            .whereType<Map>()
            .map((m) => _EventItem.fromJson(Map<String, dynamic>.from(m)))
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
    final hPad = isTablet ? 24.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  t(lang, "explore.events_title"),
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface,
                    letterSpacing: -0.2,
                    fontFamily: "DM Sans",
                  ),
                ),
              ),
              _GlassButton(
                label: t(lang, "explore.events_hint"),
                onTap: () => Navigator.pushNamed(context, AppRoutes.events),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ✅ List layout (no sliding)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: _loading
              ? Column(
                  children: List.generate(
                    4,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: _EventListSkeleton(),
                    ),
                  ),
                )
              : _error != null
                  ? _ErrorState(message: _error!, onRetry: _load)
                  : _items.isEmpty
                      ? _EmptyState(label: t(lang, "common.coming_soon"))
                      : Column(
                          children: List.generate(_items.length, (i) {
                            final evt = _items[i];
                            return Padding(
                              padding: EdgeInsets.only(bottom: i == _items.length - 1 ? 0 : 12),
                              child: _EventListTile(
                                item: evt,
                                isTablet: isTablet,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.eventDetails,
                                  arguments: evt.id,
                                ),
                              ),
                            );
                          }),
                        ),
        ),
      ],
    );
  }
}

/* ----------------------------- EVENT TILE ----------------------------- */

class _EventListTile extends StatefulWidget {
  final _EventItem item;
  final bool isTablet;
  final VoidCallback onTap;

  const _EventListTile({
    required this.item,
    required this.isTablet,
    required this.onTap,
  });

  @override
  State<_EventListTile> createState() => _EventListTileState();
}

class _EventListTileState extends State<_EventListTile> {
  bool _pressed = false;
  void _set(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final radius = BorderRadius.circular(widget.isTablet ? 22 : 20);
    final h = widget.isTablet ? 104.0 : 96.0;

    final title = widget.item.name.trim().isNotEmpty ? widget.item.name.trim() : "Event";
    final loc = widget.item.location.trim();

    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.994 : 1,
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              // Glass base
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surface.withOpacity(isDark ? 0.55 : 0.75),
                    borderRadius: radius,
                    border: Border.all(color: scheme.onSurface.withOpacity(isDark ? 0.10 : 0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.20 : 0.10),
                        blurRadius: 26,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: const SizedBox.expand(),
                ),
              ),

              // Subtle accent gradient
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.primary.withOpacity(isDark ? 0.18 : 0.10),
                          scheme.surface.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Content row
              SizedBox(
                height: h,
                child: Padding(
                  padding: EdgeInsets.all(widget.isTablet ? 14 : 12),
                  child: Row(
                    children: [
                      _EventThumbnail(
                        imageUrl: widget.item.imageUrl,
                        size: widget.isTablet ? 70 : 64,
                        radius: 16,
                      ),
                      const SizedBox(width: 12),

                      // Texts
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: widget.isTablet ? 14.5 : 13.5,
                                fontWeight: FontWeight.w900,
                                color: scheme.onSurface,
                                letterSpacing: -0.2,
                                height: 1.05,
                                fontFamily: "DM Sans",
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                HugeIcon(
                                  icon: HugeIcons.strokeRoundedCalendar01,
                                  size: 14,
                                  strokeWidth: 2,
                                  color: scheme.onSurface.withOpacity(0.72),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    widget.item.dateLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onSurface.withOpacity(0.72),
                                      fontFamily: "DM Sans",
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (loc.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedMapPin,
                                    size: 13,
                                    strokeWidth: 2,
                                    color: scheme.onSurface.withOpacity(0.70),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      loc,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: scheme.onSurface.withOpacity(0.68),
                                        fontFamily: "DM Sans",
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Trailing arrow (glass)
                      _TrailingGlass(
                        active: _pressed,
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: scheme.onSurface.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Specular highlight
              Positioned.fill(
                child: IgnorePointer(
                  child: _SpecularHighlight(radius: radius),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventThumbnail extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final double radius;

  const _EventThumbnail({
    required this.imageUrl,
    required this.size,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: scheme.surfaceVariant.withOpacity(0.55),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: scheme.surfaceVariant.withOpacity(0.55)),
                loadingBuilder: (context, child, evt) {
                  if (evt == null) return child;
                  return Container(color: scheme.surfaceVariant.withOpacity(0.55));
                },
              )
            : Center(
                child: Icon(
                  Icons.celebration_rounded,
                  size: 20,
                  color: scheme.onSurface.withOpacity(0.55),
                ),
              ),
      ),
    );
  }
}

class _TrailingGlass extends StatelessWidget {
  final bool active;
  final Widget child;
  const _TrailingGlass({required this.active, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: scheme.surface.withOpacity(active ? 0.70 : 0.55),
            border: Border.all(color: scheme.onSurface.withOpacity(0.10)),
            shape: BoxShape.circle,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/* ----------------------------- MODEL ----------------------------- */

class _EventItem {
  final String id;
  final String name;
  final String? imageUrl;
  final String dateLabel;
  final String location;

  const _EventItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.dateLabel,
    required this.location,
  });

  factory _EventItem.fromJson(Map<String, dynamic> json) {
    final date = (json["start_date"] ?? json["date"] ?? json["created_at"] ?? "").toString();
    final city = (json["city"] ?? "").toString();
    final country = (json["country"] ?? "").toString();
    final loc = [city, country].where((e) => e.trim().isNotEmpty).join(", ");

    return _EventItem(
      id: (json["id"] ?? "").toString(),
      name: (json["name"] ?? json["title"] ?? "Upcoming event").toString(),
      imageUrl: (json["cover_url"] ??
              json["image"] ??
              json["first_image_url"] ??
              json["banner_url"]) as String?,
      dateLabel: date.isEmpty ? "Soon" : date,
      location: loc,
    );
  }
}

/* ----------------------------- SKELETON ----------------------------- */

class _EventListSkeleton extends StatelessWidget {
  const _EventListSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final w = MediaQuery.sizeOf(context).width;
    final isTablet = w >= 700;

    final radius = BorderRadius.circular(isTablet ? 22 : 20);
    final h = isTablet ? 104.0 : 96.0;

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: h,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant.withOpacity(0.55),
                  borderRadius: radius,
                  border: Border.all(color: scheme.onSurface.withOpacity(0.06)),
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: const SizedBox.expand(),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isTablet ? 14 : 12),
              child: Row(
                children: [
                  Container(
                    width: isTablet ? 70 : 64,
                    height: isTablet ? 70 : 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.10)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: 220,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 12,
                          width: 160,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: 140,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.10),
                      border: Border.all(color: Colors.white.withOpacity(0.10)),
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

/* ----------------------------- SMALL REUSED PIECES ----------------------------- */

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
                  fontFamily: "DM Sans",
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecularHighlight extends StatelessWidget {
  final BorderRadius radius;
  const _SpecularHighlight({required this.radius});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: [
          Positioned(
            top: -60,
            left: -40,
            child: Transform.rotate(
              angle: -0.25,
              child: Container(
                width: 220,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(80),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.12),
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
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: scheme.surfaceVariant.withOpacity(0.6),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, color: scheme.error),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.error,
              fontWeight: FontWeight.w800,
              fontFamily: "DM Sans",
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onRetry,
            child: Text(t(currentLangSync(), "common.try_again")),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(14),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontFamily: "DM Sans",
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
