import "dart:async";
import "dart:convert";

import "dart:math" as math;
import "dart:ui";

import "package:flutter/material.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;
import "package:intl/intl.dart";
import "package:map_launcher/map_launcher.dart" as launcher;
import "package:toastification/toastification.dart";

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/event_endpoints.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../../../auth/presentation/widgets/quick_login_dialog.dart";
import "../widgets/main_scaffold.dart";

class EventDetailsPage extends StatefulWidget {
  final String? eventId;
  const EventDetailsPage({super.key, this.eventId});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  bool _loading = true;
  bool _authBusy = false;
  String? _error;
  _EventDetail? _event;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    final id =
        widget.eventId ?? ModalRoute.of(context)?.settings.arguments as String?;
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
      final uri = Api.url(EventEndpoints.detail(id));
      final resp = await http.get(uri, headers: {"Accept": "application/json"});
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        _event = _EventDetail.fromJson(decoded);
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
    final e = _event;

    return MainScaffold(
      title: t(lang, "events.details_title"),
      showAppBar: false,
      child: SafeArea(
        child: _loading
            ? const _EventDetailsSkeleton()
            : (_error != null || e == null)
                ? _PremiumErrorState(
                    message: _error ?? t(lang, "common.coming_soon"),
                    onRetry: _fetch,
                  )
                : _EventDetailsBody(
                    event: e,
                    lang: lang,
                    scheme: scheme,
                    authBusy: _authBusy,
                    onLogin: () async {
                      setState(() => _authBusy = true);
                      await QuickLoginDialog.show(context);
                      setState(() => _authBusy = false);
                      if (AuthSession.instance.value.isAuthenticated) {
                        if (mounted) await _fetch();
                      }
                    },
                    onBuy: () {
                      toastification.show(
                        context: context,
                        type: ToastificationType.info,
                        title: Text(t(lang, "common.coming_soon")),
                        autoCloseDuration: const Duration(seconds: 3),
                      );
                    },
                    onBack: () => Navigator.maybePop(context),
                    onRefresh: _fetch,
                  ),
      ),
    );
  }
}

/* ----------------------------- Premium Body ----------------------------- */

class _EventDetailsBody extends StatelessWidget {
  final _EventDetail event;
  final String lang;
  final ColorScheme scheme;
  final bool authBusy;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final Future<void> Function() onLogin;
  final VoidCallback onBuy;

