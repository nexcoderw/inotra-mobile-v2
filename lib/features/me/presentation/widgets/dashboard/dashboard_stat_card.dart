import "dart:math" as math;

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

/// A compact metric tile shown inside a horizontally-scrolling row on the
/// dashboard. Displays a label, a large value, an optional trend badge and a
/// small spark-line chart.
class DashboardStatCard extends StatelessWidget {
  final String label;
  final String value;
  final dynamic icon; // HugeIcons constant
  final Color accentColor;
  final String? trend;
  final bool isUp;
  final List<double>? sparkData;
  final bool isLoading;

  const DashboardStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.trend,
    this.isUp = true,
    this.sparkData,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Container(
      width: 158,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: scheme.outline.withValues(alpha: isDark ? 0.08 : 0.09)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: isLoading ? _buildSkeleton(scheme) : _buildContent(scheme, isDark),
    );
  }

  Widget _buildSkeleton(ColorScheme s) {
    final c = s.onSurface.withValues(alpha: 0.08);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: c, borderRadius: BorderRadius.circular(10))),
      const SizedBox(height: 14),
      Container(
          width: 54,
          height: 22,
          decoration:
              BoxDecoration(color: c, borderRadius: BorderRadius.circular(6))),
      const SizedBox(height: 6),
      Container(
          width: 82,
          height: 11,
          decoration: BoxDecoration(
              color: s.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4))),
    ]);
  }

  Widget _buildContent(ColorScheme s, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDark ? 0.18 : 0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child:
                  Center(child: HugeIcon(icon: icon, color: accentColor, size: 17)),
            ),
            if (trend != null) _buildTrendBadge(),
          ],
        ),
        const SizedBox(height: 13),
        Text(
          value,
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            color: s.onSurface,
            height: 1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: s.onSurface.withValues(alpha: 0.48),
            letterSpacing: 0.1,
          ),
        ),
        if (sparkData != null && sparkData!.length >= 2) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 28,
            child: CustomPaint(
              painter: _SparkPainter(data: sparkData!, color: accentColor),
              size: Size.infinite,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTrendBadge() {
    final trendColor =
        isUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: trendColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          isUp ? Icons.north_rounded : Icons.south_rounded,
          size: 9,
          color: trendColor,
        ),
        const SizedBox(width: 2),
        Text(
          trend!,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: trendColor,
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Spark-line painter
// ─────────────────────────────────────────────────────────────────────────────

class _SparkPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  const _SparkPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final maxV = data.reduce(math.max);
    final minV = data.reduce(math.min);
    final range = (maxV - minV).clamp(1.0, double.infinity);

    List<Offset> pts = List.generate(data.length, (i) {
      final x = i * size.width / (data.length - 1);
      final norm = (data[i] - minV) / range;
      final y = size.height - (norm * size.height * 0.78 + size.height * 0.11);
      return Offset(x, y);
    });

    // Gradient fill
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
            color.withValues(alpha: 0.22),
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
        ..color = color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.data != data || old.color != color;
}
