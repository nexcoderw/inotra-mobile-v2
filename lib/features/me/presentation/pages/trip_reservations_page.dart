import "dart:math" as math;

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../core/constants/app_colors.dart";
import "../../../../core/utils/rwf_currency.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class TripReservationsPage extends StatelessWidget {
  const TripReservationsPage({super.key});

  static const _statusStages = [
    _StagePreview(
      label: "Confirmed",
      detail: "Guests with approved itineraries and issued confirmations.",
      count: 68,
      progress: 0.78,
      accent: Color(0xFF0F8F5F),
    ),
    _StagePreview(
      label: "Awaiting Payment",
      detail: "Reservations held while balance collection is in progress.",
      count: 21,
      progress: 0.42,
      accent: Color(0xFFC07A12),
    ),
    _StagePreview(
      label: "Check-in Ready",
      detail: "Arrivals within the next 72 hours with logistics confirmed.",
      count: 14,
      progress: 0.34,
      accent: Color(0xFF1877B8),
    ),
    _StagePreview(
      label: "Completed",
      detail: "Closed trips ready for reporting and payout reconciliation.",
      count: 29,
      progress: 0.58,
      accent: Color(0xFF5E6B7A),
    ),
  ];

  static const _liveModeItems = [
    _LaunchPreview(
      icon: HugeIcons.strokeRoundedSearchList01,
      title: "Search, filters and partner segmentation",
      description:
          "Live endpoints will plug into saved filters for status, travel date, partner and payment stage.",
    ),
    _LaunchPreview(
      icon: HugeIcons.strokeRoundedBubbleChatLock,
      title: "Guest notes and operations context",
      description:
          "Each reservation row is designed to expand into message history, internal notes and handoff actions.",
    ),
    _LaunchPreview(
      icon: HugeIcons.strokeRoundedInvoice03,
      title: "RWF-first billing and reconciliation",
      description:
          "All booking totals, deposit balances and payout summaries are planned in RWF only.",
    ),
    _LaunchPreview(
      icon: HugeIcons.strokeRoundedCalendar03,
      title: "Arrival timelines",
      description:
          "Upcoming departures, reminder triggers and checklist milestones will flow into the same layout.",
    ),
  ];

  static const _reservations = [
    _ReservationPreview(
      guestName: "Aline Mukamana",
      packageName: "Volcano Ridge Escape",
      travelWindow: "06 Apr - 10 Apr",
      travelers: 4,
      amountRwf: 1450000,
      status: "Confirmed",
      paymentLabel: "Paid in full",
      accent: Color(0xFF0F8F5F),
      note: "Airport pickup, gorilla permit and lodge check-in confirmed.",
    ),
    _ReservationPreview(
      guestName: "Jean Bosco Nshimiyimana",
      packageName: "Lake Kivu Signature Retreat",
      travelWindow: "08 Apr - 11 Apr",
      travelers: 2,
      amountRwf: 980000,
      status: "Awaiting Payment",
      paymentLabel: "Deposit received",
      accent: Color(0xFFC07A12),
      note: "Final balance pending before rooming list is released.",
    ),
    _ReservationPreview(
      guestName: "Keza Uwase",
      packageName: "Akagera Premium Safari",
      travelWindow: "09 Apr - 12 Apr",
      travelers: 5,
      amountRwf: 2230000,
      status: "Check-in Ready",
      paymentLabel: "Travel docs verified",
      accent: Color(0xFF1877B8),
      note: "Vehicle allocation and ranger briefing are already assigned.",
    ),
    _ReservationPreview(
      guestName: "Patrick Mugisha",
      packageName: "Kigali Curated City Weekend",
      travelWindow: "12 Apr - 14 Apr",
      travelers: 3,
      amountRwf: 760000,
      status: "Proposal Sent",
      paymentLabel: "Awaiting confirmation",
      accent: Color(0xFF7C8A9B),
      note: "Client requested dinner add-on and private transfer upgrade.",
    ),
  ];

  static const _weeklyRevenue = [
    _WeekRevenue(label: "Mon", value: 1280000),
    _WeekRevenue(label: "Tue", value: 1840000),
    _WeekRevenue(label: "Wed", value: 1660000),
    _WeekRevenue(label: "Thu", value: 2310000),
    _WeekRevenue(label: "Fri", value: 2780000),
    _WeekRevenue(label: "Sat", value: 2480000),
    _WeekRevenue(label: "Sun", value: 1930000),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontalPadding = width >= 1200
            ? 28.0
            : width >= 760
            ? 24.0
            : 16.0;
        final contentWidth = math.max(0.0, width - (horizontalPadding * 2));
        final isWide = contentWidth >= 980;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                scheme.surface,
                scheme.surfaceContainerLowest.withValues(alpha: 0.92),
              ],
            ),
          ),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  18,
                  horizontalPadding,
                  28,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroPanel(
                        title: t(lang, "nav.trip_reservations"),
                        totalBooked: RwfCurrency.format(18420000),
                        arrivalCount: "06 arrivals today",
                        pendingValue: RwfCurrency.format(3180000),
                      ),
                      const SizedBox(height: 18),
                      _MetricsGrid(contentWidth: contentWidth),
                      const SizedBox(height: 18),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: Column(
                                children: const [
                                  _ReservationFeedCard(
                                    reservations: _reservations,
                                  ),
                                  SizedBox(height: 18),
                                  _WeeklyRevenueCard(revenue: _weeklyRevenue),
                                ],
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              flex: 5,
                              child: Column(
                                children: const [
                                  _StageBreakdownCard(stages: _statusStages),
                                  SizedBox(height: 18),
                                  _LaunchModeCard(items: _liveModeItems),
                                ],
                              ),
                            ),
                          ],
                        )
                      else ...[
                        const _ReservationFeedCard(reservations: _reservations),
                        const SizedBox(height: 18),
                        const _StageBreakdownCard(stages: _statusStages),
                        const SizedBox(height: 18),
                        const _WeeklyRevenueCard(revenue: _weeklyRevenue),
                        const SizedBox(height: 18),
                        const _LaunchModeCard(items: _liveModeItems),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final String title;
  final String totalBooked;
  final String arrivalCount;
  final String pendingValue;

  const _HeroPanel({
    required this.title,
    required this.totalBooked,
    required this.arrivalCount,
    required this.pendingValue,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final isSplit = width >= 860;

    final overview = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedSparkles,
                  size: 12,
                  color: Colors.white,
                ),
                SizedBox(width: 6),
                Text(
                  "Static preview",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.7,
              height: 1.02,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "A polished command center for arrivals, payment follow-up and reservation operations. "
            "Live endpoints can slot into this layout without changing the experience.",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroChip(
                icon: HugeIcons.strokeRoundedCalendar03,
                label: arrivalCount,
              ),
              _HeroChip(
                icon: HugeIcons.strokeRoundedWallet02,
                label: "$pendingValue pending collection",
              ),
              const _HeroChip(
                icon: HugeIcons.strokeRoundedInvoice03,
                label: "RWF-first billing",
              ),
            ],
          ),
        ],
      ),
    );

    final summaryCard = Container(
      width: isSplit ? 320 : double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Booked pipeline",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.72),
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            totalBooked,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Projected from confirmed and in-progress reservations for the current travel window.",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.68),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: const [
              Expanded(
                child: _HeroMetric(
                  label: "Conversion",
                  value: "74%",
                  tone: Color(0xFF8FE6B7),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _HeroMetric(
                  label: "Avg ticket",
                  value: "RWF 1.2M",
                  tone: Color(0xFFFFD27A),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF072C18), Color(0xFF0F5A38), Color(0xFF0B4365)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -52,
            right: -14,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -70,
            left: -30,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.tertiary.withValues(alpha: 0.10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: isSplit
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      overview,
                      const SizedBox(width: 18),
                      summaryCard,
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [overview]),
                      const SizedBox(height: 18),
                      summaryCard,
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final double contentWidth;

  const _MetricsGrid({required this.contentWidth});

  @override
  Widget build(BuildContext context) {
    final items = const [
      _MetricPreview(
        icon: HugeIcons.strokeRoundedTickDouble03,
        label: "Active reservations",
        value: "124",
        detail: "68 confirmed, 21 awaiting payment",
        accent: Color(0xFF0F8F5F),
      ),
      _MetricPreview(
        icon: HugeIcons.strokeRoundedCalendarAdd02,
        label: "Arrival window",
        value: "06 today",
        detail: "14 more in the next 72 hours",
        accent: Color(0xFF1877B8),
      ),
      _MetricPreview(
        icon: HugeIcons.strokeRoundedWallet02,
        label: "Gross booked",
        value: "RWF 18,420,000",
        detail: "Static preview of endpoint-backed revenue",
        accent: Color(0xFFB97912),
      ),
      _MetricPreview(
        icon: HugeIcons.strokeRoundedUserGroup03,
        label: "Average party size",
        value: "3.2 guests",
        detail: "Sized for rooming, transport and guide planning",
        accent: Color(0xFF5C7082),
      ),
    ];

    final itemWidth = contentWidth >= 1120
        ? (contentWidth - 36) / 4
        : contentWidth >= 700
        ? (contentWidth - 12) / 2
        : contentWidth;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map(
            (item) => SizedBox(
              width: itemWidth,
              child: _MetricCard(item: item),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ReservationFeedCard extends StatelessWidget {
  final List<_ReservationPreview> reservations;

  const _ReservationFeedCard({required this.reservations});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: "Upcoming arrivals",
            description:
                "A premium reservation list ready for real guest, package and payment endpoint data.",
            trailing: _PreviewToggleRow(),
          ),
          const SizedBox(height: 18),
          Column(
            children: reservations
                .map(
                  (reservation) => Padding(
                    padding: EdgeInsets.only(
                      bottom: reservation == reservations.last ? 0 : 12,
                    ),
                    child: _ReservationTile(reservation: reservation),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _StageBreakdownCard extends StatelessWidget {
  final List<_StagePreview> stages;

  const _StageBreakdownCard({required this.stages});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: "Reservation pipeline",
            description:
                "The status rail is shaped for real-time counts and fulfillment visibility once the endpoints arrive.",
          ),
          const SizedBox(height: 18),
          Column(
            children: stages
                .map(
                  (stage) => Padding(
                    padding: EdgeInsets.only(
                      bottom: stage == stages.last ? 0 : 14,
                    ),
                    child: _StageTile(stage: stage),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _WeeklyRevenueCard extends StatelessWidget {
  final List<_WeekRevenue> revenue;

  const _WeeklyRevenueCard({required this.revenue});

  @override
  Widget build(BuildContext context) {
    final peak = revenue.map((item) => item.value).reduce(math.max).toDouble();

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: "Booked revenue this week",
            description:
                "Static weekly shape using RWF to preview how live demand and reservation intake will surface.",
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: revenue
                  .map(
                    (item) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: item == revenue.last ? 0 : 10,
                        ),
                        child: _WeekRevenueBar(item: item, peak: peak),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _LaunchModeCard extends StatelessWidget {
  final List<_LaunchPreview> items;

  const _LaunchModeCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: "Ready for live mode",
            description:
                "This preview is already structured for filters, guest context, financial tracking and operational actions.",
          ),
          const SizedBox(height: 18),
          Column(
            children: items
                .map(
                  (item) => Padding(
                    padding: EdgeInsets.only(
                      bottom: item == items.last ? 0 : 12,
                    ),
                    child: _LaunchTile(item: item),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;

  const _SurfaceCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surface.withValues(alpha: isDark ? 0.88 : 0.96),
            scheme.surfaceContainerLowest.withValues(
              alpha: isDark ? 0.92 : 0.98,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: isDark ? 0.14 : 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String description;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    required this.description,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final stacked = trailing != null && width < 720;

    final textBlock = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface.withValues(alpha: 0.94),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.45,
              color: scheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );

    if (trailing == null) {
      return Row(children: [textBlock]);
    }

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [textBlock]),
          const SizedBox(height: 14),
          trailing!,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [textBlock, const SizedBox(width: 14), trailing!],
    );
  }
}

class _PreviewToggleRow extends StatelessWidget {
  const _PreviewToggleRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: const [
        _MiniToggle(label: "Upcoming", selected: true),
        _MiniToggle(label: "Pending"),
        _MiniToggle(label: "Completed"),
      ],
    );
  }
}

class _MiniToggle extends StatelessWidget {
  final String label;
  final bool selected;

  const _MiniToggle({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.12)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.22)
              : scheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: selected
              ? AppColors.primary
              : scheme.onSurface.withValues(alpha: 0.68),
        ),
      ),
    );
  }
}

class _ReservationTile extends StatelessWidget {
  final _ReservationPreview reservation;

  const _ReservationTile({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 680;

    final metaPills = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _DataPill(
          icon: HugeIcons.strokeRoundedCalendar03,
          label: reservation.travelWindow,
        ),
        _DataPill(
          icon: HugeIcons.strokeRoundedUserGroup03,
          label: "${reservation.travelers} guests",
        ),
        _DataPill(
          icon: HugeIcons.strokeRoundedWallet02,
          label: reservation.paymentLabel,
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReservationHeader(reservation: reservation),
                  const SizedBox(height: 12),
                  metaPills,
                  const SizedBox(height: 12),
                  Text(
                    reservation.note,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                      color: scheme.onSurface.withValues(alpha: 0.64),
                    ),
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ReservationHeader(reservation: reservation),
                        const SizedBox(height: 12),
                        metaPills,
                        const SizedBox(height: 12),
                        Text(
                          reservation.note,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                            color: scheme.onSurface.withValues(alpha: 0.64),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 1,
                    height: 88,
                    color: scheme.onSurface.withValues(alpha: 0.08),
                  ),
                  const SizedBox(width: 12),
                  _ReservationAmount(reservation: reservation),
                ],
              ),
      ),
    );
  }
}

class _ReservationHeader extends StatelessWidget {
  final _ReservationPreview reservation;

  const _ReservationHeader({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: reservation.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              _initials(reservation.guestName),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: reservation.accent,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reservation.guestName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface.withValues(alpha: 0.94),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                reservation.packageName,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.66),
                ),
              ),
            ],
          ),
        ),
        _StatusBadge(label: reservation.status, accent: reservation.accent),
      ],
    );
  }
}