  const _EventDetailsBody({
    required this.event,
    required this.lang,
    required this.scheme,
    required this.authBusy,
    required this.onBack,
    required this.onRefresh,
    required this.onLogin,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final status = _resolveStatus(event, lang, scheme);

    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _HeroBanner(
                url: event.bannerUrl,
                title: event.title,
                status: status,
                onBack: onBack,
                onRefresh: onRefresh,
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle(t(lang, "events.details_title")),
                          const SizedBox(height: 10),
                          _MetaLine(
                            icon: HugeIcons.strokeRoundedCalendar02,
                            label: event.dateRange.isNotEmpty
                                ? event.dateRange
                                : t(lang, "listings.no_data"),
                          ),
                          const SizedBox(height: 8),
                          _MetaLine(
                            icon: HugeIcons.strokeRoundedMapsLocation02,
                            label: event.venue.isNotEmpty
                                ? event.venue
                                : (event.city.isNotEmpty
                                    ? event.city
                                    : t(lang, "listings.no_data")),
                          ),
                          if (event.country.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _MetaLine(
                              icon: HugeIcons.strokeRoundedGlobalSearch,
                              label: event.country,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (event.description.isNotEmpty) ...[
                      _GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle(t(lang, "listings.overview_title")),
                            const SizedBox(height: 8),
                            Text(
                              event.description,
                              style: TextStyle(
                                height: 1.6,
                                fontSize: 12,
                                color: scheme.onSurface.withValues(alpha: 0.82),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    _EventMapSection(event: event, lang: lang, scheme: scheme),

                    if (event.tickets.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle(t(lang, "events.tickets")),
                            const SizedBox(height: 10),
                            ...event.tickets.map(
                              (tkt) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _TicketTile(
                                  label: tkt.label,
                                  price: tkt.priceLabel(lang),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),

        // Sticky CTA bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _BottomCtaBar(
            status: status,
            lang: lang,
            scheme: scheme,
            authBusy: authBusy,
            onLogin: onLogin,
            onBuy: onBuy,
          ),
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final String? url;
  final String title;
  final _StatusMeta status;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const _HeroBanner({
    required this.url,
    required this.title,
    required this.status,
    required this.onBack,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasUrl = url != null && url!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            SizedBox(
              height: 300,
              width: double.infinity,
              child: hasUrl
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        // Blurred background fills letterbox areas
                        ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                          child: Image.network(
                            url!.trim(),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                        ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
                        // Full image, no cropping
                        Image.network(
                          url!.trim(),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              _BannerFallback(scheme: scheme),
                          loadingBuilder: (_, child, evt) =>
                              evt == null ? child : _BannerFallback(scheme: scheme),
                        ),
                      ],
                    )
                  : _BannerFallback(scheme: scheme),
            ),

            // subtle darkening (no gradient)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                ),
              ),
            ),

            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: Row(
                children: [
                  _GlassIconButton(
                    tooltip: t(currentLangSync(), "nav.back"),
                    icon: HugeIcons.strokeRoundedArrowLeft01,
                    onTap: onBack,
                  ),
                  const Spacer(),
                  _GlassIconButton(
                    tooltip: t(currentLangSync(), "common.try_again"),
                    icon: HugeIcons.strokeRoundedRefresh,
                    onTap: onRefresh,
                  ),
                ],
              ),
            ),

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
                          color: Colors.white.withValues(alpha: 0.96),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _StatusPill(status: status),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomCtaBar extends StatelessWidget {
  final _StatusMeta status;
  final String lang;
  final ColorScheme scheme;
  final bool authBusy;
  final Future<void> Function() onLogin;
  final VoidCallback onBuy;

  const _BottomCtaBar({
    required this.status,
    required this.lang,
    required this.scheme,
    required this.authBusy,
    required this.onLogin,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final authed = AuthSession.instance.value.isAuthenticated;
    if (status.ended) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: _GlassBar(
          child: _PrimaryCtaButton(
            label: !authed
                ? t(lang, "listings.login_to_proceed")
                : t(lang, "events.buy_ticket"),
            icon: !authed
                ? HugeIcons.strokeRoundedLogin03
                : HugeIcons.strokeRoundedTicket02,
            filled: authed,
            busy: authBusy,
            onTap: () async {
              if (!authed) {
                await onLogin();
                return;
              }
              onBuy();
            },
          ),
        ),
      ),
    );
  }
}

/* ----------------------------- Event Map Section ----------------------------- */

class _EventMapSection extends StatelessWidget {
  final _EventDetail event;
  final String lang;
  final ColorScheme scheme;

  const _EventMapSection({
    required this.event,
    required this.lang,
    required this.scheme,
  });

  Future<void> _openExternalMaps(BuildContext context) async {
    final lat = event.lat;
    final lng = event.lng;

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(lang, "listings.no_data"))),
      );
      return;
    }

    final coords = launcher.Coords(lat, lng);
    final title = event.title.isNotEmpty ? event.title : "Event";

    final availableMaps = await launcher.MapLauncher.installedMaps;

    if (!context.mounted) return;

    if (availableMaps.isEmpty) {
      await launcher.MapLauncher.showDirections(
        mapType: launcher.MapType.google,
        destination: coords,
        destinationTitle: title,
      );
      return;
    }

    final googleMapApp = availableMaps
        .where((m) => m.mapType == launcher.MapType.google)
        .cast<launcher.AvailableMap?>()
        .fold<launcher.AvailableMap?>(null, (prev, curr) => curr ?? prev);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: scheme.surface,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              ListTile(
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedMapsLocation02,
                  size: 22,
                  color: scheme.primary,
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface.withValues(alpha: 0.92),
                  ),
                ),
                subtitle: Text(
                  "${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.70),
                  ),
                ),
              ),
              Divider(height: 0, color: scheme.onSurface.withValues(alpha: 0.08)),

              if (googleMapApp != null)
                ListTile(
                  leading: HugeIcon(
                    icon: HugeIcons.strokeRoundedMapsLocation02,
                    size: 22,
                    color: scheme.onSurface.withValues(alpha: 0.70),
                  ),
                  title: Text(
                    "Google Maps",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.90),
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await launcher.MapLauncher.showDirections(
                      mapType: launcher.MapType.google,
                      destination: coords,
                      destinationTitle: title,
                    );
                  },
                ),

