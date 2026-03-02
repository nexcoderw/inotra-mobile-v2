import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;
import "package:intl/intl.dart";

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/event_endpoints.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/main_scaffold.dart";

class EventDetailsPage extends StatefulWidget {
  final String? eventId;
  const EventDetailsPage({super.key, this.eventId});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  bool _loading = true;
  String? _error;
  _EventDetail? _event;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    final id = widget.eventId ??
        ModalRoute.of(context)?.settings.arguments as String?;
    if (id == null || id.isEmpty) {
      setState(() {
        _loading = false;
        _error = "Missing event id";
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

  // Plug your real actions here
  void _onOpenMap(_EventDetail e) {
    // TODO: integrate maps launcher in your project
    // Example: open Google Maps with lat/lng or query address
  }

  void _onPrimaryAction(_EventDetail e) {
    // TODO: navigate to ticket purchase / booking
  }

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    final e = _event;
    final hasData = !_loading && _error == null && e != null;

    return MainScaffold(
      title: t(lang, "events.details_title"),
      child: Stack(
        children: [
          // Body
          Positioned.fill(
            child: _loading
                ? const _PremiumLoader()
                : (_error != null || e == null)
                    ? _PremiumError(
                        message: _error ?? t(lang, "common.coming_soon"),
                        onRetry: _fetch,
                      )
                    : CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 14, 16, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _BannerCard(event: e),
                                  const SizedBox(height: 14),

                                  // Title + meta chips
                                  Text(
                                    e.title,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      _MetaChip(
                                        icon: HugeIcons.strokeRoundedCalendar02,
                                        label: e.dateRange.isNotEmpty
                                            ? e.dateRange
                                            : t(lang, "listings.no_data"),
                                      ),
                                      _MetaChip(
                                        icon: HugeIcons.strokeRoundedMapsLocation02,
                                        label: e.venue.isNotEmpty
                                            ? e.venue
                                            : (e.city.isNotEmpty
                                                ? e.city
                                                : t(lang, "listings.no_data")),
                                      ),
                                      if (e.country.isNotEmpty)
                                        _MetaChip(
                                          icon:
                                              HugeIcons.strokeRoundedGlobalSearch,
                                          label: e.country,
                                        ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Overview
                                  if (e.description.isNotEmpty) ...[
                                    _SectionHeader(
                                      title: t(lang, "listings.overview_title"),
                                      icon: HugeIcons.strokeRoundedNote01,
                                    ),
                                    const SizedBox(height: 10),
                                    _GlassCard(
                                      child: Text(
                                        e.description,
                                        style: TextStyle(
                                          height: 1.55,
                                          fontWeight: FontWeight.w600,
                                          color: scheme.onSurface
                                              .withOpacity(0.86),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // Address
                                  _SectionHeader(
                                    title: t(lang, "listings.address"),
                                    icon: HugeIcons.strokeRoundedMapsLocation02,
                                    trailing: (e.lat != null && e.lng != null)
                                        ? Text(
                                            "${e.lat!.toStringAsFixed(6)}, ${e.lng!.toStringAsFixed(6)}",
                                            style: TextStyle(
                                              color: scheme.onSurface
                                                  .withOpacity(0.65),
                                              fontWeight: FontWeight.w800,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(height: 10),
                                  _InfoRowCard(
                                    icon: HugeIcons.strokeRoundedMapsLocation02,
                                    title: e.address.isNotEmpty
                                        ? e.address
                                        : t(lang, "listings.no_data"),
                                    subtitle: e.venue.isNotEmpty ? e.venue : null,
                                    onTap: (e.lat != null && e.lng != null) ||
                                            e.address.isNotEmpty
                                        ? () => _onOpenMap(e)
                                        : null,
                                    trailing: (e.lat != null && e.lng != null) ||
                                            e.address.isNotEmpty
                                        ? _MiniPill(
                                            label: t(lang, "listings.map_placeholder"),
                                            icon: HugeIcons.strokeRoundedNavigation03,
                                          )
                                        : _MiniPill(
                                            label: t(lang, "listings.no_data"),
                                            icon: HugeIcons.strokeRoundedInformationCircle,
                                          ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Tickets
                                  if (e.tickets.isNotEmpty) ...[
                                    _SectionHeader(
                                      title: t(lang, "events.tickets"),
                                      icon: HugeIcons.strokeRoundedTicket02,
                                    ),
                                    const SizedBox(height: 10),
                                    Column(
                                      children: e.tickets.map((tkt) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 10),
                                          child: _TicketCard(ticket: tkt),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 88), // room for bottom bar
                                  ] else ...[
                                    const SizedBox(height: 88),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
          ),

          // Bottom glass action bar
          if (hasData)
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: SafeArea(
                top: false,
                child: _BottomGlassBar(
                  child: Row(
                    children: [
                      Expanded(
                        child: _PrimaryButton(
                          label: e!.tickets.isNotEmpty ? "Buy tickets" : "Attend",
                          icon: HugeIcons.strokeRoundedTicket02,
                          onTap: () => _onPrimaryAction(e),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _IconActionButton(
                        tooltip: "Open map",
                        icon: HugeIcons.strokeRoundedNavigation03,
                        onTap: () => _onOpenMap(e),
                        enabled: (e.lat != null && e.lng != null) ||
                            e.address.isNotEmpty,
                      ),
                      const SizedBox(width: 10),
                      _IconActionButton(
                        tooltip: "Close",
                        icon: HugeIcons.strokeRoundedCancel02,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/* ----------------------------- Premium UI ----------------------------- */

class _PremiumLoader extends StatelessWidget {
  const _PremiumLoader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: _GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Loading…",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PremiumError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  color: scheme.onSurface.withOpacity(0.85),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _SecondaryButton(
                label: "Try again",
                icon: HugeIcons.strokeRoundedRotate360,
                onTap: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final _EventDetail event;
  const _BannerCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final url = (event.bannerUrl ?? "").trim();
    final hasUrl = url.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 220,
        width: double.infinity,
        color: scheme.surfaceVariant.withOpacity(0.45),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasUrl)
              Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _BannerFallback(scheme: scheme),
                loadingBuilder: (_, child, evt) =>
                    evt == null ? child : _BannerFallback(scheme: scheme),
              )
            else
              _BannerFallback(scheme: scheme),

            // Subtle dark overlay (NOT gradient)
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.18),
              ),
            ),

            // Bottom glass label
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedSparkles,
                      size: 18,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Event highlight",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: scheme.onSurface.withOpacity(0.88),
                        ),
                      ),
                    ),
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

class _BannerFallback extends StatelessWidget {
  final ColorScheme scheme;
  const _BannerFallback({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: scheme.surfaceVariant.withOpacity(0.55),
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedImageNotFound01,
          size: 40,
          color: scheme.onSurface.withOpacity(0.35),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final dynamic icon;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        HugeIcon(
          icon: icon,
          size: 18,
          color: scheme.onSurface.withOpacity(0.78),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final dynamic icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: 999,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: icon,
            size: 16,
            color: scheme.onSurface.withOpacity(0.78),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface.withOpacity(0.86),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRowCard extends StatelessWidget {
  final dynamic icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _InfoRowCard({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _GlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: scheme.surface.withOpacity(0.22),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: icon,
                    size: 18,
                    color: scheme.onSurface.withOpacity(0.78),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface.withOpacity(0.88),
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface.withOpacity(0.62),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final _Ticket ticket;
  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: scheme.surface.withOpacity(0.22),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedTicket02,
                  size: 18,
                  color: scheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface.withOpacity(0.88),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ticket.consumable
                        ? (ticket.consumableDescription?.isNotEmpty == true
                            ? ticket.consumableDescription!
                            : "Consumable ticket")
                        : "Standard ticket",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withOpacity(0.62),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),
            Text(
              ticket.priceLabel,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final dynamic icon;
  const _MiniPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: icon,
            size: 16,
            color: scheme.onSurface.withOpacity(0.75),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface.withOpacity(0.78),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomGlassBar extends StatelessWidget {
  final Widget child;
  const _BottomGlassBar({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: scheme.surface.withOpacity(0.18),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
            boxShadow: [
              BoxShadow(
                blurRadius: 22,
                spreadRadius: 1,
                offset: const Offset(0, 12),
                color: Colors.black.withOpacity(0.20),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final dynamic icon;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: scheme.primary.withOpacity(0.16),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.primary.withOpacity(0.26)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(icon: icon, size: 18, color: scheme.primary),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final dynamic icon;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: scheme.surface.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: icon,
              size: 18,
              color: scheme.onSurface.withOpacity(0.82),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: scheme.onSurface.withOpacity(0.82),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final String tooltip;
  final dynamic icon;
  final VoidCallback onTap;
  final bool enabled;

  const _IconActionButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: scheme.surface.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.14)),
            ),
            child: Center(
              child: HugeIcon(
                icon: icon,
                size: 20,
                color: scheme.onSurface.withOpacity(0.84),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderRadius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: scheme.surface.withOpacity(0.16),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 10),
                color: Colors.black.withOpacity(0.12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/* ------------------------------- Models ------------------------------- */

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

  String get priceLabel {
    if (price == null || price == 0) return "Free";
    return "Rwf ${price!.toStringAsFixed(0)}";
  }

  factory _Ticket.fromJson(Map<String, dynamic> json) {
    return _Ticket(
      id: (json["id"] ?? "").toString(),
      category: (json["category"] ?? "").toString(),
      price: (json["price"] as num?)?.toDouble(),
      consumable: json["consumable"] == true,
      consumableDescription: (json["consumable_description"] ?? "").toString(),
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
    final sameDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
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

    final banner = (json["banner_url"] ?? json["cover_url"] ?? "").toString();
    return _EventDetail(
      id: (json["id"] ?? "").toString(),
      title: (json["title"] ?? json["name"] ?? "").toString(),
      description: (json["description"] ?? "").toString(),
      bannerUrl: banner.isEmpty ? null : banner,
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