class _ReservationAmount extends StatelessWidget {
  final _ReservationPreview reservation;

  const _ReservationAmount({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          "Booking value",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface.withValues(alpha: 0.52),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          RwfCurrency.format(reservation.amountRwf),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: scheme.onSurface.withValues(alpha: 0.94),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _WeekRevenueBar extends StatelessWidget {
  final _WeekRevenue item;
  final double peak;

  const _WeekRevenueBar({required this.item, required this.peak});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = (item.value / peak * 94).clamp(20.0, 94.0);
    final isPeak = item.value == peak;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          RwfCurrency.compact(item.value),
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface.withValues(alpha: 0.62),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isPeak
                      ? const [Color(0xFF0F8F5F), Color(0xFF0B5C3D)]
                      : [
                          AppColors.primary.withValues(alpha: 0.68),
                          AppColors.primary.withValues(alpha: 0.26),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              height: height,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          item.label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface.withValues(alpha: 0.62),
          ),
        ),
      ],
    );
  }
}

class _StageTile extends StatelessWidget {
  final _StagePreview stage;

  const _StageTile({required this.stage});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: stage.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  stage.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface.withValues(alpha: 0.92),
                  ),
                ),
              ),
              Text(
                "${stage.count}",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: stage.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            stage.detail,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.45,
              color: scheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: stage.progress,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest.withValues(
                alpha: 0.70,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(stage.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _LaunchTile extends StatelessWidget {
  final _LaunchPreview item;

  const _LaunchTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface.withValues(alpha: 0.92),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    HugeIcon(
                      icon: item.icon,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                    color: scheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final _MetricPreview item;

  const _MetricCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: item.icon,
                    size: 18,
                    color: item.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.54),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface.withValues(alpha: 0.94),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.detail,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.45,
              color: scheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: 14, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color tone;

  const _HeroMetric({
    required this.label,
    required this.value,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.60),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: tone,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color accent;

  const _StatusBadge({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: accent,
        ),
      ),
    );
  }
}

class _DataPill extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;

  const _DataPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: icon,
            size: 13,
            color: scheme.onSurface.withValues(alpha: 0.60),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.70),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricPreview {
  final List<List<dynamic>> icon;
  final String label;
  final String value;
  final String detail;
  final Color accent;

  const _MetricPreview({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.accent,
  });
}

class _ReservationPreview {
  final String guestName;
  final String packageName;
  final String travelWindow;
  final int travelers;
  final int amountRwf;
  final String status;
  final String paymentLabel;
  final Color accent;
  final String note;

  const _ReservationPreview({
    required this.guestName,
    required this.packageName,
    required this.travelWindow,
    required this.travelers,
    required this.amountRwf,
    required this.status,
    required this.paymentLabel,
    required this.accent,
    required this.note,
  });
}

class _StagePreview {
  final String label;
  final String detail;
  final int count;
  final double progress;
  final Color accent;

  const _StagePreview({
    required this.label,
    required this.detail,
    required this.count,
    required this.progress,
    required this.accent,
  });
}

class _LaunchPreview {
  final List<List<dynamic>> icon;
  final String title;
  final String description;

  const _LaunchPreview({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _WeekRevenue {
  final String label;
  final int value;

  const _WeekRevenue({required this.label, required this.value});
}

String _initials(String name) {
  final parts = name.split(RegExp(r"\s+")).where((part) => part.isNotEmpty);
  return parts
      .take(2)
      .map((part) => part.characters.first)
      .join()
      .toUpperCase();
}