              ...availableMaps.where((m) => m != googleMapApp).map((m) {
                return ListTile(
                  leading: HugeIcon(
                    icon: HugeIcons.strokeRoundedMapsLocation02,
                    size: 22,
                    color: scheme.onSurface.withValues(alpha: 0.70),
                  ),
                  title: Text(
                    m.mapName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.90),
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await m.showMarker(
                      coords: coords,
                      title: title,
                      description: event.address,
                    );
                  },
                );
              }),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lat = event.lat;
    final lng = event.lng;
    final hasCoords = lat != null && lng != null;

    final camera = hasCoords
        ? CameraPosition(target: LatLng(lat, lng), zoom: 15)
        : const CameraPosition(target: LatLng(0, 0), zoom: 1);

    final markers = hasCoords
        ? <Marker>{
            Marker(
              markerId: const MarkerId("event"),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: event.title.isNotEmpty ? event.title : t(lang, "listings.address"),
                snippet: event.address,
              ),
            ),
          }
        : <Marker>{};

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(t(lang, "listings.address")),
          const SizedBox(height: 10),
          _InfoRow(
            icon: HugeIcons.strokeRoundedMapsLocation02,
            label: event.address.isNotEmpty
                ? event.address
                : t(lang, "listings.no_data"),
            trailing: hasCoords
                ? Text(
                    "${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}",
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),

          // Map card
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
              child: InkWell(
                onTap: hasCoords ? () => _openExternalMaps(context) : null,
                child: SizedBox(
                  width: double.infinity,
                  height: 220,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: hasCoords
                            ? GoogleMap(
                                initialCameraPosition: camera,
                                markers: markers,
                                zoomControlsEnabled: false,
                                myLocationButtonEnabled: false,
                                mapToolbarEnabled: false,
                                compassEnabled: false,
                                tiltGesturesEnabled: false,
                                rotateGesturesEnabled: false,
                                mapType: MapType.normal,
                              )
                            : Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    HugeIcon(
                                      icon: HugeIcons.strokeRoundedMapsLocation02,
                                      size: 34,
                                      color: scheme.onSurface.withValues(alpha: 0.55),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      t(lang, "listings.map_placeholder"),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: scheme.onSurface.withValues(alpha: 0.6),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),

                      // Subtle border overlay
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: scheme.onSurface.withValues(alpha: 0.10),
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),

                      // Open in maps pill
                      if (hasCoords)
                        Positioned(
                          left: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: scheme.surface.withValues(alpha: 0.90),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: scheme.onSurface.withValues(alpha: 0.10)),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                  color: Colors.black.withValues(alpha: 0.12),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                HugeIcon(
                                  icon: HugeIcons.strokeRoundedArrowUpRight01,
                                  size: 18,
                                  color: scheme.onSurface.withValues(alpha: 0.85),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  t(lang, "listings.open_in_maps"),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
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
        ],
      ),
    );
  }
}

/* ------------------------------ UI building ------------------------------ */

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
  final String tooltip;
  final dynamic icon;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
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
        fontWeight: FontWeight.w900,
        fontSize: 12,
        color: scheme.onSurface.withValues(alpha: 0.92),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final dynamic icon;
  final String label;
  const _MetaLine({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        HugeIcon(icon: icon, size: 16, color: scheme.onSurface.withValues(alpha: 0.78)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.86),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final dynamic icon;
  final String label;
  final Widget? trailing;
  const _InfoRow({required this.icon, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          HugeIcon(icon: icon, size: 18, color: scheme.onSurface.withValues(alpha: 0.78)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withValues(alpha: 0.86),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  final String label;
  final String price;

  const _TicketTile({required this.label, required this.price});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedTicket02,
            size: 18,
            color: scheme.onSurface.withValues(alpha: 0.78),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface.withValues(alpha: 0.90),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            price,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryCtaButton extends StatefulWidget {
  final String label;
  final dynamic icon;
  final VoidCallback? onTap;
  final bool busy;
  final bool filled;

  const _PrimaryCtaButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.busy = false,
    this.filled = true,
  });

  @override
  State<_PrimaryCtaButton> createState() => _PrimaryCtaButtonState();
}

class _PrimaryCtaButtonState extends State<_PrimaryCtaButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (!mounted) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Filled style (primary pill) OR glass style (outline + blur)
    final filledBg = scheme.primary;
    final filledFg = scheme.onPrimary;

    final glassBg = scheme.surface.withValues(alpha: 0.40);
    final glassBorder = scheme.onSurface.withValues(alpha: 0.10);
    final glassFg = scheme.onSurface.withValues(alpha: 0.92);

    final disabled = widget.onTap == null || widget.busy;

    Widget content({required Color fg}) {
      return AnimatedSwitcher(
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
                key: const ValueKey("row"),
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    HugeIcon(
                      icon: widget.icon,
                      size: 18,
                      strokeWidth: 2.2,
                      color: fg,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: fg,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      );
    }

    Widget pillBody() {
      if (widget.filled) {
        // Primary pill (no extra shadow)
        return Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: disabled ? filledBg.withValues(alpha: 0.60) : filledBg,
          ),
          child: Center(child: content(fg: filledFg)),
        );
      }

      // Glass pill (blur + subtle border)
      return ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: disabled ? glassBg.withValues(alpha: 0.65) : glassBg,
              border: Border.all(color: glassBorder),
            ),
            child: Center(child: content(fg: glassFg)),
          ),
        ),
      );
    }

    return GestureDetector(
      onTapDown: disabled ? null : (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: disabled ? null : widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        scale: _pressed ? 0.992 : 1,
        child: SizedBox(
          width: double.infinity,
          child: pillBody(),
        ),
      ),
    );
  }
}

