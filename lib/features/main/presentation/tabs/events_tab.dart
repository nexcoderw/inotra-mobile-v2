import "dart:async";
import "dart:convert";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;
import "package:intl/intl.dart";

import "../../../../core/config/api.dart";
import "../../../../core/config/app_routes.dart";
import "../../../../core/constants/api/event_endpoints.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class EventsTab extends StatefulWidget {
  const EventsTab({super.key});

  @override
  State<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<EventsTab> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();

  final List<_EventItem> _events = [];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  String _query = "";
  String? _error;
  bool _showBackToTop = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchPage(reset: true);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 &&
        !_loading &&
        _hasMore) {
      _fetchPage(reset: false);
    }
    final show = _scrollCtrl.position.pixels > 300;
    if (show != _showBackToTop) setState(() => _showBackToTop = show);
  }

  Future<void> _fetchPage({required bool reset}) async {
    setState(() {
      _loading = true;
      if (reset) {
        _page = 1;
        _hasMore = true;
        _events.clear();
      }
      _error = null;
    });

    try {
      final uri = Api.url(
        "${EventEndpoints.list}?page=$_page&page_size=10${_query.isNotEmpty ? "&search=$_query" : ""}",
      );
      final resp = await http.get(uri);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body);
        List results = const [];
        if (decoded is Map) {
          results = (decoded["results"] ?? decoded["data"] ?? const []) as List? ?? const [];
        } else if (decoded is List) {
          results = decoded;
        }
        final incoming = results
            .whereType<Map>()
            .map((m) => _EventItem.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        final existing = _events.map((e) => e.id).toSet();
        final unique = incoming.where((e) => !existing.contains(e.id)).toList();
        setState(() {
          _events.addAll(unique);
          _hasMore = incoming.length >= 10;
          if (_hasMore) _page += 1;
        });
      } else {
        setState(() => _error = "Status ${resp.statusCode}");
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onRefresh() async => _fetchPage(reset: true);

  void _onSearchChanged(String v) {
    setState(() {}); // refresh clear icon
    _query = v.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (_query.isEmpty) {
        _fetchPage(reset: true);
        return;
      }
      if (_query.length < 3) {
        setState(() {
          _events.clear();
          _hasMore = false;
          _error = null;
          _loading = false;
        });
        return;
      }
      _fetchPage(reset: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _onRefresh,
            child: CustomScrollView(
              controller: _scrollCtrl,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Text(
                      t(lang, "nav.events"),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: t(lang, "packages.search_hint"),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 10, right: 6),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedSearch01,
                            size: 16,
                            strokeWidth: 2,
                            color: scheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _onSearchChanged("");
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: scheme.surfaceVariant.withOpacity(0.6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: "DM Sans",
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                if (_loading && _events.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Column(
                        children: List.generate(
                          3,
                          (_) => const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: _EventSkeleton(),
                          ),
                        ),
                      ),
                    ),
                  ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final showLoader = _loading && _events.isNotEmpty;
                      if (index >= _events.length) {
                        return showLoader
                            ? const Padding(
                                padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                                child: _EventSkeleton(),
                              )
                            : const SizedBox.shrink();
                      }
                      final evt = _events[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: _EventCard(
                          event: evt,
                          isTablet: MediaQuery.sizeOf(context).width >= 700,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.eventDetails,
                            arguments: evt.id,
                          ),
                        ),
                      );
                    },
                    childCount: _events.length + ((_loading && _events.isNotEmpty) ? 1 : 0),
                  ),
                ),
                if (_error != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            _error!,
                            style: TextStyle(
                              color: scheme.error,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => _fetchPage(reset: true),
                            child: Text(t(lang, "common.try_again")),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!_loading && _events.isEmpty && _error == null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          t(lang, "common.coming_soon"),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 60)),
              ],
            ),
          ),
          if (_showBackToTop)
            Positioned(
              right: 16,
              bottom: 18,
              child: FloatingActionButton(
                mini: true,
                onPressed: () => _scrollCtrl.animateTo(
                  0,
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOut,
                ),
                child: const Icon(Icons.arrow_upward_rounded),
              ),
            ),
        ],
      ),
    );
  }
}

class _EventItem {
  final String id;
  final String title;
  final String? bannerUrl;
  final DateTime? startAt;
  final DateTime? endAt;
  final String venue;
  final String city;
  final String country;
  final double minPrice;

