import "dart:async";
import "dart:convert";
import "dart:math" as math;
import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;
import "package:toastification/toastification.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/place_endpoints.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/listing_details_shared.dart";
import "../widgets/listing_details_overview_tab.dart";
import "../widgets/listing_details_map_tab.dart";
import "../widgets/listing_details_reviews_tab.dart";
import "../widgets/listing_details_transport_tab.dart";
import "../widgets/listing_image_preview.dart";

class ListingDetailsPage extends StatefulWidget {
  final String? placeId;
  const ListingDetailsPage({super.key, this.placeId});

  @override
  State<ListingDetailsPage> createState() => _ListingDetailsPageState();
}

class _ListingDetailsPageState extends State<ListingDetailsPage> {
  PlaceDetails? _place;
  bool _loading = true;
  String? _error;

  bool _ctaBusy = false;
  bool _saved = false;
  static const _favKey = "listing_favorites";
  static const _expiryMs = Duration(days: 7).inMilliseconds;
  Set<String> _favorites = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _loadFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_favKey);
    if (raw == null) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final kept = decoded.whereType<Map>().where((m) {
          final ts = m["ts"] as int? ?? 0;
          return now - ts < _expiryMs;
        }).toList();
        _favorites
          ..clear()
          ..addAll(kept.map((m) => (m["id"] ?? "").toString()));
        await prefs.setString(_favKey, jsonEncode(kept));
        if (_place != null) _saved = _favorites.contains(_place!.id);
      }
    } catch (_) {
      // ignore cache errors
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final payload = _favorites.map((id) => {"id": id, "ts": now}).toList();
    await prefs.setString(_favKey, jsonEncode(payload));
  }

  bool _isFavorite(String id) => _favorites.contains(id);

  Future<void> _toggleFavorite() async {
    if (_place == null) return;
    final id = _place!.id;
    final added = !_favorites.contains(id);

    setState(() {
      if (added) {
        _favorites.add(id);
      } else {
        _favorites.remove(id);
      }
      _saved = added;
    });

    await _saveFavorites();
    if (!mounted) return;

    final msg = added
        ? "Listing added to favorites"
        : "Listing removed from favorites";

    toastification.show(
      context: context,
      type: added ? ToastificationType.success : ToastificationType.info,
      style: ToastificationStyle.fillColored,
      title: Text(msg),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  Future<void> _init() async {
    await _loadFavorite();
    await _fetch();
  }

  Future<void> _fetch() async {
    final id =
        widget.placeId ?? ModalRoute.of(context)?.settings.arguments as String?;
    if (id == null || id.isEmpty) {
      setState(() {
        _loading = false;
        _error = "Missing listing id";
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Api.url(PlaceEndpoints.detail(id));
      final resp = await http.get(uri);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body);
        if (decoded is Map) {
          _place = PlaceDetails.fromJson(Map<String, dynamic>.from(decoded));
          if (_place != null) _saved = _isFavorite(_place!.id);
        } else {
          _error = "Invalid response";
        }
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
    final scheme = Theme.of(context).colorScheme;
    final lang = currentLangSync();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          top: false,
          child: _loading
              ? const _PageSkeleton()
              : _error != null
                  ? _ErrorState(message: _error!, onRetry: _fetch)
                  : _place == null
                      ? _ErrorState(
                          message: t(lang, "listings.no_data"),
                          onRetry: _fetch,
                        )
                      : Stack(
                          children: [
                            // HERO
                            Positioned.fill(
                              child: _HeroPager(images: _place!.images),
                            ),

                            // TOP BAR (BACK)
                            Positioned(
                              left: 16,
                              top: MediaQuery.of(context).padding.top + 14,
                              child: _RoundIconButton(
                                icon: HugeIcons.strokeRoundedArrowLeft01,
                                onTap: () => Navigator.maybePop(context),
                              ),
                            ),

                            // BOTTOM SHEET CONTENT
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: _DetailsSheet(
                                place: _place!,
                                saved: _saved,
                                onToggleSaved: _toggleFavorite,
                              ),
                            ),
                          ],
                        ),
        ),
        bottomNavigationBar: (_place != null && !_loading && _error == null)
            ? SafeArea(
                minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _ReserveCTAButton(
                  label: t(lang, "listings.reserve_cta"),
                  busy: _ctaBusy,
                  onTap: _ctaBusy
                      ? null
                      : () async {
                          setState(() => _ctaBusy = true);
                          await Future.delayed(const Duration(milliseconds: 900));
                          if (!mounted) return;

                          toastification.show(
                            context: context,
                            type: ToastificationType.info,
                            style: ToastificationStyle.fillColored,
                            title: Text(t(lang, "common.coming_soon")),
                            alignment: Alignment.topCenter,
                            autoCloseDuration: const Duration(seconds: 3),
                          );

                          if (mounted) setState(() => _ctaBusy = false);
                        },
                ),
              )
            : null,
      ),
    );
  }
}

