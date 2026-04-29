import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;

import "../../../../core/config/api.dart";
import "../../../../core/config/app_routes.dart";
import "../../../../core/constants/api/event_endpoints.dart";
import "../../../../core/widgets/app_cached_image.dart";
import "../../../../core/widgets/image_not_found_svg.dart";
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

  Future<void> _load({bool forceRefresh = false}) async {
    if (forceRefresh) {
      // Kept for compatibility with existing retry handlers.
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Api.url(
        "${EventEndpoints.list}?page=1&page_size=3&limit=3&ordering=start_at",
      );
      final resp = await http.get(uri);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body);

        List<dynamic> results = const [];
        if (decoded is Map) {
          results =
              (decoded["results"] ?? decoded["data"] ?? const []) as List? ??
              const [];
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
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Fully responsive padding
    final hPad = screenWidth < 360
        ? 12.0
        : screenWidth < 600
        ? 16.0
        : screenWidth < 900
        ? 24.0
        : 32.0;

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
                    fontSize: screenWidth < 400 ? 13 : 14,
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface,
                    letterSpacing: -0.3,
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

        // List layout
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: _loading
              ? Column(
                  children: List.generate(
                    3,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: _EventListSkeleton(),
                    ),
                  ),
                )
              : _error != null
              ? _ErrorState(
                  message: _error!,
                  onRetry: () => _load(forceRefresh: true),
                )
              : _items.isEmpty
              ? _EmptyState(label: t(lang, "explore.no_events"))
              : Column(
                  children: List.generate(_items.length, (i) {
                    final evt = _items[i];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: i == _items.length - 1 ? 0 : 12,
                      ),
                      child: _EventListTile(
                        item: evt,
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
  final VoidCallback onTap;

  const _EventListTile({required this.item, required this.onTap});

  @override
  State<_EventListTile> createState() => _EventListTileState();
}

class _EventListTileState extends State<_EventListTile> {
  bool _pressed = false;

  String _resolvePillLabel(String lang) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final start = widget.item.startAt;
    final end = widget.item.endAt;

    // Ended: end_at is in the past
    if (end != null && end.isBefore(now)) {
      return t(lang, "events.status_ended");
    }

    if (start != null) {
      final startDay = DateTime(start.year, start.month, start.day);

      // Happening today
      if (startDay == today) {
        return t(lang, "events.status_happening");
      }

      // Happening tomorrow
      if (startDay == tomorrow) {
        return t(lang, "events.status_tomorrow");
      }

      // Future date: show formatted date
      final day = start.day.toString().padLeft(2, '0');
      final month = _shortMonth(start.month);
      return "$day $month";
    }

    return "";
  }

  String _shortMonth(int m) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[(m - 1).clamp(0, 11)];
  }

  _PillStyle _pillStyle(String label, String lang) {
    final endedLabel = t(lang, "events.status_ended");
    final happeningLabel = t(lang, "events.status_happening");
    final tomorrowLabel = t(lang, "events.status_tomorrow");

    if (label == endedLabel) return _PillStyle.ended;
    if (label == happeningLabel) return _PillStyle.happening;
    if (label == tomorrowLabel) return _PillStyle.tomorrow;
    return _PillStyle.date;
  }

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;

    final isTablet = screenWidth >= 700;
    final radius = BorderRadius.circular(isTablet ? 28 : 24);
    final cardHeight = isTablet ? 120.0 : 106.0;
    final thumbSize = isTablet ? 80.0 : 72.0;
    final thumbRadius = isTablet ? 20.0 : 18.0;
    final innerPad = isTablet ? 14.0 : 12.0;
    final gap = isTablet ? 14.0 : 12.0;

    final title = widget.item.title.trim().isNotEmpty
        ? widget.item.title.trim()
        : "Event";
    final subtitle = widget.item.location().trim().isNotEmpty
        ? widget.item.location().trim()
        : "—";
    final priceLabel = widget.item.minPrice <= 0
        ? t(lang, "events.free")
        : "${_formatCompactPrice(widget.item.minPrice)} RWF";

    final pillLabel = _resolvePillLabel(lang);
    final pillStyle = _pillStyle(pillLabel, lang);

    final isDark = scheme.brightness == Brightness.dark;
    final cardColor = isDark ? scheme.surface : const Color(0xFFFFFFFF);
    final borderColor = isDark
        ? scheme.onSurface.withValues(alpha: 0.08)
        : const Color(0xFFEAEAEA);
    final shadowColor = Colors.black.withValues(alpha: isDark ? 0.22 : 0.07);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.985 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Material(
              color: cardColor,
              child: InkWell(
                onTap: widget.onTap,
                splashColor: scheme.primary.withValues(alpha: 0.05),
                highlightColor: scheme.primary.withValues(alpha: 0.02),
                child: Container(
                  height: cardHeight,
                  padding: EdgeInsets.all(innerPad),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: radius,
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Row(
                    children: [
                      // Poster thumbnail
                      _EventPosterThumb(
                        imageUrl: widget.item.imageUrl,
                        size: thumbSize,
                        radius: thumbRadius,
                      ),
                      SizedBox(width: gap),

                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title row + pill
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                      color: isDark
                                          ? scheme.onSurface
                                          : const Color(0xFF111111),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (pillLabel.isNotEmpty)
                                  _StatusPill(
                                    label: pillLabel,
                                    style: pillStyle,
                                  ),
                              ],
                            ),

                            const SizedBox(height: 5),

                            // Venue / location
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? scheme.onSurface.withValues(alpha: 0.55)
                                    : const Color(0xFF9A9A9A),
                              ),
                            ),

                            const Spacer(),

                            // Bottom row: price + date
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Text(
                                    priceLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.2,
                                      color: Color(0xFF0B3B2A),
                                    ),
                                  ),
                                ),
                                if (widget.item.startAt != null)
                                  Text(
                                    _formatDate(widget.item.startAt!),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? scheme.onSurface.withValues(
                                              alpha: 0.45,
                                            )
                                          : const Color(0xFFAAAAAA),
                                    ),
                                  ),
                              ],
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

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = _shortMonth(dt.month);
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return "$day $month $year, $hour:$min";
  }

  String _formatCompactPrice(double value) {
    final v = value.round();
    if (v >= 1000) {
      final k = v / 1000;
      final s = (k % 1 == 0) ? k.toStringAsFixed(0) : k.toStringAsFixed(1);
      return "${s}k";
    }
    return v.toString();
  }
}

