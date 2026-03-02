import "dart:async";
import "dart:convert";
import "dart:ui";
import "dart:math" as math;

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
    final id =
        widget.eventId ?? ModalRoute.of(context)?.settings.arguments as String?;
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

    return MainScaffold(
      title: t(lang, "events.details_title"),
      showAppBar: false,
      child: SafeArea(
        child: _loading
            ? const _EventDetailsSkeleton()
            : (_error != null || e == null)
                ? _ErrorState(
                    message: _error ?? t(lang, "common.coming_soon"),
                    onRetry: _fetch,
                  )
                : CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: PageHeader(
                            title: t(lang, "events.details_title"),
                            onBack: () => Navigator.maybePop(context),
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _HeroBanner(
                            url: e.bannerUrl,
                            overlay: Align(
                              alignment: Alignment.bottomLeft,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: _StatusPill(
                                  status: _resolveStatus(e, lang, scheme),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                          child: Text(
                            e.title,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.35,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                          child: _GlassCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                _MetaRow(
                                  icon: HugeIcons.strokeRoundedCalendar02,
                                  label: e.dateRange.isNotEmpty
                                      ? e.dateRange
                                      : t(lang, "listings.no_data"),
                                ),
                                const SizedBox(height: 10),
                                _MetaRow(
                                  icon: HugeIcons.strokeRoundedMapsLocation02,
                                  label: e.venue.isNotEmpty
                                      ? e.venue
                                      : (e.city.isNotEmpty
                                          ? e.city
                                          : t(lang, "listings.no_data")),
                                ),
                                if (e.country.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  _MetaRow(
                                    icon: HugeIcons.strokeRoundedGlobalSearch,
                                    label: e.country,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                      if (e.description.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                            child: _Section(
                              title: t(lang, "listings.overview_title"),
                              child: _GlassCard(
                                padding: const EdgeInsets.all(14),
                                child: Text(
                                  e.description,
                                  style: TextStyle(
                                    height: 1.55,
                                    color: scheme.onSurface.withOpacity(0.82),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          child: _Section(
                            title: t(lang, "listings.address"),
                            subtitle: t(lang, "listings.map_placeholder"),
                            child: _GlassCard(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _GlassIcon(
                                    icon: HugeIcons.strokeRoundedMapsLocation02,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          e.address.isNotEmpty
                                              ? e.address
                                              : t(lang, "listings.no_data"),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: scheme.onSurface
                                                .withOpacity(0.90),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          (e.lat != null && e.lng != null)
                                              ? "${e.lat!.toStringAsFixed(6)}, ${e.lng!.toStringAsFixed(6)}"
                                              : t(lang, "listings.map_placeholder"),
                                          style: TextStyle(
                                            color: scheme.onSurface
                                                .withOpacity(0.60),
                                            fontWeight: FontWeight.w700,
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

                      if (e.tickets.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                            child: _Section(
                              title: t(lang, "events.tickets"),
                              child: Column(
                                children: e.tickets.map((tkt) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _GlassCard(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        children: [
                                          _GlassIcon(
                                            icon:
                                                HugeIcons.strokeRoundedTicket02,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              tkt.label,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: scheme.onSurface
                                                    .withOpacity(0.88),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          _PricePill(label: tkt.priceLabel),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 2, 16, 22),
                          child: _buildCta(context, lang, scheme, e),
                        ),
                      ),
                    ],
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

/* =========================
   Premium UI Building Blocks
   ========================= */

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: scheme.surface.withOpacity(0.16),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                blurRadius: 24,
                offset: const Offset(0, 10),
                color: Colors.black.withOpacity(0.18),
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassIcon extends StatelessWidget {
  final dynamic icon;
  const _GlassIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Center(
        child: HugeIcon(
          icon: icon,
          size: 18,
          color: scheme.onSurface.withOpacity(0.82),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _Section({
    required this.title,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: scheme.onSurface,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              color: scheme.onSurface.withOpacity(0.60),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final String? url;
  final Widget? overlay;
  const _HeroBanner({this.url, this.overlay});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasUrl = url != null && url!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          Container(
            height: 230,
            width: double.infinity,
            color: scheme.surfaceVariant.withOpacity(0.45),
            child: hasUrl
                ? Image.network(
                    url!.trim(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _BannerFallback(scheme: scheme),
                    loadingBuilder: (_, child, evt) =>
                        evt == null ? child : _BannerFallback(scheme: scheme),
                  )
                : _BannerFallback(scheme: scheme),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.18),
              ),
            ),
          ),
          if (overlay != null) Positioned.fill(child: overlay!),
        ],
      ),
    );
  }
}

class _BannerFallback extends StatelessWidget {
  final ColorScheme scheme;
  const _BannerFallback({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedImageNotFound01,
        size: 36,
        color: scheme.onSurface.withOpacity(0.35),
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  final String label;
  const _PricePill({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.primary.withOpacity(0.12),
        border: Border.all(color: scheme.primary.withOpacity(0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: scheme.primary,
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

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: _GlassCard(
          padding: const EdgeInsets.all(18),
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
                  color: scheme.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text("Try again")),
            ],
          ),
        ),
      ),
    );
  }
}

/* =========================
   Skeleton Loader (matches layout)
   ========================= */

class _EventDetailsSkeleton extends StatefulWidget {
  const _EventDetailsSkeleton();

  @override
  State<_EventDetailsSkeleton> createState() => _EventDetailsSkeletonState();
}

class _EventDetailsSkeletonState extends State<_EventDetailsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  double _pulse() {
    // 0.55..0.85
    final t = _ctl.value * 2 * math.pi;
    return 0.55 + (math.sin(t) * 0.15 + 0.15);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _ctl,
      builder: (_, __) {
        final a = _pulse();

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: _SkeletonLine(
                  alpha: a,
                  height: 22,
                  radius: 14,
                  widthFactor: 0.55,
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    height: 230,
                    color: scheme.surfaceVariant.withOpacity(0.35 * a),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonLine(alpha: a, height: 18, radius: 12),
                    const SizedBox(height: 10),
                    _SkeletonLine(
                      alpha: a,
                      height: 18,
                      radius: 12,
                      widthFactor: 0.78,
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: _SkeletonGlassCard(
                  alpha: a,
                  child: Column(
                    children: const [
                      _SkeletonMetaRow(),
                      SizedBox(height: 10),
                      _SkeletonMetaRow(),
                      SizedBox(height: 10),
                      _SkeletonMetaRow(),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonLine(
                      alpha: a,
                      height: 14,
                      radius: 10,
                      widthFactor: 0.36,
                    ),
                    const SizedBox(height: 10),
                    _SkeletonGlassCard(
                      alpha: a,
                      child: Column(
                        children: [
                          _SkeletonLine(alpha: a, height: 12, radius: 10),
                          const SizedBox(height: 8),
                          _SkeletonLine(
                            alpha: a,
                            height: 12,
                            radius: 10,
                            widthFactor: 0.92,
                          ),
                          const SizedBox(height: 8),
                          _SkeletonLine(
                            alpha: a,
                            height: 12,
                            radius: 10,
                            widthFactor: 0.74,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonLine(
                      alpha: a,
                      height: 14,
                      radius: 10,
                      widthFactor: 0.30,
                    ),
                    const SizedBox(height: 6),
                    _SkeletonLine(
                      alpha: a,
                      height: 10,
                      radius: 10,
                      widthFactor: 0.55,
                    ),
                    const SizedBox(height: 10),
                    _SkeletonGlassCard(
                      alpha: a,
                      child: Row(
                        children: [
                          _SkeletonBox(alpha: a, w: 40, h: 40, r: 14),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SkeletonLine(
                                  alpha: a,
                                  height: 12,
                                  radius: 10,
                                  widthFactor: 0.88,
                                ),
                                const SizedBox(height: 8),
                                _SkeletonLine(
                                  alpha: a,
                                  height: 10,
                                  radius: 10,
                                  widthFactor: 0.62,
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonLine(
                      alpha: a,
                      height: 14,
                      radius: 10,
                      widthFactor: 0.26,
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children: List.generate(2, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SkeletonGlassCard(
                            alpha: a,
                            child: Row(
                              children: [
                                _SkeletonBox(alpha: a, w: 40, h: 40, r: 14),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SkeletonLine(
                                    alpha: a,
                                    height: 12,
                                    radius: 10,
                                    widthFactor: 0.62,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _SkeletonBox(alpha: a, w: 84, h: 30, r: 999),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 22),
                child: _SkeletonBox(alpha: a, w: double.infinity, h: 48, r: 14),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SkeletonGlassCard extends StatelessWidget {
  final double alpha;
  final Widget child;
  const _SkeletonGlassCard({required this.alpha, required this.child});

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
            color: scheme.surface.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Opacity(
            opacity: alpha,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SkeletonMetaRow extends StatelessWidget {
  const _SkeletonMetaRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _SkeletonBox(alpha: 1, w: 18, h: 18, r: 6),
        SizedBox(width: 10),
        Expanded(child: _SkeletonLine(alpha: 1, height: 12, radius: 10)),
      ],
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double alpha;
  final double height;
  final double radius;
  final double widthFactor;

  const _SkeletonLine({
    required this.alpha,
    required this.height,
    required this.radius,
    this.widthFactor = 1,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: scheme.surfaceVariant.withOpacity(0.35 * alpha),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double alpha;
  final double w;
  final double h;
  final double r;
  const _SkeletonBox({
    required this.alpha,
    required this.w,
    required this.h,
    required this.r,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.35 * alpha),
        borderRadius: BorderRadius.circular(r),
      ),
    );
  }
}

/* =========================
   Existing widgets (kept)
   ========================= */

class _MetaRow extends StatelessWidget {
  final dynamic icon;
  final String label;
  const _MetaRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        HugeIcon(icon: icon, size: 16, color: scheme.onSurface.withOpacity(0.80)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface.withOpacity(0.88),
            ),
          ),
        ),
      ],
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
    final bg = filled ? scheme.primary : scheme.surfaceVariant.withOpacity(0.60);
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
    bg: scheme.surfaceVariant.withOpacity(0.55),
    fg: scheme.onSurface.withOpacity(0.90),
  );
}

class _StatusPill extends StatelessWidget {
  final _StatusMeta status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: status.bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: status.fg.withOpacity(0.22)),
          ),
          child: Text(
            status.label,
            style: TextStyle(
              color: status.fg,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

/* =========================
   Models (kept)
   ========================= */

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