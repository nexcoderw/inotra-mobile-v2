import "dart:math" as math;

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../../core/constants/app_colors.dart";
import "../../../../../core/utils/rwf_currency.dart";

/// Revenue overview card — fully static / sample data until the revenue
/// analytics endpoint is available. Marked clearly with a "Coming soon" badge.
class DashboardRevenueCard extends StatelessWidget {
  const DashboardRevenueCard({super.key});

  static const _weekDays = ["W1", "W2", "W3", "W4"];
  static final _bars = [4200000.0, 6800000.0, 5100000.0, 7400000.0];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        final statWidth = constraints.maxWidth >= 980
            ? (constraints.maxWidth - 48) / 3
            : constraints.maxWidth >= 620
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        final maxV = _bars.reduce(math.max);

        return Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF0F2A1C),
                      const Color(0xFF082518),
                      const Color(0xFF0A3040),
                    ]
                  : [
                      AppColors.primary,
                      const Color(0xFF0D5231),
                      const Color(0xFF0C425C),
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -48,
                right: -12,
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
                bottom: -76,
                left: -30,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedMoney02,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Revenue",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                Text(
                                  "Static preview in RWF",
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.62),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(
                                0xFFF59E0B,
                              ).withValues(alpha: 0.28),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedSparkles,
                                color: Color(0xFFF4C66E),
                                size: 12,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "Endpoint-ready",
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFFD27A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _RevenueHeadline(
                              total: RwfCurrency.format(23500000),
                              subtitle:
                                  "Projected gross bookings for the current month across listing stays and trip operations.",
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: _ForecastPanel(
                              collected: RwfCurrency.format(16700000),
                              pending: RwfCurrency.format(6800000),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _RevenueHeadline(
                        total: RwfCurrency.format(23500000),
                        subtitle:
                            "Projected gross bookings for the current month across listing stays and trip operations.",
                      ),
                      const SizedBox(height: 14),
                      _ForecastPanel(
                        collected: RwfCurrency.format(16700000),
                        pending: RwfCurrency.format(6800000),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: statWidth,
                          child: const _RevenueStat(
                            label: "Gross booked",
                            value: "RWF 23,500,000",
                            sub: "+18% vs previous month",
                          ),
                        ),
                        SizedBox(
                          width: statWidth,
                          child: const _RevenueStat(
                            label: "Listings",
                            value: "RWF 16,200,000",
                            sub: "69% of the previewed total",
                          ),
                        ),
                        SizedBox(
                          width: statWidth,
                          child: const _RevenueStat(
                            label: "Trips",
                            value: "RWF 7,300,000",
                            sub: "31% of the previewed total",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(_weekDays.length, (i) {
                        final h = (_bars[i] / maxV * 74).clamp(18.0, 74.0);
                        final isHighest = _bars[i] == maxV;

                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: i == _weekDays.length - 1 ? 0 : 10,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  RwfCurrency.compact(_bars[i]),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.70),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  height: h,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: isHighest
                                          ? [
                                              Colors.white,
                                              Colors.white.withValues(
                                                alpha: 0.78,
                                              ),
                                            ]
                                          : [
                                              Colors.white.withValues(
                                                alpha: 0.46,
                                              ),
                                              Colors.white.withValues(
                                                alpha: 0.18,
                                              ),
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _weekDays[i],
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.58),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RevenueHeadline extends StatelessWidget {
  final String total;
  final String subtitle;

  const _RevenueHeadline({required this.total, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Booked pipeline",
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.58),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          total,
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.6,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            height: 1.45,
            color: Colors.white.withValues(alpha: 0.72),
          ),
        ),
      ],
    );
  }
}

class _ForecastPanel extends StatelessWidget {
  final String collected;
  final String pending;

  const _ForecastPanel({required this.collected, required this.pending});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _ForecastMetric(
                  label: "Collected",
                  value: collected,
                  tone: const Color(0xFF8FE6B7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ForecastMetric(
                  label: "Pending",
                  value: pending,
                  tone: const Color(0xFFFFD27A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            "Finance and reservations endpoints will replace this preview with live totals while keeping the same layout.",
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.64),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color tone;

  const _ForecastMetric({
    required this.label,
    required this.value,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.58),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            color: tone,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _RevenueStat extends StatelessWidget {
  final String label;
  final String value;
  final String sub;

  const _RevenueStat({
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        Text(
          sub,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.42),
          ),
        ),
      ],
    );
  }
}