/* ----------------------------- SHEET ----------------------------- */

class _DetailsSheet extends StatelessWidget {
  final PlaceDetails place;
  final bool saved;
  final VoidCallback onToggleSaved;

  const _DetailsSheet({
    required this.place,
    required this.saved,
    required this.onToggleSaved,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lang = currentLangSync();
    final media = MediaQuery.of(context);

    final maxH = media.size.height;
    final sheetMax = maxH * 0.62;
    final sheetMin = maxH * 0.52;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      tween: Tween(begin: 0, end: 1),
      builder: (context, anim, _) {
        return SizedBox(
          height: lerpDouble(sheetMin, sheetMax, 1)!,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surface.withOpacity(0.92),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 26,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // TITLE + SAVE
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              place.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                                height: 1.05,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _RoundIconButton(
                            icon: saved
                                ? HugeIcons.strokeRoundedBookmark02
                                : HugeIcons.strokeRoundedBookmark01,
                            onTap: onToggleSaved,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // SEGMENTED TABS
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _PillTabBar(
                        labels: [
                          t(lang, "listings.tab_overview"),
                          t(lang, "listings.tab_map"),
                          t(lang, "listings.tab_reviews"),
                          t(lang, "listings.tab_transport"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // LOCATION + RATING
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedMapsLocation02,
                            size: 18,
                            color: scheme.onSurface.withOpacity(0.65),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              place.city.isNotEmpty
                                  ? "${place.city}, ${place.country}"
                                  : place.country,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface.withOpacity(0.62),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _RatingCompact(
                            rating: place.rating ?? 0,
                            reviews: place.reviewsCount ?? 0,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // THUMBNAILS ROW
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _ThumbRow(images: place.images),
                    ),

                    const SizedBox(height: 12),

                    // TAB CONTENT
                    Expanded(
                      child: TabBarView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          ListingOverviewTab(place: place),
                          ListingMapTab(place: place),
                          const ListingReviewsTab(),
                          ListingTransportTab(place: place),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/* ----------------------------- HERO PAGER ----------------------------- */

class _HeroPager extends StatefulWidget {
  final List<String> images;
  const _HeroPager({required this.images});

  @override
  State<_HeroPager> createState() => _HeroPagerState();
}

class _HeroPagerState extends State<_HeroPager> {
  int _index = 0;
  late final PageController _pageCtrl;
  Timer? _auto;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final imgs = widget.images.isNotEmpty ? widget.images : [""];

    final media = MediaQuery.of(context);
    final topPad = media.padding.top;

    // Make image area taller so user sees it clearly
    final heroHeight = media.size.height * 0.52; // ~52% of screen height

    return Stack(
      children: [
        // Background fallback color behind image
        Container(color: scheme.surface),

        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: heroHeight,
            width: double.infinity,
            child: GestureDetector(
              onTap: () => _openPreview(context, imgs),
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: imgs.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final url = imgs[i].trim();
                  if (url.isEmpty) return _HeroPlaceholder(scheme: scheme);

                  return Image.network(
                    url,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high, // sharper
                    isAntiAlias: true,
                    errorBuilder: (_, __, ___) => _HeroPlaceholder(scheme: scheme),
                    loadingBuilder: (_, child, evt) {
                      if (evt == null) return child;
                      return _HeroPlaceholder(scheme: scheme);
                    },
                  );
                },
              ),
            ),
          ),
        ),

        // Softer bottom fade (reduced so image stays clear)
        Positioned(
          left: 0,
          right: 0,
          top: heroHeight - 180,
          height: 180,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.18),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Dots indicator - placed nicely under status bar
        Positioned(
          left: 0,
          right: 0,
          top: topPad + 64,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                imgs.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: _index == i ? 18 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _index == i
                        ? Colors.white.withOpacity(0.95)
                        : Colors.white.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _startAuto();
  }

  void _startAuto() {
    _auto?.cancel();
    _auto = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final total = widget.images.isEmpty ? 1 : widget.images.length;
      if (total <= 1) return;
      final next = (_index + 1) % total;
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _openPreview(BuildContext context, List<String> imgs) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (_) => ListingImagePreview(
        images: imgs,
        initialIndex: _index,
      ),
    );
  }

  @override
  void dispose() {
    _auto?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }
}

class _HeroPlaceholder extends StatelessWidget {
  final ColorScheme scheme;
  const _HeroPlaceholder({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: scheme.surfaceVariant.withOpacity(0.7),
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedImageNotFound01,
          color: scheme.onSurface.withOpacity(0.35),
          size: 34,
        ),
      ),
    );
  }
}

/* ----------------------------- PILL TAB BAR ----------------------------- */

class _PillTabBar extends StatelessWidget {
  final List<String> labels;
  const _PillTabBar({required this.labels});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: TabBar(
        isScrollable: true,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurface.withOpacity(0.55),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        tabAlignment: TabAlignment.start,
        tabs: labels
            .map(
              (t) => Tab(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(t),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/* ----------------------------- THUMB ROW ----------------------------- */

class _ThumbRow extends StatelessWidget {
  final List<String> images;
  const _ThumbRow({required this.images});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final list = images.where((e) => e.trim().isNotEmpty).toList();
    final shown = list.take(4).toList();
    final extra = math.max(0, list.length - shown.length);

    return Row(
      children: [
        ...shown.map(
          (url) => Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 54,
                height: 54,
                color: scheme.surfaceVariant.withOpacity(0.35),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _thumbFallback(scheme),
                ),
              ),
            ),
          ),
        ),
        if (extra > 0)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: scheme.surfaceVariant.withOpacity(0.35),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (shown.isNotEmpty)
                    Image.network(
                      shown.last,
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.35),
                      colorBlendMode: BlendMode.darken,
                      errorBuilder: (_, __, ___) => _thumbFallback(scheme),
                    )
                  else
                    _thumbFallback(scheme),
                  Center(
                    child: Text(
                      "+$extra",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _thumbFallback(ColorScheme scheme) {
    return Center(
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedImageNotFound01,
        size: 18,
        color: scheme.onSurface.withOpacity(0.35),
      ),
    );
  }
}

/* ----------------------------- RATING (COMPACT) ----------------------------- */

class _RatingCompact extends StatelessWidget {
  final double rating;
  final int reviews;
  const _RatingCompact({required this.rating, required this.reviews});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: 18, color: Colors.amber.shade600),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: scheme.onSurface.withOpacity(0.82),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          "($reviews)",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: scheme.onSurface.withOpacity(0.55),
          ),
        ),
      ],
    );
  }
}

/* ----------------------------- ROUND ICON BUTTON ----------------------------- */

class _RoundIconButton extends StatelessWidget {
  final dynamic icon;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface.withOpacity(0.86),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: HugeIcon(
            icon: icon,
            size: 22,
            color: scheme.onSurface.withOpacity(0.85),
          ),
        ),
      ),
    );
  }
}

