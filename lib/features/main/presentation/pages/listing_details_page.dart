import "dart:convert";
import "dart:math" as math;
import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;
import "package:toastification/toastification.dart";

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/place_endpoints.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/page_header.dart";
import "../widgets/listing_details_shared.dart";
import "../widgets/listing_details_overview_tab.dart";
import "../widgets/listing_details_map_tab.dart";
import "../widgets/listing_details_reviews_tab.dart";
import "../widgets/listing_details_transport_tab.dart";

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
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
        body: SafeArea(
          child: _loading
              ? const _PageSkeleton()
              : _error != null
                  ? _ErrorState(
                      message: _error!,
                      onRetry: _fetch,
                    )
                  : _place == null
                      ? _ErrorState(
                          message: t(lang, "listings.no_data"),
                          onRetry: _fetch,
                        )
                      : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: PageHeader(
                                title: _place!.name,
                                onBack: () => Navigator.maybePop(context),
                                icon: HugeIcons.strokeRoundedArrowLeft01,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _HeroCarousel(images: _place!.images),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _place!.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      ListingRatingChip(
                                        rating: _place!.rating ?? 0,
                                        reviews: _place!.reviewsCount ?? 0,
                                      ),
                                      const SizedBox(width: 10),
                                      if (_place!.categoryName.isNotEmpty)
                                        ListingPill(
                                          icon: HugeIcons.strokeRoundedHotelBell,
                                          label: _place!.categoryName,
                                        ),
                                      const Spacer(),
                                      ListingPill(
                                        icon: HugeIcons.strokeRoundedMapsLocation02,
                                        label: _place!.city.isNotEmpty
                                            ? "${_place!.city}, ${_place!.country}"
                                            : _place!.country,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            TabBar(
                              labelColor: scheme.primary,
                              unselectedLabelColor: scheme.onSurface.withOpacity(0.6),
                              indicatorColor: scheme.primary,
                              isScrollable: true,
                              tabs: [
                                Tab(text: t(lang, "listings.tab_overview")),
                                Tab(text: t(lang, "listings.tab_map")),
                                Tab(text: t(lang, "listings.tab_reviews")),
                                Tab(text: t(lang, "listings.tab_transport")),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  ListingOverviewTab(place: _place!),
                                  ListingMapTab(place: _place!),
                                  const ListingReviewsTab(),
                                  ListingTransportTab(place: _place!),
                                ],
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
          height: 54,
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
                        const SizedBox(width: 8),
                        Text(
                          widget.label,
                          key: const ValueKey("label"),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: Colors.white,
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

/* ----------------------------- HERO CAROUSEL ----------------------------- */

class _HeroCarousel extends StatefulWidget {
  final List<String> images;
  const _HeroCarousel({required this.images});

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(20);
    final imgs = widget.images.isNotEmpty ? widget.images : [null];

    return Column(
      children: [
        ClipRRect(
          borderRadius: radius,
          child: Container(
            height: 210,
            decoration: BoxDecoration(
              color: scheme.surfaceVariant.withOpacity(0.6),
            ),
            child: PageView.builder(
              itemCount: imgs.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final url = imgs[i];
                if (url == null || url.trim().isEmpty) {
                  return _PlaceholderImage(scheme: scheme);
                }
                return Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _PlaceholderImage(scheme: scheme),
                  loadingBuilder: (_, child, evt) =>
                      evt == null ? child : _PlaceholderImage(scheme: scheme),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            imgs.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: _index == i ? 18 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color:
                    _index == i ? scheme.primary : scheme.onSurface.withOpacity(0.25),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  final ColorScheme scheme;
  const _PlaceholderImage({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: scheme.surfaceVariant.withOpacity(0.7),
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedImageNotFound01,
          color: scheme.onSurface.withOpacity(0.35),
          size: 32,
        ),
      ),
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
                height: 210,
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 16,
                width: 260,
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 16,
                width: 180,
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 24),
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
