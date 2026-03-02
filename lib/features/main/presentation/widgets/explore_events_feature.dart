import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:intl/intl.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/event_endpoints.dart";
import "../../../../core/config/app_routes.dart";
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
      final uri = Api.url("${EventEndpoints.list}?page=1&page_size=3&limit=3");
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Dimensions close to screenshot proportions
    final radius = BorderRadius.circular(widget.isTablet ? 30 : 28);
    final h = widget.isTablet ? 128.0 : 118.0;

    final title = widget.item.title.trim().isNotEmpty ? widget.item.title.trim() : "Event";
    final subtitle = widget.item.location().trim().isNotEmpty ? widget.item.location().trim() : "—";
    final priceLabel =
        widget.item.minPrice <= 0 ? "Free" : "${_formatCompactPrice(widget.item.minPrice)} RWF";

    // Right pill label: keep "Today" to match screenshot.
    // If you want it dynamic, swap to widget.item.dateLabel (but screenshot uses Today).
    final pillLabel = "Today";

    // Clean light look (like image) + still okay on dark theme
    final isDark = scheme.brightness == Brightness.dark;
    final cardColor = isDark ? scheme.surface : const Color(0xFFFFFFFF);
    final borderColor = isDark ? scheme.onSurface.withOpacity(0.10) : const Color(0xFFEDEDED);

    // Blue outer glow like screenshot
    final glowColor = isDark ? scheme.primary.withOpacity(0.45) : const Color(0xFF2D57FF).withOpacity(0.35);

    // Soft shadow under card
    final shadowColor = Colors.black.withOpacity(isDark ? 0.35 : 0.10);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.992 : 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              // Blue glow (outer)
              BoxShadow(
                color: glowColor,
                blurRadius: 34,
                spreadRadius: 10,
                offset: const Offset(0, 18),
              ),
              // Main subtle shadow
              BoxShadow(
                color: shadowColor,
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Material(
              color: cardColor,
              child: InkWell(
                onTap: widget.onTap,
                splashColor: scheme.primary.withOpacity(0.06),
                highlightColor: scheme.primary.withOpacity(0.03),
                child: Container(
                  height: h,
                  padding: EdgeInsets.all(widget.isTablet ? 16 : 14),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: radius,
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Row(
                    children: [
                      // Poster (left)
                      _EventPosterThumb(
                        imageUrl: widget.item.imageUrl,
                        size: widget.isTablet ? 86 : 78,
                        radius: widget.isTablet ? 22 : 20,
                      ),
                      SizedBox(width: widget.isTablet ? 16 : 14),

                      // Text area
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top row: title + pill
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: widget.isTablet ? 20 : 18,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.3,
                                        color: isDark ? scheme.onSurface : const Color(0xFF111111),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _TodayPill(label: pillLabel),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Subtitle (grey, like "Mundi Center")
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: widget.isTablet ? 18 : 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? scheme.onSurface.withOpacity(0.60)
                                    : const Color(0xFF9A9A9A),
                              ),
                            ),

                            const Spacer(),

                            // Price (green)
                            Text(
                              priceLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: widget.isTablet ? 22 : 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                                color: const Color(0xFF0B3B2A), // close to screenshot
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
        ),
      ),
    );
  }

  String _formatCompactPrice(double value) {
    // 25000 -> 25k (like screenshot)
    final v = value.round();
    if (v >= 1000) {
      final k = (v / 1000);
      // show 25k not 25.0k
      final s = (k % 1 == 0) ? k.toStringAsFixed(0) : k.toStringAsFixed(1);
      return "${s}k";
    }
    return v.toString();
  }
}

class _TodayPill extends StatelessWidget {
  final String label;
  const _TodayPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    // light green pill like screenshot
    final bg = isDark ? scheme.surfaceVariant.withOpacity(0.65) : const Color(0xFFDCE9E2);
    final border = isDark ? scheme.onSurface.withOpacity(0.12) : const Color(0xFF0B3B2A);
    final text = isDark ? scheme.onSurface : const Color(0xFF0B3B2A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border.withOpacity(isDark ? 0.25 : 0.45), width: 1.2),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: text,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

class _EventPosterThumb extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final double radius;

