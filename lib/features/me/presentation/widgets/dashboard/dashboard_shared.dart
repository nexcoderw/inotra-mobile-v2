import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

// ─────────────────────────────────────────────────────────────────────────────
// Reusable section container card shared across dashboard sections.
// ─────────────────────────────────────────────────────────────────────────────

class DashboardSectionCard extends StatelessWidget {
  final Widget child;

  const DashboardSectionCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: scheme.outline.withValues(alpha: isDark ? 0.08 : 0.09)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header: icon + title + subtitle + optional "View all" link.
// ─────────────────────────────────────────────────────────────────────────────

class DashboardSectionHeader extends StatelessWidget {
  final dynamic icon; // HugeIcons constant
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onViewAll;

  const DashboardSectionHeader({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: HugeIcon(icon: icon, color: iconColor, size: 16),
            ),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ]),
        ]),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Text(
              "View all",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact icon + label + value chip.
// ─────────────────────────────────────────────────────────────────────────────

class DashboardStatChip extends StatelessWidget {
  final dynamic icon; // HugeIcons constant
  final String label;
  final String value;
  final Color color;

  const DashboardStatChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        HugeIcon(icon: icon, color: color, size: 13),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ]),
    );
  }
}
