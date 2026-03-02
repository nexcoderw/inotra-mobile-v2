import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/event_endpoints.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

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
        _items = results.whereType<Map>().map(_EventItem.fromJson).toList();
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
    final height = isTablet ? 260.0 : 224.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _GlassPill(
                child: Text(
                  t(lang, "explore.events_title"),
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              _GlassLink(
                label: t(lang, "explore.events_hint"),
                onTap: () {
                  // hook to events page when available
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: height,
          child: _loading
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  itemBuilder: (_, __) => const _EventSkeleton(),
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: 4,
                )
              : _error != null
                  ? Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: _ErrorState(message: _error!, onRetry: _load),
                    )
                  : _items.isEmpty
                      ? Padding(
                          padding: EdgeInsets.symmetric(horizontal: hPad),
                          child: _EmptyState(label: t(lang, "common.coming_soon")),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: hPad),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            final evt = _items[i];
                            return _EventCard(
                              item: evt,
                              isTablet: isTablet,
                            );
                          },
                        ),
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final _EventItem item;
  final bool isTablet;

  const _EventCard({
    required this.item,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final cardW = isTablet ? 260.0 : 200.0;
    final cardH = isTablet ? 230.0 : 210.0;
    final radius = BorderRadius.circular(isTablet ? 26 : 22);
    final title = item.name.isNotEmpty ? item.name : "Event";

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: cardW,
        height: cardH,
        child: Stack(
          children: [
            Positioned.fill(
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: scheme.surfaceVariant.withOpacity(0.7)),
                      loadingBuilder: (context, child, evt) {
                        if (evt == null) return child;
                        return Container(color: scheme.surfaceVariant.withOpacity(0.7));
                      },
                    )
                  : Container(color: scheme.surfaceVariant.withOpacity(0.7)),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.10),
                      Colors.black.withOpacity(0.52),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: Colors.white.withOpacity(isDark ? 0.12 : 0.18),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.30 : 0.14),
                      blurRadius: 26,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
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
                        fontSize: isTablet ? 14.5 : 13.5,
                        color: Colors.white,
                        letterSpacing: -0.2,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedCalendar01,
                          size: 14,
                          strokeWidth: 2,
                          color: Colors.white.withOpacity(0.92),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.dateLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.86),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.location.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedMapPin,
                            size: 13,
                            strokeWidth: 2,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.82),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: _SpecularHighlight(radius: radius),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

  factory _EventItem.fromJson(Map json) {
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

class _GlassFooter extends StatelessWidget {
  final Widget child;
  const _GlassFooter({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isDark ? 0.10 : 0.14),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(isDark ? 0.14 : 0.18)),
          ),
          child: child,
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
                      Colors.white.withOpacity(0.14),
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

class _EventSkeleton extends StatelessWidget {
  const _EventSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final w = MediaQuery.sizeOf(context).width;
    final isTablet = w >= 700;
    final radius = BorderRadius.circular(isTablet ? 26 : 22);
    final cardW = isTablet ? 260.0 : 200.0;

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: cardW,
        decoration: BoxDecoration(
          color: scheme.surfaceVariant.withOpacity(0.55),
          borderRadius: radius,
          border: Border.all(color: scheme.onSurface.withOpacity(0.06)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 84,
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

class _GlassLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GlassLink({
    required this.label,
    required this.onTap,
  });

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
