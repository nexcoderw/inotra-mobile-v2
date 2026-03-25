import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:intl/intl.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../../core/config/api.dart";
import "../../../../../core/constants/api/my_event_endpoints.dart";
import "../../../../../core/services/auth_session.dart";
import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";
import "../../../../main/presentation/widgets/page_header.dart";

class MyEventSubmissionDetailArgs {
  final String submissionId;
  final String? title;

  const MyEventSubmissionDetailArgs({required this.submissionId, this.title});
}

class MyEventSubmissionDetailPage extends StatefulWidget {
  final String? submissionId;
  final String? title;

  const MyEventSubmissionDetailPage({super.key, this.submissionId, this.title});

  @override
  State<MyEventSubmissionDetailPage> createState() =>
      _MyEventSubmissionDetailPageState();
}

class _MyEventSubmissionDetailPageState
    extends State<MyEventSubmissionDetailPage> {
  bool _loading = true;
  String? _error;
  _EventSubmissionDetail? _detail;

  String get _lang => currentLangSync();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  MyEventSubmissionDetailArgs? get _routeArgs {
    final raw = ModalRoute.of(context)?.settings.arguments;
    if (raw is MyEventSubmissionDetailArgs) return raw;
    return null;
  }

  String? get _submissionId => widget.submissionId ?? _routeArgs?.submissionId;

  String get _resolvedTitle {
    final candidates = [
      _detail?.title,
      widget.title,
      _routeArgs?.title,
      t(_lang, "nav.my_event_submissions"),
    ];
    for (final value in candidates) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return t(_lang, "nav.my_event_submissions");
  }

  Future<void> _fetch() async {
    final submissionId = _submissionId;
    if (submissionId == null || submissionId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = t(_lang, "my_events.submissions_load_failed");
      });
      return;
    }

    final valid = await AuthSession.instance.ensureValid();
    if (!valid) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = t(_lang, "my_events.submissions_session_expired");
      });
      return;
    }

    final token = AuthSession.instance.value.accessToken;
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = t(_lang, "my_events.submissions_session_expired");
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Api.url(MyEventEndpoints.submissionDetail(submissionId));
      final resp = await http.get(
        uri,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (resp.statusCode == 401 || resp.statusCode == 403) {
        await AuthSession.instance.expireSession();
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = t(_lang, "my_events.submissions_session_expired");
        });
        return;
      }

      final decoded = resp.body.isEmpty
          ? null
          : jsonDecode(resp.body) as Object?;

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw _ApiException(
          _extractMessage(decoded) ??
              t(_lang, "my_events.submissions_load_failed"),
        );
      }

      if (decoded is! Map<String, dynamic>) {
        throw const _ApiException("Invalid submission response.");
      }

      if (!mounted) return;
      setState(() {
        _detail = _EventSubmissionDetail.fromJson(decoded);
        _loading = false;
      });
    } on _ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = t(_lang, "my_events.submissions_load_failed");
      });
    }
  }

  String? _extractMessage(Object? decoded) {
    if (decoded is Map && decoded["message"] != null) {
      return decoded["message"].toString();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: _fetch,
      color: scheme.primary,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: _loading
                      ? _DetailSkeleton(title: _resolvedTitle)
                      : (_error != null || _detail == null)
                      ? _DetailErrorState(
                          title: _resolvedTitle,
                          message:
                              _error ??
                              t(_lang, "my_events.submissions_load_failed"),
                          onRetry: _fetch,
                        )
                      : _DetailContent(
                          detail: _detail!,
                          title: _resolvedTitle,
                          lang: _lang,
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

class _DetailContent extends StatelessWidget {
  final _EventSubmissionDetail detail;
  final String title;
  final String lang;

  const _DetailContent({
    required this.detail,
    required this.title,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = <_DetailTabSpec>[
      _DetailTabSpec(
        label: t(lang, "my_events.submissions_tab_overview"),
        child: _OverviewCard(detail: detail, lang: lang),
      ),
      _DetailTabSpec(
        label: t(lang, "my_events.submissions_tab_event"),
        child: _EventInfoTab(detail: detail, lang: lang),
      ),
      _DetailTabSpec(
        label: t(lang, "my_events.submissions_tab_organizer"),
        child: _OrganizerInfoTab(detail: detail, lang: lang),
      ),
      _DetailTabSpec(
        label: t(lang, "my_events.submissions_tab_tickets"),
        child: _TicketCard(tickets: detail.tickets, lang: lang),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: title,
          onBack: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(height: 10),
        _HeroCard(detail: detail, lang: lang),
        const SizedBox(height: 16),
        DefaultTabController(
          length: tabs.length,
          child: Builder(
            builder: (context) {
              final controller = DefaultTabController.of(context);
              final scheme = Theme.of(context).colorScheme;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.42,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.36),
                      ),
                    ),
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      labelColor: scheme.onPrimary,
                      unselectedLabelColor: scheme.onSurface.withValues(
                        alpha: 0.68,
                      ),
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      tabs: tabs.map((tab) => Tab(text: tab.label)).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) {
                      final index = controller.index;
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: KeyedSubtree(
                          key: ValueKey(index),
                          child: tabs[index].child,
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DetailTabSpec {
  final String label;
  final Widget child;

  const _DetailTabSpec({required this.label, required this.child});
}

class _HeroCard extends StatelessWidget {
  final _EventSubmissionDetail detail;
  final String lang;

  const _HeroCard({required this.detail, required this.lang});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = _SubmissionStatusStyle.resolve(detail.status, lang);

    return Container(
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _BannerImage(url: detail.bannerUrl, scheme: scheme),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.18),
                      Colors.black.withValues(alpha: 0.16),
                      Colors.black.withValues(alpha: 0.82),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(top: 16, left: 16, child: _StatusBadge(style: status)),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          detail.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.04,
                            letterSpacing: -0.45,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _HeroPill(
                              icon: Icons.event_available_rounded,
                              label: detail.compactDateLabel(lang),
                            ),
                            _HeroPill(
                              icon: Icons.location_on_rounded,
                              label: detail.venueLocationPill(lang),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final _EventSubmissionDetail detail;
  final String lang;

  const _OverviewCard({required this.detail, required this.lang});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(t(lang, "my_events.submissions_overview")),
          const SizedBox(height: 10),
          Text(
            detail.description?.trim().isNotEmpty == true
                ? detail.description!.trim()
                : t(lang, "my_events.submissions_description_empty"),
            style: TextStyle(
              fontSize: 13.5,
              height: 1.6,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.82),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventInfoTab extends StatelessWidget {
  final _EventSubmissionDetail detail;
  final String lang;

  const _EventInfoTab({required this.detail, required this.lang});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: t(lang, "my_events.submissions_dates"),
      children: [
        _InfoRow(
          icon: Icons.event_rounded,
          label: t(lang, "my_events.submissions_dates"),
          value: detail.fullDateLabel(lang),
        ),
        _InfoRow(
          icon: Icons.place_rounded,
          label: t(lang, "my_events.submissions_venue"),
          value: detail.venueName?.trim().isNotEmpty == true
              ? detail.venueName!.trim()
              : t(lang, "my_events.submissions_no_venue"),
        ),
        _InfoRow(
          icon: Icons.pin_drop_rounded,
          label: t(lang, "my_events.submissions_location"),
          value: detail.locationLabel(lang),
        ),
        if (detail.address?.trim().isNotEmpty == true)
          _InfoRow(
            icon: Icons.route_rounded,
            label: t(lang, "my_events.submissions_address"),
            value: detail.address!.trim(),
          ),
        if (detail.coordinatesLabel != null)
          _InfoRow(
            icon: Icons.my_location_rounded,
            label: t(lang, "my_events.submissions_coordinates"),
            value: detail.coordinatesLabel!,
          ),
      ],
    );
  }
}

class _OrganizerInfoTab extends StatelessWidget {
  final _EventSubmissionDetail detail;
  final String lang;

  const _OrganizerInfoTab({required this.detail, required this.lang});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: t(lang, "my_events.submissions_organizer"),
      children: [
        _InfoRow(
          icon: Icons.badge_rounded,
          label: t(lang, "my_events.submissions_organizer"),
          value: detail.organizerName?.trim().isNotEmpty == true
              ? detail.organizerName!.trim()
              : t(lang, "my_events.submissions_not_available"),
        ),
        _InfoRow(
          icon: Icons.call_rounded,
          label: t(lang, "my_events.submissions_contact"),
          value: detail.organizerContact?.trim().isNotEmpty == true
              ? detail.organizerContact!.trim()
              : t(lang, "my_events.submissions_not_available"),
        ),
        _InfoRow(
          icon: Icons.schedule_rounded,
          label: t(lang, "my_events.submissions_status"),
          value: _submissionStatusLabel(lang, detail.status),
        ),
        _InfoRow(
          icon: Icons.upload_rounded,
          label: t(lang, "my_events.submissions_submitted_on"),
          value: detail.createdAtLabel,
        ),
        _InfoRow(
          icon: Icons.history_toggle_off_rounded,
          label: t(lang, "my_events.submissions_updated_on"),
          value: detail.updatedAtLabel,
        ),
        if (detail.approvedEventId?.trim().isNotEmpty == true)
          _InfoRow(
            icon: Icons.verified_rounded,
            label: t(lang, "my_events.submissions_approved_event"),
            value: detail.approvedEventId!.trim(),
          ),
      ],
    );
  }
}

class _TicketCard extends StatelessWidget {
  final List<_SubmissionTicket> tickets;
  final String lang;

  const _TicketCard({required this.tickets, required this.lang});

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return _InfoCard(
        title: t(lang, "events.tickets"),
        children: [
          Text(
            t(lang, "my_events.submissions_ticket_none"),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.76),
            ),
          ),
        ],
      );
    }

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(t(lang, "events.tickets")),
          const SizedBox(height: 10),
          ...tickets.asMap().entries.map((entry) {
            final ticket = entry.value;
            final isLast = entry.key == tickets.length - 1;

            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: _TicketTile(
                label: ticket.categoryLabel(lang),
                price: ticket.priceLabel(lang),
                consumableDescription: ticket.consumableDescription,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.44),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),
          ...children.expand(
            (child) => [
              child,
              if (child != children.last) const SizedBox(height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: scheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.50),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

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

class _TicketTile extends StatelessWidget {
  final String label;
  final String price;
  final String? consumableDescription;

  const _TicketTile({
    required this.label,
    required this.price,
    this.consumableDescription,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasConsumable =
        consumableDescription != null && consumableDescription!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedTicket02,
            size: 18,
            color: scheme.onSurface.withValues(alpha: 0.78),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface.withValues(alpha: 0.90),
                  ),
                ),
                if (hasConsumable) ...[
                  const SizedBox(height: 2),
                  Text(
                    consumableDescription!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: scheme.primary.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ],
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

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.92)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _SubmissionStatusStyle style;

  const _StatusBadge({required this.style});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: style.backgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: style.borderColor),
          ),
          child: Text(
            style.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: style.textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerImage extends StatelessWidget {
  final String? url;
  final ColorScheme scheme;

  const _BannerImage({required this.url, required this.scheme});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.trim().isNotEmpty) {
      return Image.network(
        url!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _BannerPlaceholder(scheme: scheme),
        loadingBuilder: (_, child, event) =>
            event == null ? child : _BannerPlaceholder(scheme: scheme),
      );
    }
    return _BannerPlaceholder(scheme: scheme);
  }
}

class _BannerPlaceholder extends StatelessWidget {
  final ColorScheme scheme;

  const _BannerPlaceholder({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.30),
            scheme.surfaceContainerHighest.withValues(alpha: 0.86),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.event_note_rounded,
          size: 52,
          color: scheme.onSurface.withValues(alpha: 0.26),
        ),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  final String title;

  const _DetailSkeleton({required this.title});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(title: title),
        const SizedBox(height: 10),
        Container(
          height: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [
                scheme.surfaceContainerHighest.withValues(alpha: 0.70),
                scheme.surfaceContainerHighest.withValues(alpha: 0.38),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              height: 158,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _DetailErrorState({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: title,
          onBack: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: scheme.errorContainer.withValues(alpha: 0.54),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.error.withValues(alpha: 0.22)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.wifi_tethering_error_rounded,
                size: 40,
                color: scheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                t(currentLangSync(), "my_events.submissions_error_title"),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: scheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: scheme.onErrorContainer.withValues(alpha: 0.86),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(t(currentLangSync(), "common.try_again")),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EventSubmissionDetail {
  final String id;
  final String title;
  final String? description;
  final DateTime? startAt;
  final DateTime? endAt;
  final String? venueName;
  final String? address;
  final String? city;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? organizerName;
  final String? organizerContact;
  final String status;
  final String? approvedEventId;
  final String? bannerUrl;
  final _SubmissionTicket? firstTicket;
  final List<_SubmissionTicket> tickets;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const _EventSubmissionDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.startAt,
    required this.endAt,
    required this.venueName,
    required this.address,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.organizerName,
    required this.organizerContact,
    required this.status,
    required this.approvedEventId,
    required this.bannerUrl,
    required this.firstTicket,
    required this.tickets,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _EventSubmissionDetail.fromJson(Map<String, dynamic> json) {
    return _EventSubmissionDetail(
      id: (json["id"] ?? "").toString(),
      title: (json["title"] ?? "").toString(),
      description: json["description"]?.toString(),
      startAt: _parseDate(json["start_at"]),
      endAt: _parseDate(json["end_at"]),
      venueName: json["venue_name"]?.toString(),
      address: json["address"]?.toString(),
      city: json["city"]?.toString(),
      country: json["country"]?.toString(),
      latitude: _parseDouble(json["latitude"]),
      longitude: _parseDouble(json["longitude"]),
      organizerName: json["organizer_name"]?.toString(),
      organizerContact: json["organizer_contact"]?.toString(),
      status: (json["status"] ?? "PENDING").toString(),
      approvedEventId: json["approved_event_id"]?.toString(),
      bannerUrl: json["banner_url"]?.toString(),
      firstTicket: json["first_ticket"] is Map<String, dynamic>
          ? _SubmissionTicket.fromJson(
              json["first_ticket"] as Map<String, dynamic>,
            )
          : null,
      tickets:
          (json["tickets"] as List?)
              ?.whereType<Map>()
              .map(
                (item) =>
                    _SubmissionTicket.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList() ??
          const [],
      createdAt: _parseDate(json["created_at"]),
      updatedAt: _parseDate(json["updated_at"]),
    );
  }

  String compactDateLabel(String lang) {
    if (startAt == null && endAt == null) {
      return t(lang, "my_events.submissions_no_dates");
    }

    if (startAt != null && endAt != null) {
      final sameDay =
          startAt!.year == endAt!.year &&
          startAt!.month == endAt!.month &&
          startAt!.day == endAt!.day;

      if (sameDay) {
        return DateFormat("dd MMM · hh:mm a").format(startAt!);
      }

      return "${DateFormat("dd MMM").format(startAt!)} - ${DateFormat("dd MMM").format(endAt!)}";
    }

    return DateFormat("dd MMM · hh:mm a").format(startAt ?? endAt!);
  }

  String fullDateLabel(String lang) {
    if (startAt == null && endAt == null) {
      return t(lang, "my_events.submissions_no_dates");
    }

    if (startAt != null && endAt != null) {
      return "${DateFormat("EEE, dd MMM yyyy · hh:mm a").format(startAt!)}\n${DateFormat("EEE, dd MMM yyyy · hh:mm a").format(endAt!)}";
    }

    return DateFormat("EEE, dd MMM yyyy · hh:mm a").format(startAt ?? endAt!);
  }

  String locationLabel(String lang) {
    final parts = [
      if (city?.trim().isNotEmpty == true) city!.trim(),
      if (country?.trim().isNotEmpty == true) country!.trim(),
    ];
    if (parts.isEmpty) return t(lang, "my_events.submissions_not_available");
    return parts.join(", ");
  }

  String venueLocationPill(String lang) {
    if (venueName?.trim().isNotEmpty == true) return venueName!.trim();
    return locationLabel(lang);
  }

  String? get coordinatesLabel {
    if (latitude == null || longitude == null) return null;
    return "${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}";
  }

  String get createdAtLabel => _formatAuditDate(createdAt);
  String get updatedAtLabel => _formatAuditDate(updatedAt);

  static String _formatAuditDate(DateTime? value) {
    if (value == null) return "—";
    return DateFormat("dd MMM yyyy · hh:mm a").format(value);
  }
}

class _SubmissionTicket {
  final String category;
  final num? price;
  final bool consumable;
  final String? consumableDescription;

  const _SubmissionTicket({
    required this.category,
    required this.price,
    required this.consumable,
    required this.consumableDescription,
  });

  factory _SubmissionTicket.fromJson(Map<String, dynamic> json) {
    return _SubmissionTicket(
      category: (json["category"] ?? "").toString().trim(),
      price: json["price"] is num
          ? json["price"] as num
          : num.tryParse("${json["price"] ?? ""}"),
      consumable: json["consumable"] == true,
      consumableDescription: json["consumable_description"]?.toString(),
    );
  }

  String categoryLabel(String lang) {
    final normalized = category.trim().toUpperCase();

    switch (normalized) {
      case "FREE":
        return t(lang, "my_events.ticket_free");
      case "REGULAR":
        return t(lang, "my_events.ticket_regular");
      case "VIP":
        return t(lang, "my_events.ticket_vip");
      case "VVIP":
        return t(lang, "my_events.ticket_vvip");
      case "TABLE":
        return t(lang, "my_events.ticket_table");
      default:
        return category.trim().isNotEmpty
            ? category.trim()
            : t(lang, "my_events.submissions_not_available");
    }
  }

  String priceLabel(String lang) {
    if ((price ?? 0) <= 0) return t(lang, "my_events.ticket_free");
    final formatter = NumberFormat("#,###");
    return "Rwf ${formatter.format(price)}";
  }
}

class _SubmissionStatusStyle {
  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const _SubmissionStatusStyle({
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  factory _SubmissionStatusStyle.resolve(String raw, String lang) {
    switch (raw.toUpperCase()) {
      case "APPROVED":
        return _SubmissionStatusStyle(
          label: t(lang, "my_events.submissions_approved"),
          backgroundColor: Colors.green.withValues(alpha: 0.52),
          borderColor: Colors.green.withValues(alpha: 0.36),
          textColor: Colors.white,
        );
      case "REJECTED":
        return _SubmissionStatusStyle(
          label: t(lang, "my_events.submissions_rejected"),
          backgroundColor: Colors.red.withValues(alpha: 0.52),
          borderColor: Colors.red.withValues(alpha: 0.36),
          textColor: Colors.white,
        );
      default:
        return _SubmissionStatusStyle(
          label: t(lang, "my_events.submissions_pending"),
          backgroundColor: Colors.orange.withValues(alpha: 0.52),
          borderColor: Colors.orange.withValues(alpha: 0.36),
          textColor: Colors.white,
        );
    }
  }
}

String _submissionStatusLabel(String lang, String status) {
  return _SubmissionStatusStyle.resolve(status, lang).label;
}

DateTime? _parseDate(Object? raw) {
  final value = raw?.toString();
  if (value == null || value.isEmpty) return null;
  try {
    return DateTime.parse(value).toLocal();
  } catch (_) {
    return null;
  }
}

double? _parseDouble(Object? raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw.toString());
}

class _ApiException implements Exception {
  final String message;

  const _ApiException(this.message);
}
