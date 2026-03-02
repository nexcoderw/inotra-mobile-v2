import "dart:async";
import "dart:convert";
import "dart:ui";

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
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
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
          results =
              (decoded["results"] ?? decoded["data"] ?? const []) as List? ??
                  const [];
        } else if (decoded is List) {
          results = decoded;
        }
        final incoming = results
            .whereType<Map>()
            .map((m) => _EventItem.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        final existing = _events.map((e) => e.id).toSet();
        final unique =
            incoming.where((e) => !existing.contains(e.id)).toList();
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
    setState(() {});
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
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Responsive: 1 column on phone, 2 on tablet
    final isTablet = screenWidth >= 700;
    final hPad = isTablet ? 20.0 : 16.0;
    final crossCount = isTablet ? 2 : 1;
    // Card aspect ratio: tall poster — ~0.62 width/height ratio (portrait)
    final cardAspect = isTablet ? 0.64 : 0.62;

    return SafeArea(
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _onRefresh,
            child: CustomScrollView(
              controller: _scrollCtrl,
              slivers: [
                // Title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 12),
                    child: Text(
                      t(lang, "nav.events"),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),

                // Search bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 14),
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
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                // Skeleton (initial load)
                if (_loading && _events.isEmpty)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 14),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: cardAspect,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => const _EventCardSkeleton(),
                        childCount: 4,
                      ),
                    ),
                  ),

                // Grid of event cards
                if (_events.isNotEmpty)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 14),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: cardAspect,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= _events.length) {
                            return const _EventCardSkeleton();
                          }
                          final evt = _events[index];
                          return _EventPosterCard(
                            event: evt,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.eventDetails,
                              arguments: evt.id,
                            ),
                          );
                        },
                        childCount: _events.length +
                            ((_loading && _events.isNotEmpty) ? 2 : 0),
                      ),
                    ),
                  ),

                // Error state
                if (_error != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
                      child: Column(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedWifiError01,
                            color: scheme.error,
                            size: 26,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: scheme.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
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

                // Empty state
                if (!_loading && _events.isEmpty && _error == null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(hPad),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedCalendarRemove02,
                            color: scheme.onSurface.withOpacity(0.35),
                            size: 36,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t(lang, "common.coming_soon"),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),

          // Back to top FAB
          if (_showBackToTop)
            Positioned(
              right: 16,
              bottom: 18,
              child: FloatingActionButton.small(
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

/* ─────────────────────────────── POSTER CARD ─────────────────────────────── */

class _EventPosterCard extends StatefulWidget {
  final _EventItem event;
  final VoidCallback onTap;

  const _EventPosterCard({required this.event, required this.onTap});

  @override
  State<_EventPosterCard> createState() => _EventPosterCardState();
}

class _EventPosterCardState extends State<_EventPosterCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(22);

    final statusInfo = _resolveStatus(widget.event, lang, scheme);
    final priceLabel = widget.event.minPrice <= 0
        ? t(lang, "events.free")
        : "From Rwf ${_formatPrice(widget.event.minPrice)}";
    final locationLabel = widget.event.location().isNotEmpty
        ? widget.event.location()
        : "—";

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.97 : 1.0,
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Full-bleed banner image ──
              _BannerImage(url: widget.event.bannerUrl),

              // ── Top status pill ──
              Positioned(
                top: 12,
                left: 12,
                child: _StatusPill(
                  label: statusInfo.label,
                  bgColor: statusInfo.bgColor,
                  textColor: statusInfo.textColor,
                  borderColor: statusInfo.borderColor,
                ),
              ),

              // ── Bottom frosted glass bar ──
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _FrostedBar(
                  title: widget.event.title,
                  locationLabel: locationLabel,
                  priceLabel: priceLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(double v) {
    if (v >= 1000000) return "${(v / 1000000).toStringAsFixed(1)}M";
    if (v >= 1000) return "${(v / 1000).toStringAsFixed(0)}k";
    return v.toStringAsFixed(0);
  }
}

/* ─────────────────────────────── BANNER IMAGE ─────────────────────────────── */

class _BannerImage extends StatelessWidget {
  final String? url;
  const _BannerImage({this.url});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (url != null && url!.trim().isNotEmpty) {
      return Image.network(
        url!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _Placeholder(scheme: scheme),
        loadingBuilder: (_, child, evt) =>
            evt == null ? child : _Placeholder(scheme: scheme),
      );
    }
    return _Placeholder(scheme: scheme);
  }
}

class _Placeholder extends StatelessWidget {
  final ColorScheme scheme;
  const _Placeholder({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: scheme.surfaceVariant.withOpacity(0.55),
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedImageNotFound01,
          color: scheme.onSurface.withOpacity(0.3),
          size: 36,
        ),
      ),
    );
  }
}

/* ─────────────────────────────── FROSTED BOTTOM BAR ─────────────────────────────── */

class _FrostedBar extends StatelessWidget {
  final String title;
  final String locationLabel;
  final String priceLabel;

  const _FrostedBar({
    required this.title,
    required this.locationLabel,
    required this.priceLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 7),
              // Bottom row: venue + price
              Row(
                children: [
                  // Location chip
                  Expanded(
                    child: _BottomChip(
                      icon: HugeIcons.strokeRoundedMapsLocation02,
                      label: locationLabel,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Price chip
                  _BottomChip(
                    icon: HugeIcons.strokeRoundedTag01,
                    label: priceLabel,
                    shrink: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomChip extends StatelessWidget {
  final dynamic icon; // HugeIcons value
  final String label;
  final bool shrink;

  const _BottomChip({
    required this.icon,
    required this.label,
    this.shrink = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(
          icon: icon,
          color: Colors.white,
          size: 12,
        ),
        const SizedBox(width: 5),
        shrink
            ? Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              )
            : Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.22), width: 1),
      ),
      child: child,
    );
  }
}

/* ─────────────────────────────── STATUS PILL ─────────────────────────────── */

class _StatusPill extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final Color borderColor;

  const _StatusPill({
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

/* ─────────────────────────────── SKELETON ─────────────────────────────── */

class _EventCardSkeleton extends StatelessWidget {
  const _EventCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(22);
    final shimmer = scheme.surfaceVariant.withOpacity(0.65);
    final shimmerDark = scheme.surfaceVariant.withOpacity(0.40);

    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background shimmer
          Container(color: shimmer),

          // Top-left pill skeleton
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              width: 90,
              height: 26,
              decoration: BoxDecoration(
                color: shimmerDark,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),

          // Bottom bar skeleton
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: scheme.surfaceVariant.withOpacity(0.55),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title line
                  Container(
                    height: 13,
                    width: double.infinity,
                    margin: const EdgeInsets.only(right: 40),
                    decoration: BoxDecoration(
                      color: shimmerDark,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Bottom chips row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 26,
                          decoration: BoxDecoration(
                            color: shimmerDark,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 80,
                        height: 26,
                        decoration: BoxDecoration(
                          color: shimmerDark,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ─────────────────────────────── MODEL ─────────────────────────────── */

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
    final parts =
        [venue, city, country].where((e) => e.trim().isNotEmpty).toList();
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

    final start =
        parseDt(json["start_at"]?.toString() ?? json["start_date"]?.toString());
    final end =
        parseDt(json["end_at"]?.toString() ?? json["end_date"]?.toString());

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

/* ─────────────────────────────── STATUS HELPERS ─────────────────────────────── */

class _StatusInfo {
  final String label;
  final Color bgColor;
  final Color textColor;
  final Color borderColor;

  const _StatusInfo({
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
  });
}

_StatusInfo _resolveStatus(_EventItem e, String lang, ColorScheme scheme) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Ended
  if (e.endAt != null && e.endAt!.isBefore(now)) {
    return _StatusInfo(
      label: t(lang, "events.status_ended"),
      bgColor: Colors.red.withOpacity(0.55),
      textColor: Colors.white,
      borderColor: Colors.red.withOpacity(0.4),
    );
  }

  if (e.startAt != null) {
    final startDay =
        DateTime(e.startAt!.year, e.startAt!.month, e.startAt!.day);

    // Happening today
    if (startDay == today) {
      return _StatusInfo(
        label: t(lang, "events.status_happening"),
        bgColor: Colors.green.withOpacity(0.55),
        textColor: Colors.white,
        borderColor: Colors.green.withOpacity(0.4),
      );
    }

    // Tomorrow
    final tomorrow = today.add(const Duration(days: 1));
    if (startDay == tomorrow) {
      return _StatusInfo(
        label: t(lang, "events.status_tomorrow"),
        bgColor: Colors.white.withOpacity(0.22),
        textColor: Colors.white,
        borderColor: Colors.white.withOpacity(0.35),
      );
    }

    // Future: show relative or formatted date
    final diff = startDay.difference(today).inDays;
    final df = DateFormat("dd MMM, h:mm a");
    final label = diff <= 30
        ? "In $diff day${diff == 1 ? '' : 's'}, ${DateFormat('h:mm a').format(e.startAt!)}"
        : df.format(e.startAt!);

    return _StatusInfo(
      label: label,
      bgColor: Colors.black.withOpacity(0.40),
      textColor: Colors.white,
      borderColor: Colors.white.withOpacity(0.22),
    );
  }

  return _StatusInfo(
    label: t(lang, "events.status_ended"),
    bgColor: Colors.red.withOpacity(0.55),
    textColor: Colors.white,
    borderColor: Colors.red.withOpacity(0.4),
  );
}