enum _PillStyle { ended, happening, tomorrow, date }

class _StatusPill extends StatelessWidget {
  final String label;
  final _PillStyle style;

  const _StatusPill({required this.label, required this.style});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    Color bg;
    Color textColor;
    Color borderColor;

    switch (style) {
      case _PillStyle.ended:
        bg = isDark
            ? const Color(0xFF3B1010).withValues(alpha: 0.7)
            : const Color(0xFFFFEDED);
        textColor = const Color(0xFFB91C1C);
        borderColor = const Color(0xFFB91C1C).withValues(alpha: 0.25);
        break;
      case _PillStyle.happening:
        bg = isDark
            ? const Color(0xFF0B3B2A).withValues(alpha: 0.6)
            : const Color(0xFFDCF5EA);
        textColor = const Color(0xFF0B7B45);
        borderColor = const Color(0xFF0B7B45).withValues(alpha: 0.25);
        break;
      case _PillStyle.tomorrow:
        bg = isDark
            ? const Color(0xFF1A2B4A).withValues(alpha: 0.6)
            : const Color(0xFFE0E9FF);
        textColor = const Color(0xFF2D57FF);
        borderColor = const Color(0xFF2D57FF).withValues(alpha: 0.25);
        break;
      case _PillStyle.date:
        bg = isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : const Color(0xFFF4F4F4);
        textColor = isDark
            ? scheme.onSurface.withValues(alpha: 0.75)
            : const Color(0xFF555555);
        borderColor = isDark
            ? scheme.onSurface.withValues(alpha: 0.10)
            : const Color(0xFFDDDDDD);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: -0.1,
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
    final placeholder = isDark
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.45)
        : const Color(0xFFF0F0F0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: placeholder,
        child: (imageUrl != null && imageUrl!.trim().isNotEmpty)
            ? AppCachedImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: 512,
                memCacheHeight: 512,
                maxWidthDiskCache: 768,
                maxHeightDiskCache: 768,
                errorBuilder: (_) => ImageNotFoundSvg(
                  backgroundColor: placeholder,
                  sizeFactor: 0.46,
                ),
                placeholderBuilder: (_) => Container(color: placeholder),
              )
            : ImageNotFoundSvg(backgroundColor: placeholder, sizeFactor: 0.46),
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
    final parts = [
      venue,
      city,
      country,
    ].where((e) => e.trim().isNotEmpty).toList();
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

    final start = parseDt(
      json["start_at"]?.toString() ?? json["start_date"]?.toString(),
    );
    final end = parseDt(
      json["end_at"]?.toString() ?? json["end_date"]?.toString(),
    );

    return _EventItem(
      id: (json["id"] ?? "").toString(),
      title: (json["title"] ?? json["name"] ?? "Upcoming event").toString(),
      imageUrl:
          (json["banner_url"] ??
                  json["cover_url"] ??
                  json["image"] ??
                  json["first_image_url"])
              as String?,
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= 700;

    final radius = BorderRadius.circular(isTablet ? 28 : 24);
    final h = isTablet ? 120.0 : 106.0;
    final isDark = scheme.brightness == Brightness.dark;

    final cardColor = isDark ? scheme.surface : const Color(0xFFFFFFFF);
    final borderColor = isDark
        ? scheme.onSurface.withValues(alpha: 0.08)
        : const Color(0xFFEAEAEA);
    final shimmer = scheme.surfaceContainerHighest.withValues(
      alpha: isDark ? 0.45 : 0.55,
    );
    final shadowColor = Colors.black.withValues(alpha: isDark ? 0.18 : 0.06);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Container(
          height: h,
          padding: EdgeInsets.all(isTablet ? 14 : 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: radius,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: isTablet ? 80 : 72,
                height: isTablet ? 80 : 72,
                decoration: BoxDecoration(
                  color: shimmer,
                  borderRadius: BorderRadius.circular(isTablet ? 20 : 18),
                ),
              ),
              SizedBox(width: isTablet ? 14 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 13,
                            decoration: BoxDecoration(
                              color: shimmer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 70,
                          height: 24,
                          decoration: BoxDecoration(
                            color: shimmer.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 160,
                      decoration: BoxDecoration(
                        color: shimmer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          height: 14,
                          width: 80,
                          decoration: BoxDecoration(
                            color: shimmer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          height: 11,
                          width: 90,
                          decoration: BoxDecoration(
                            color: shimmer.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ],
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.50),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: scheme.onSurface.withValues(alpha: 0.10),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border.all(color: scheme.error.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedWifiError01,
            color: scheme.error,
            size: 28,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: scheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onRetry,
            child: Text(
              t(currentLangSync(), "common.try_again"),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
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
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedCalendarRemove02,
            color: scheme.onSurface.withValues(alpha: 0.35),
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