  const _EventPosterThumb({
    required this.imageUrl,
    required this.size,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isDark ? scheme.surfaceVariant.withOpacity(0.45) : const Color(0xFFF0F0F0),
        ),
        child: (imageUrl != null && imageUrl!.trim().isNotEmpty)
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: isDark ? scheme.surfaceVariant.withOpacity(0.45) : const Color(0xFFF0F0F0),
                  child: Icon(Icons.image_not_supported_rounded, color: scheme.onSurface.withOpacity(0.45)),
                ),
                loadingBuilder: (context, child, evt) {
                  if (evt == null) return child;
                  return Container(
                    color: isDark ? scheme.surfaceVariant.withOpacity(0.45) : const Color(0xFFF0F0F0),
                  );
                },
              )
            : Container(
                color: isDark ? scheme.surfaceVariant.withOpacity(0.45) : const Color(0xFFF0F0F0),
                child: Icon(
                  Icons.celebration_rounded,
                  size: 22,
                  color: scheme.onSurface.withOpacity(0.55),
                ),
              ),
      ),
    );
  }
}

/* ----------------------------- MODEL ----------------------------- */

class _EventItem {
  final String id;
  final String title;
  final String? imageUrl;
  final DateTime? startAt;
  final DateTime? endAt;
  final String venue;
  final String city;
  final String country;
  final double minPrice;

  _EventItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.startAt,
    required this.endAt,
    required this.venue,
    required this.city,
    required this.country,
    required this.minPrice,
  });

  String location() {
    final parts = [venue, city, country].where((e) => e.trim().isNotEmpty).toList();
    return parts.join(" • ");
  }

  factory _EventItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      try {
        return DateTime.parse(raw).toLocal();
      } catch (_) {
        return null;
      }
    }

    final start = parseDt(json["start_at"]?.toString() ?? json["start_date"]?.toString());
    final end = parseDt(json["end_at"]?.toString() ?? json["end_date"]?.toString());

    return _EventItem(
      id: (json["id"] ?? "").toString(),
      title: (json["title"] ?? json["name"] ?? "Upcoming event").toString(),
      imageUrl: (json["banner_url"] ??
              json["cover_url"] ??
              json["image"] ??
              json["first_image_url"]) as String?,
      startAt: start,
      endAt: end,
      venue: (json["venue_name"] ?? "").toString(),
      city: (json["city"] ?? "").toString(),
      country: (json["country"] ?? "").toString(),
      minPrice: (json["min_ticket_price"] as num?)?.toDouble() ?? 0.0,
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

    final radius = BorderRadius.circular(isTablet ? 30 : 28);
    final h = isTablet ? 128.0 : 118.0;
    final isDark = scheme.brightness == Brightness.dark;

    final cardColor = isDark ? scheme.surface : const Color(0xFFFFFFFF);
    final borderColor = isDark ? scheme.onSurface.withOpacity(0.10) : const Color(0xFFEDEDED);
    final glowColor = isDark ? scheme.primary.withOpacity(0.35) : const Color(0xFF2D57FF).withOpacity(0.22);
    final shadowColor = Colors.black.withOpacity(isDark ? 0.30 : 0.08);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: 30,
            spreadRadius: 8,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: shadowColor,
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Container(
          height: h,
          padding: EdgeInsets.all(isTablet ? 16 : 14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: radius,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: isTablet ? 86 : 78,
                height: isTablet ? 86 : 78,
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(isTablet ? 22 : 20),
                ),
              ),
              SizedBox(width: isTablet ? 16 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 18,
                            decoration: BoxDecoration(
                              color: scheme.surfaceVariant.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 86,
                          height: 36,
                          decoration: BoxDecoration(
                            color: scheme.surfaceVariant.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 16,
                      width: 180,
                      decoration: BoxDecoration(
                        color: scheme.surfaceVariant.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 20,
                      width: 110,
                      decoration: BoxDecoration(
                        color: scheme.surfaceVariant.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