/* ----------------------------- RESERVE CTA ----------------------------- */

class _ReserveCTAButton extends StatefulWidget {
  final String label;
  final bool busy;
  final VoidCallback? onTap;

  const _ReserveCTAButton({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  @override
  State<_ReserveCTAButton> createState() => _ReserveCTAButtonState();
}

class _ReserveCTAButtonState extends State<_ReserveCTAButton> {
  bool _pressed = false;

  void _setPressed(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        scale: _pressed ? 0.992 : 1,
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary,
                scheme.primary.withOpacity(0.88),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withOpacity(0.22),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: widget.busy
                  ? const _PremiumDotsLoader(key: ValueKey("dots"))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedCalendarCheckIn01,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.label.toUpperCase(),
                          key: const ValueKey("label"),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: Colors.white,
                            letterSpacing: 0.5,
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

/* ----------------------------- LOADER ----------------------------- */

class _PremiumDotsLoader extends StatefulWidget {
  const _PremiumDotsLoader({super.key});

  @override
  State<_PremiumDotsLoader> createState() => _PremiumDotsLoaderState();
}

class _PremiumDotsLoaderState extends State<_PremiumDotsLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = i * 0.18;
            final v = (t - phase);
            final pulse =
                (0.5 + 0.5 * (1 - math.cos(v * 2 * math.pi))).clamp(0.0, 1.0);
            final size = 6 + 4 * pulse;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: scheme.onPrimary,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/* ----------------------------- STATES ----------------------------- */

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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedWifiError01,
              size: 34,
              color: scheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(t(lang, "common.try_again")),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageSkeleton extends StatelessWidget {
  const _PageSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                height: 24,
                width: 220,
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 240,
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
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