class _PremiumDotsLoader extends StatefulWidget {
  const _PremiumDotsLoader({super.key});

  @override
  State<_PremiumDotsLoader> createState() => _PremiumDotsLoaderState();
}

class _PremiumDotsLoaderState extends State<_PremiumDotsLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;

        double bump(double phase) {
          final x = (t - phase) * 2 * math.pi;
          return (0.5 + 0.5 * (-math.cos(x))).clamp(0.0, 1.0);
        }

        final b1 = bump(0.0);
        final b2 = bump(0.18);
        final b3 = bump(0.36);

        Widget dot(double b) => AnimatedContainer(
              duration: const Duration(milliseconds: 90),
              height: 6 + (b * 4),
              width: 6 + (b * 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75 + b * 0.25),
                borderRadius: BorderRadius.circular(999),
              ),
            );

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dot(b1),
            const SizedBox(width: 7),
            dot(b2),
            const SizedBox(width: 7),
            dot(b3),
          ],
        );
      },
    );
  }
}

/* ------------------------------ Banner pieces ---------------------------- */

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

/* ------------------------------ Error state ------------------------------ */

class _PremiumErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _PremiumErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
              TextButton(onPressed: onRetry, child: Text(t(currentLangSync(), "common.try_again"))),
            ],
          ),
        ),
      ),
    );
  }
}

/* ----------------------------- Skeleton Loader ---------------------------- */

class _EventDetailsSkeleton extends StatefulWidget {
  const _EventDetailsSkeleton();

  @override
  State<_EventDetailsSkeleton> createState() => _EventDetailsSkeletonState();
}

