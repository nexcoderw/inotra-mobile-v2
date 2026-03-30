import "dart:math" as math;

import "package:flutter/material.dart";

import "../../../../../core/constants/app_colors.dart";

/// Full-width area chart that overlays two data series over the selected
/// date range. Series 1 = listing activity (green), Series 2 = bookings
/// (sky-blue). Both series are generated from sample data in the page and
/// passed in as plain double lists.
class DashboardActivityChart extends StatelessWidget {
  final DateTimeRange range;
  final List<double> listingsData;
  final List<double> bookingsData;

  const DashboardActivityChart({
    super.key,
    required this.range,
    required this.listingsData,
    required this.bookingsData,
  });

  static const _months = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
  ];

  static String _fmt(DateTime d) => "${_months[d.month - 1]} ${d.day}";

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: scheme.outline.withValues(alpha: isDark ? 0.08 : 0.09)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── header ───────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Activity Overview",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${_fmt(range.start)} – ${_fmt(range.end)}",
                    style: TextStyle(
                      fontSize: 11.5,
                      color: scheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
              Row(children: [
                _Legend(
                  color: AppColors.primary,
                  label: "Listings",
                  scheme: scheme,
                ),
                const SizedBox(width: 14),
                _Legend(
                  color: const Color(0xFF0EA5E9),
                  label: "Bookings",
                  scheme: scheme,
                ),
              ]),
            ],
          ),
          const SizedBox(height: 18),

          // ── chart canvas ─────────────────────────────────────────────────
          SizedBox(
            height: 156,
            child: CustomPaint(
              painter: _AreaChartPainter(
                series1: listingsData,
                series2: bookingsData,
                color1: AppColors.primary,
                color2: const Color(0xFF0EA5E9),
                gridColor: scheme.onSurface.withValues(alpha: 0.06),
              ),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 10),

          // ── x-axis labels ────────────────────────────────────────────────
          _XAxisLabels(range: range, scheme: scheme),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// X-axis labels
// ─────────────────────────────────────────────────────────────────────────────

class _XAxisLabels extends StatelessWidget {
  final DateTimeRange range;
  final ColorScheme scheme;

  const _XAxisLabels({required this.range, required this.scheme});

  static const _months = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
  ];

  @override
  Widget build(BuildContext context) {
    final days = range.end.difference(range.start).inDays + 1;
    final labelCount = math.min(days, 5);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(labelCount, (i) {
        final offset = labelCount == 1
            ? 0
            : ((days - 1) * i / (labelCount - 1)).round().clamp(0, days - 1);
        final d = range.start.add(Duration(days: offset));
        return Text(
          "${_months[d.month - 1]} ${d.day}",
          style: TextStyle(
            fontSize: 10,
            color: scheme.onSurface.withValues(alpha: 0.38),
            fontWeight: FontWeight.w500,
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Legend item
// ─────────────────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final ColorScheme scheme;

  const _Legend(
      {required this.color, required this.label, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Area chart painter
// ─────────────────────────────────────────────────────────────────────────────

class _AreaChartPainter extends CustomPainter {
  final List<double> series1;
  final List<double> series2;
  final Color color1;
  final Color color2;
  final Color gridColor;

  const _AreaChartPainter({
    required this.series1,
    required this.series2,
    required this.color1,
    required this.color2,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final allVals = [...series1, ...series2];
    if (allVals.isEmpty) return;
    final maxV = allVals.reduce(math.max);

    // Grid lines (4 horizontal)
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = size.height * (1 - i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    _drawSeries(canvas, size, series2, color2, maxV, alpha: 0.65);
    _drawSeries(canvas, size, series1, color1, maxV, alpha: 0.85);
  }

  void _drawSeries(
    Canvas canvas,
    Size size,
    List<double> data,
    Color color,
    double maxV, {
    double alpha = 1,
  }) {
    if (data.length < 2) return;

    final pts = List.generate(data.length, (i) {
      final x = i * size.width / (data.length - 1);
      final norm = maxV == 0 ? 0.0 : data[i] / maxV;
      final y = size.height - (norm * size.height * 0.86 + size.height * 0.04);
      return Offset(x, y);
    });

    // Area fill
    final fillPath = Path()
      ..moveTo(pts.first.dx, size.height)
      ..lineTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final cpX = (pts[i - 1].dx + pts[i].dx) / 2;
      fillPath.cubicTo(
          cpX, pts[i - 1].dy, cpX, pts[i].dy, pts[i].dx, pts[i].dy);
    }
    fillPath
      ..lineTo(pts.last.dx, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: alpha * 0.28),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill,
    );

    // Stroke
    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final cpX = (pts[i - 1].dx + pts[i].dx) / 2;
      linePath.cubicTo(
          cpX, pts[i - 1].dy, cpX, pts[i].dy, pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color.withValues(alpha: alpha)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Peak dot
    final peakIdx = data.indexOf(data.reduce(math.max));
    canvas
      ..drawCircle(pts[peakIdx], 4, Paint()..color = color..style = PaintingStyle.fill)
      ..drawCircle(pts[peakIdx], 2.5,
          Paint()..color = Colors.white..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter old) =>
      old.series1 != series1 || old.series2 != series2;
}