  _EventItem({
    required this.id,
    required this.title,
    required this.bannerUrl,
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
      title: (json["title"] ?? json["name"] ?? "Event").toString(),
      bannerUrl: (json["banner_url"] ??
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

class _EventCard extends StatefulWidget {
  final _EventItem event;
  final bool isTablet;
  final VoidCallback onTap;

  const _EventCard({
    required this.event,
    required this.isTablet,
    required this.onTap,
  });

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lang = currentLangSync();
    final isDark = scheme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(widget.isTablet ? 24 : 22);
    final height = widget.isTablet ? 112.0 : 104.0;

    final status = _eventStatus(widget.event, scheme, lang);
    final dateText = _dateLabel(widget.event, lang);

    final priceLabel =
        widget.event.minPrice <= 0 ? t(lang, "events.free") : "${_formatCompactPrice(widget.event.minPrice)} RWF";

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
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.08),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Material(
              color: scheme.surface,
              child: InkWell(
                onTap: widget.onTap,
                child: SizedBox(
                  height: height,
                  child: Row(
                    children: [
                      _EventThumb(
                        url: widget.event.bannerUrl,
                        size: widget.isTablet ? 110 : 96,
                        radius: BorderRadius.circular(widget.isTablet ? 24 : 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8, top: 10, bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.event.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: "DM Sans",
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _StatusPill(
                                    label: status.label,
                                    color: status.color,
                                    textColor: status.textColor,
                                  ),
                                ],
                              ),
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
                                      dateText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: "DM Sans",
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: scheme.onSurface.withOpacity(0.72),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
                                      widget.event.location(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: "DM Sans",
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: scheme.onSurface.withOpacity(0.68),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  _PricePill(label: priceLabel, fontSize: 14),
                                  const Spacer(),
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedArrowRight02,
                                    size: 14,
                                    strokeWidth: 2,
                                    color: scheme.onSurface.withOpacity(0.70),
                                  ),
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
            ),
          ),
        ),
      ),
    );
  }

  String _formatCompactPrice(double value) {
    if (value >= 1000000) return "${(value / 1000000).toStringAsFixed(1)}M";
    if (value >= 1000) return "${(value / 1000).toStringAsFixed(1)}K";
    return value.toStringAsFixed(0);
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _StatusPill({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  final String label;
  final double fontSize;
  const _PricePill({required this.label, this.fontSize = 13});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.primary.withOpacity(0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: "DM Sans",
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: scheme.primary,
        ),
      ),
    );
  }
}

class _EventThumb extends StatelessWidget {
  final String? url;
  final double size;
  final BorderRadius radius;

  const _EventThumb({
    required this.url,
    required this.size,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: size,
        height: size,
        color: scheme.surfaceVariant.withOpacity(0.55),
        child: url != null && url!.isNotEmpty
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: scheme.surfaceVariant.withOpacity(0.55)),
              )
            : Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedCalendar01,
                  size: 20,
                  strokeWidth: 2,
                  color: scheme.onSurface.withOpacity(0.55),
                ),
              ),
      ),
    );
  }
}

class _EventSkeleton extends StatelessWidget {
  const _EventSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isTablet = MediaQuery.sizeOf(context).width >= 700;
    final radius = BorderRadius.circular(isTablet ? 24 : 22);
    final height = isTablet ? 112.0 : 104.0;

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: scheme.surfaceVariant.withOpacity(0.55),
          borderRadius: radius,
          border: Border.all(color: scheme.onSurface.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: isTablet ? 110 : 96,
              height: isTablet ? 110 : 96,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.surfaceVariant.withOpacity(0.6),
                borderRadius: BorderRadius.circular(isTablet ? 20 : 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: 140,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 10,
                    width: 120,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 10,
                    width: 100,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class _EventStatus {
  final String label;
  final Color color;
  final Color textColor;
  const _EventStatus(this.label, this.color, this.textColor);
}

_EventStatus _eventStatus(_EventItem e, ColorScheme scheme, String lang) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  if (e.endAt != null && e.endAt!.isBefore(now)) {
    return _EventStatus(
      t(lang, "events.status_ended"),
      scheme.error,
      Colors.white,
    );
  }
  if (e.startAt != null) {
    final startDay = DateTime(e.startAt!.year, e.startAt!.month, e.startAt!.day);
    if (startDay == today) {
      return _EventStatus(t(lang, "events.status_happening"), scheme.primary, Colors.white);
    }
    final tomorrow = today.add(const Duration(days: 1));
    if (startDay == tomorrow) {
      return _EventStatus(t(lang, "events.status_tomorrow"), scheme.primary, Colors.white);
    }
  }
  return _EventStatus(
    _dateLabel(e, lang),
    scheme.primary.withOpacity(0.12),
    scheme.onSurface,
  );
}

String _dateLabel(_EventItem e, String lang) {
  final df = DateFormat("EEE, dd MMM");
  final dt = e.startAt ?? e.endAt;
  if (dt == null) return t(lang, "events.status_ended");
  return df.format(dt);
}
