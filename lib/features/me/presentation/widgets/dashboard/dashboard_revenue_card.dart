import "dart:math" as math;

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../../core/constants/app_colors.dart";

/// Revenue overview card — fully static / sample data until the revenue
/// analytics endpoint is available. Marked clearly with a "Coming soon" badge.
class DashboardRevenueCard extends StatelessWidget {
  const DashboardRevenueCard({super.key});

  static const _weekDays = ["W1", "W2", "W3", "W4"];
  static final _bars = [4200.0, 6800.0, 5100.0, 7400.0];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0F2A1C),
                  const Color(0xFF061810),
                ]
              : [
                  AppColors.primary,
                  const Color(0xFF0D5231),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative background circles
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: 60,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedMoney02,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Revenue",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            "This month",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ]),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedSparkles,
                            color: Color(0xFFF59E0B),
                            size: 11,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "Coming soon",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Revenue numbers row
                Row(
                  children: [
                    _RevenueStat(
                        label: "Total",
                        value: "\$23,500",
                        sub: "+18% vs last month"),
                    const SizedBox(width: 24),
                    _RevenueStat(
                        label: "Listings",
                        value: "\$16,200",
                        sub: "69% of total"),
                    const SizedBox(width: 24),
                    _RevenueStat(
                        label: "Events",
                        value: "\$7,300",
                        sub: "31% of total"),
                  ],
                ),
                const SizedBox(height: 20),

                // Weekly bar chart
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_weekDays.length, (i) {
                    final maxV = _bars.reduce(math.max);
                    final h = (_bars[i] / maxV * 52).clamp(8.0, 52.0);
                    final isHighest = _bars[i] == maxV;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: h,
                          decoration: BoxDecoration(
                            color: isHighest
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.26),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _weekDays[i],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueStat extends StatelessWidget {
  final String label;
  final String value;
  final String sub;

  const _RevenueStat(
      {required this.label, required this.value, required this.sub});

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
            fontSize: 17,
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
