import "dart:convert";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;
import "package:intl/intl.dart";
import "package:toastification/toastification.dart";

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/event_endpoints.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../../../auth/presentation/widgets/quick_login_dialog.dart";
import "../widgets/main_scaffold.dart";
import "../widgets/page_header.dart";

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
    final id = widget.eventId ?? ModalRoute.of(context)?.settings.arguments as String?;
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

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    final e = _event;
    final hasData = !_loading && _error == null && e != null;

    return MainScaffold(
      title: t(lang, "events.details_title"),
      showAppBar: false,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null || e == null)
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedWifiError01,
                        size: 28,
                        color: scheme.error,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error ?? t(lang, "common.coming_soon"),
                        style: TextStyle(
                          color: scheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(onPressed: _fetch, child: Text(t(lang, "common.try_again"))),
                    ],
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PageHeader(
                          title: t(lang, "events.details_title"),
                          onBack: () => Navigator.maybePop(context),
                        ),

                        _StatusPill(status: _resolveStatus(e, lang, scheme)),
                        const SizedBox(height: 12),

                        _BannerImage(url: e.bannerUrl),
                        const SizedBox(height: 14),

                        Text(
                          e.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 10),

                        _MetaRow(
                          icon: HugeIcons.strokeRoundedCalendar02,
                          label: e.dateRange.isNotEmpty ? e.dateRange : t(lang, "listings.no_data"),
                        ),
                        const SizedBox(height: 6),
                        _MetaRow(
                          icon: HugeIcons.strokeRoundedMapsLocation02,
                          label: e.venue.isNotEmpty
                              ? e.venue
                              : (e.city.isNotEmpty ? e.city : t(lang, "listings.no_data")),
                        ),
                        if (e.country.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _MetaRow(
                            icon: HugeIcons.strokeRoundedGlobalSearch,
                            label: e.country,
                          ),
                        ],

                        const SizedBox(height: 16),

                        if (e.description.isNotEmpty) ...[
                          Text(
                            t(lang, "listings.overview_title"),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            e.description,
                            style: TextStyle(
                              height: 1.5,
                              color: scheme.onSurface.withOpacity(0.82),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        Text(
                          t(lang, "listings.address"),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t(lang, "listings.map_placeholder"),
                          style: TextStyle(
                            color: scheme.onSurface.withOpacity(0.65),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _InfoCard(
                          icon: HugeIcons.strokeRoundedMapsLocation02,
                          label:
                              e.address.isNotEmpty ? e.address : t(lang, "listings.no_data"),
                          trailing: (e.lat != null && e.lng != null)
                              ? Text(
                                  "${e.lat!.toStringAsFixed(6)}, ${e.lng!.toStringAsFixed(6)}",
                                  style: TextStyle(
                                    color: scheme.onSurface.withOpacity(0.65),
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : Text(
                                  t(lang, "listings.map_placeholder"),
                                  style: TextStyle(
                                    color: scheme.onSurface.withOpacity(0.55),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 14),

                        if (e.tickets.isNotEmpty) ...[
                          Text(
                            t(lang, "events.tickets"),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children: e.tickets
                                .map(
                                  (tkt) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _InfoCard(
                                      icon: HugeIcons.strokeRoundedTicket02,
                                      label: tkt.label,
                                      trailing: Text(
                                        tkt.priceLabel,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: scheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 14),
                        ],

                        _buildCta(context, lang, scheme, e),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildCta(
    BuildContext context,
    String lang,
    ColorScheme scheme,
    _EventDetail e,
  ) {
    final status = _resolveStatus(e, lang, scheme);
    final authed = AuthSession.instance.value.isAuthenticated;

    if (status.ended) return const SizedBox.shrink();

    if (!authed) {
      return _PrimaryCtaButton(
        label: t(lang, "listings.login_to_proceed"),
        icon: HugeIcons.strokeRoundedLogin03,
        filled: false,
        busy: _authBusy,
        onTap: () async {
          setState(() => _authBusy = true);
          await QuickLoginDialog.show(context);
          setState(() => _authBusy = false);
          if (AuthSession.instance.value.isAuthenticated) {
            if (mounted) await _fetch();
          }
        },
      );
    }

    return _PrimaryCtaButton(
      label: t(lang, "events.buy_ticket"),
      icon: HugeIcons.strokeRoundedTicket02,
      onTap: () {
        toastification.show(
          context: context,
          type: ToastificationType.info,
          title: Text(t(lang, "common.coming_soon")),
          autoCloseDuration: const Duration(seconds: 3),
        );
      },
    );
  }
}

class _BannerImage extends StatelessWidget {
  final String? url;
  const _BannerImage({this.url});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasUrl = url != null && url!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: hasUrl
          ? Image.network(
              url!.trim(),
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _BannerFallback(scheme: scheme),
              loadingBuilder: (_, child, evt) =>
                  evt == null ? child : _BannerFallback(scheme: scheme),
            )
          : _BannerFallback(scheme: scheme),
    );
  }
}

class _BannerFallback extends StatelessWidget {
  final ColorScheme scheme;
  const _BannerFallback({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      color: scheme.surfaceVariant.withOpacity(0.6),
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedImageNotFound01,
          size: 36,
          color: scheme.onSurface.withOpacity(0.35),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final dynamic icon;
  final String label;
  const _MetaRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        HugeIcon(icon: icon, size: 16, color: scheme.onSurface.withOpacity(0.75)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withOpacity(0.85),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final dynamic icon;
  final String label;
  final Widget? trailing;
  const _InfoCard({required this.icon, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surfaceVariant.withOpacity(0.45),
      ),
      child: Row(
        children: [
          HugeIcon(icon: icon, size: 18, color: scheme.onSurface.withOpacity(0.75)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withOpacity(0.85),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _PrimaryCtaButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = filled ? scheme.primary : scheme.surfaceVariant.withOpacity(0.6);
    final fg = filled ? scheme.onPrimary : scheme.onSurface;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: busy ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: busy
            ? SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fg,
                ),
              )
            : HugeIcon(
                icon: icon,
                size: 18,
                color: fg,
              ),
        label: Text(label),
      ),
    );
  }
}

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
      bg: Colors.red.withOpacity(0.12),
      fg: Colors.red.shade700,
      ended: true,
    );
  }

  if (e.startAt != null) {
    final startDay = DateTime(e.startAt!.year, e.startAt!.month, e.startAt!.day);
    if (startDay == today) {
      return _StatusMeta(
        label: t(lang, "events.status_happening"),
        bg: Colors.green.withOpacity(0.14),
        fg: Colors.green.shade700,
      );
    }
    final tomorrow = today.add(const Duration(days: 1));
    if (startDay == tomorrow) {
      return _StatusMeta(
        label: t(lang, "events.status_tomorrow"),
        bg: scheme.primary.withOpacity(0.12),
        fg: scheme.primary,
      );
    }
  }

  return _StatusMeta(
    label: t(lang, "events.status_happening"),
    bg: scheme.surfaceVariant.withOpacity(0.6),
    fg: scheme.onSurface,
  );
}

class _StatusPill extends StatelessWidget {
  final _StatusMeta status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: status.bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: status.fg.withOpacity(0.25)),
        ),
        child: Text(
          status.label,
          style: TextStyle(
            color: status.fg,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

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
    final sameDay = start.year == end.year && start.month == end.month && start.day == end.day;
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
