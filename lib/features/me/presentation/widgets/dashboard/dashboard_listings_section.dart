import "dart:math" as math;

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../../core/constants/app_colors.dart";
import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";
import "dashboard_shared.dart";

/// Dashboard section showing listing portfolio health: status donut chart
/// + a mini 7-day bookings bar chart (sample data).
class DashboardListingsSection extends StatelessWidget {
  final int? listingCount;
  final int? bookingCount;
  final int? submissionCount;
  final bool isLoading;
  final VoidCallback? onViewAll;

  const DashboardListingsSection({
    super.key,
    this.listingCount,
    this.bookingCount,
    this.submissionCount,
    this.isLoading = false,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lang = currentLangSync();

    final total = listingCount ?? 0;
    final active = (total * 0.62).round();
    final pending = (total * 0.26).round();
    final inactive = total - active - pending;

    return DashboardSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardSectionHeader(
            icon: HugeIcons.strokeRoundedHome05,
            iconColor: AppColors.primary,
            title: t(lang, "dashboard.listings"),
            subtitle: isLoading
                ? t(lang, "dashboard.loading")
                : "$total ${t(lang, "dashboard.total")}",
            onViewAll: onViewAll,
          ),
          const SizedBox(height: 18),

          // Donut + legend row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Donut chart
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      painter: _DonutPainter(
                        slices: [
                          _Slice(
                            t(lang, "dashboard.active"),
                            active.toDouble(),
                            AppColors.primary,
                          ),
                          _Slice(
                            t(lang, "dashboard.pending"),
                            pending.toDouble(),
                            const Color(0xFFF59E0B),
                          ),
                          _Slice(
                            t(lang, "dashboard.inactive"),
                            inactive.toDouble(),
                            scheme.onSurface.withValues(alpha: 0.15),
                          ),
                        ],
                      ),
                      size: const Size(100, 100),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLoading ? "—" : "$total",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                            height: 1,
                          ),
                        ),
                        Text(
                          t(lang, "dashboard.total"),
                          style: TextStyle(
                            fontSize: 10,
                            color: scheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Legend + chips
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendRow(
                      color: AppColors.primary,
                      label: t(lang, "dashboard.active"),
                      value: isLoading ? "—" : "$active",
                      scheme: scheme,
                    ),
                    const SizedBox(height: 8),
                    _LegendRow(
                      color: const Color(0xFFF59E0B),
                      label: t(lang, "dashboard.pending"),
                      value: isLoading ? "—" : "$pending",
                      scheme: scheme,
                    ),
                    const SizedBox(height: 8),
                    _LegendRow(
                      color: scheme.onSurface.withValues(alpha: 0.25),
                      label: t(lang, "dashboard.inactive"),
                      value: isLoading ? "—" : "$inactive",
                      scheme: scheme,
                    ),
                    const SizedBox(height: 14),
                    DashboardStatChip(
                      icon: HugeIcons.strokeRoundedCalendar03,
                      label: t(lang, "dashboard.bookings"),
                      value: isLoading ? "—" : "${bookingCount ?? 0}",
                      color: const Color(0xFF0EA5E9),
                    ),
                    const SizedBox(height: 6),
                    DashboardStatChip(
                      icon: HugeIcons.strokeRoundedFile02,
                      label: t(lang, "dashboard.submissions"),
                      value: isLoading ? "—" : "${submissionCount ?? 0}",
                      color: const Color(0xFF8B5CF6),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 7-day bookings bar chart (sample)
          _WeekDayLabels(scheme: scheme),
          const SizedBox(height: 8),
          SizedBox(
            height: 54,
            child: CustomPaint(
              painter: _BarChartPainter(
                bars: _sampleWeeklyBars(bookingCount),
                activeColor: AppColors.primary,
                scheme: scheme,
              ),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }

  static List<double> _sampleWeeklyBars(int? seed) {
    final rng = math.Random((seed ?? 3) + 42);
    return List.generate(7, (_) => rng.nextDouble() * 8 + 1);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Local widgets
// ─────────────────────────────────────────────────────────────────────────────

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final ColorScheme scheme;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _WeekDayLabels extends StatelessWidget {
  final ColorScheme scheme;
  const _WeekDayLabels({required this.scheme});

  @override
  Widget build(BuildContext context) {
    final weekdays = MaterialLocalizations.of(context).narrowWeekdays;
    final mondayFirst = [
      weekdays[1],
      weekdays[2],
      weekdays[3],
      weekdays[4],
      weekdays[5],
      weekdays[6],
      weekdays[0],
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: mondayFirst
          .map(
            (d) => SizedBox(
              width: 32,
              child: Text(
                d,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: scheme.onSurface.withValues(alpha: 0.35),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painters
// ─────────────────────────────────────────────────────────────────────────────

class _Slice {
  final String label;
  final double value;
  final Color color;
  const _Slice(this.label, this.value, this.color);
}

class _DonutPainter extends CustomPainter {
  final List<_Slice> slices;
  const _DonutPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (s, e) => s + e.value);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    final strokeW = radius * 0.28;
    double startAngle = -math.pi / 2;
    const gap = 0.04;

    for (final s in slices) {
      final sweep = (s.value / total) * 2 * math.pi - gap;
      if (sweep <= 0) continue;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeW / 2),
        startAngle,
        sweep,
        false,
        Paint()
          ..color = s.color
          ..strokeWidth = strokeW
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      startAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.slices != slices;
}

class _BarChartPainter extends CustomPainter {
  final List<double> bars;
  final Color activeColor;
  final ColorScheme scheme;

  const _BarChartPainter({
    required this.bars,
    required this.activeColor,
    required this.scheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    final maxV = bars.reduce(math.max).clamp(1.0, double.infinity);
    final barW = size.width / (bars.length * 1.6);
    final todayIdx = DateTime.now().weekday - 1; // 0 = Mon

    for (int i = 0; i < bars.length; i++) {
      final norm = bars[i] / maxV;
      final h = (norm * size.height * 0.88).clamp(4.0, size.height);
      final x = i * (size.width / bars.length) + barW * 0.3;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - h, barW, h),
          const Radius.circular(4),
        ),
        Paint()
          ..color = i == todayIdx
              ? activeColor
              : activeColor.withValues(alpha: 0.25),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) => old.bars != bars;
}