class _EventDetailsSkeletonState extends State<_EventDetailsSkeleton>
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
        final t = _c.value; // 0..1
        final base = scheme.surfaceContainerHighest.withValues(alpha: 0.28);
        final hi = scheme.surfaceContainerHighest.withValues(alpha: 0.45);
        final c = Color.lerp(base, hi, t)!;

        return Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: SizedBox(
                        height: 260,
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
                                              _SkelLine(color: c, w: 180, h: 12),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        _SkelPill(color: c),
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
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        _SkelCard(color: c, child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SkelLine(color: c, w: 140, h: 12),
                            const SizedBox(height: 12),
                            _SkelLine(color: c, w: double.infinity, h: 12),
                            const SizedBox(height: 10),
                            _SkelLine(color: c, w: 260, h: 12),
                            const SizedBox(height: 10),
                            _SkelLine(color: c, w: 160, h: 12),
                          ],
                        )),
                        const SizedBox(height: 12),
                        _SkelCard(color: c, child: Column(
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
                        )),
                        const SizedBox(height: 12),
                        _SkelCard(color: c, child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SkelLine(color: c, w: 90, h: 12),
                            const SizedBox(height: 12),
                            _SkelBox(color: c, h: 52, r: 14),
                            const SizedBox(height: 10),
                            _SkelLine(color: c, w: 170, h: 10),
                          ],
                        )),
                        const SizedBox(height: 12),
                        _SkelCard(color: c, child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SkelLine(color: c, w: 80, h: 12),
                            const SizedBox(height: 12),
                            _SkelBox(color: c, h: 52, r: 14),
                            const SizedBox(height: 10),
                            _SkelBox(color: c, h: 52, r: 14),
                          ],
                        )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: _SkelBox(color: c, h: 48, r: 14),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

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
  const _SkelBox({required this.color, this.h = double.infinity, this.r = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: h == double.infinity ? null : h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(r),
      ),
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
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
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
  const _SkelPill({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

/* ------------------------------ Status Logic ----------------------------- */

class _StatusMeta {
  final String label;
  final Color bg;
  final Color fg;
  final bool ended;
  const _StatusMeta({
    required this.label,
    required this.bg,
    required this.fg,
    this.ended = false,
  });
}

_StatusMeta _resolveStatus(_EventDetail e, String lang, ColorScheme scheme) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  if (e.endAt != null && e.endAt!.isBefore(now)) {
    return _StatusMeta(
      label: t(lang, "events.status_ended"),
      bg: Colors.red.withValues(alpha: 0.14),
      fg: Colors.red.shade700,
      ended: true,
    );
  }

  if (e.startAt != null) {
    final startDay =
        DateTime(e.startAt!.year, e.startAt!.month, e.startAt!.day);
    if (startDay == today) {
      return _StatusMeta(
        label: t(lang, "events.status_happening"),
        bg: Colors.green.withValues(alpha: 0.14),
        fg: Colors.green.shade700,
      );
    }
    final tomorrow = today.add(const Duration(days: 1));
    if (startDay == tomorrow) {
      return _StatusMeta(
        label: t(lang, "events.status_tomorrow"),
        bg: scheme.primary.withValues(alpha: 0.14),
        fg: scheme.primary,
      );
    }
  }

  return _StatusMeta(
    label: t(lang, "events.status_happening"),
    bg: scheme.surfaceContainerHighest.withValues(alpha: 0.40),
    fg: scheme.onSurface.withValues(alpha: 0.85),
  );
}

class _StatusPill extends StatelessWidget {
  final _StatusMeta status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: status.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: status.fg.withValues(alpha: 0.25)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.fg,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

/* ------------------------------ Data Models ------------------------------ */

class _Ticket {
  final String id;
  final String category;
  final double? price;
  final bool consumable;
  final String? consumableDescription;

  _Ticket({
    required this.id,
    required this.category,
    required this.price,
    required this.consumable,
    required this.consumableDescription,
  });

  String get label => category;

  String priceLabel(String lang) {
    if (price == null || price == 0) return t(lang, "events.free");
    return "Rwf ${price!.toStringAsFixed(0)}";
  }

  factory _Ticket.fromJson(Map<String, dynamic> json) {
    return _Ticket(
      id: (json["id"] ?? "").toString(),
      category: (json["category"] ?? "").toString(),
      price: (json["price"] as num?)?.toDouble(),
      consumable: json["consumable"] == true,
      consumableDescription:
          (json["consumable_description"] ?? "").toString(),
    );
  }
}

class _EventDetail {
  final String id;
  final String title;
  final String description;
  final String? bannerUrl;
  final DateTime? startAt;
  final DateTime? endAt;
  final String venue;
  final String address;
  final String city;
  final String country;
  final double? lat;
  final double? lng;
  final List<_Ticket> tickets;

  _EventDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.bannerUrl,
    required this.startAt,
    required this.endAt,
    required this.venue,
    required this.address,
    required this.city,
    required this.country,
    required this.lat,
    required this.lng,
    required this.tickets,
  });

  String get dateRange {
    final start = startAt;
    final end = endAt;
    if (start == null) return "";
    final df = DateFormat("dd MMM yyyy, h:mm a");
    if (end == null) return df.format(start);
    final sameDay =
        start.year == end.year && start.month == end.month && start.day == end.day;
    return sameDay
        ? "${df.format(start)} - ${DateFormat("h:mm a").format(end)}"
        : "${df.format(start)} → ${df.format(end)}";
  }

  factory _EventDetail.fromJson(Map<String, dynamic> json) {
    DateTime? parse(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      try {
        return DateTime.parse(raw).toLocal();
      } catch (_) {
        return null;
      }
    }

    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    final tickets = (json["tickets"] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(_Ticket.fromJson)
            .toList() ??
        [];

    return _EventDetail(
      id: (json["id"] ?? "").toString(),
      title: (json["title"] ?? json["name"] ?? "").toString(),
      description: (json["description"] ?? "").toString(),
      bannerUrl: (json["banner_url"] ?? json["cover_url"] ?? "").toString(),
      startAt: parse(json["start_at"]?.toString()),
      endAt: parse(json["end_at"]?.toString()),
      venue: (json["venue_name"] ?? "").toString(),
      address: (json["address"] ?? "").toString(),
      city: (json["city"] ?? "").toString(),
      country: (json["country"] ?? "").toString(),
      lat: toDouble(json["latitude"]),
      lng: toDouble(json["longitude"]),
      tickets: tickets,
    );
  }
}
