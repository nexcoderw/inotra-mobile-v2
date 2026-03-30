import "dart:math" as math;

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "dashboard_shared.dart";

/// Dashboard section for the user's events: totals, submission count,
/// estimated attendance, and a sample ticket-sales-by-category bar chart.
class DashboardEventsSection extends StatelessWidget {
  final int? eventCount;
  final int? submissionCount;
  final bool isLoading;
  final VoidCallback? onViewAll;

  const DashboardEventsSection({
    super.key,
    this.eventCount,
    this.submissionCount,
    this.isLoading = false,
    this.onViewAll,
  });

  static const _accentColor = Color(0xFFF59E0B);
  static const _categories = ["Music", "Sports", "Art", "Food", "Tech"];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = eventCount ?? 0;

    // Deterministic sample bars seeded by event count
    final rng = math.Random(total + 7);
    final values =
        List.generate(_categories.length, (_) => rng.nextDouble() * 80 + 20);
    final maxV = values.reduce(math.max);

    return DashboardSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          DashboardSectionHeader(
            icon: HugeIcons.strokeRoundedFireworks,
            iconColor: _accentColor,
            title: "Events",
            subtitle: isLoading ? "Loading…" : "$total total",
            onViewAll: onViewAll,
          ),
          const SizedBox(height: 18),

          // 3-tile stat row
          Row(children: [
            Expanded(
              child: _EventTile(
                icon: HugeIcons.strokeRoundedFireworks,
                label: "Events",
                value: isLoading ? "—" : "$total",
                color: _accentColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _EventTile(
                icon: HugeIcons.strokeRoundedFile02,
                label: "Submissions",
                value: isLoading ? "—" : "${submissionCount ?? 0}",
                color: const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _EventTile(
                icon: HugeIcons.strokeRoundedUserGroup,
                label: "Attendance",
                value: isLoading ? "—" : "${(total * 42).clamp(0, 9999)}",
                color: const Color(0xFF0EA5E9),
              ),
            ),
          ]),
          const SizedBox(height: 18),

          // Chart sub-header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Ticket Sales by Category",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.6),
                  letterSpacing: 0.1,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Sample data",
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.38),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Horizontal progress bars
          ...List.generate(_categories.length, (i) {
            final pct = values[i] / maxV;
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(children: [
                SizedBox(
                  width: 46,
                  child: Text(
                    _categories[i],
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: pct.clamp(0.0, 1.0),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: _accentColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 28,
                  child: Text(
                    "${values[i].round()}",
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ]),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EventTile extends StatelessWidget {
  final dynamic icon; // HugeIcons constant
  final String label;
  final String value;
  final Color color;

  const _EventTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(icon: icon, color: color, size: 15),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
              height: 1,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: scheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}
