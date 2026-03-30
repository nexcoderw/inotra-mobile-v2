import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "my_listing_bookings_models.dart";

class MyListingBookingMetricsRow extends StatelessWidget {
  const MyListingBookingMetricsRow({super.key, required this.items});

  final List<MyListingBookingMetricItem> items;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _MetricCard(item: items[index]),
            if (index != items.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.item});

  final MyListingBookingMetricItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 186,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.84)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.10)),
        boxShadow: isDark
            ? const []
            : [
                BoxShadow(
                  color: item.accent.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: HugeIcon(icon: item.icon, color: item.accent, size: 18),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: -0.6,
              color: scheme.onSurface.withValues(alpha: 0.94),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.76),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.detail,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: scheme.onSurface.withValues(alpha: 0.52),
            ),
          ),
        ],
      ),
    );
  }
}
