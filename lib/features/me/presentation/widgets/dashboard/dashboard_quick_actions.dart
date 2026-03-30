import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../../core/constants/app_colors.dart";

/// 2-column grid of quick-action tiles. Each tile navigates to a key area of
/// the app. All actions are static — no API calls needed.
class DashboardQuickActions extends StatelessWidget {
  final VoidCallback? onAddListing;
  final VoidCallback? onAddEvent;
  final VoidCallback? onViewBookings;
  final VoidCallback? onViewTickets;
  final VoidCallback? onViewReviews;
  final VoidCallback? onViewReservations;

  const DashboardQuickActions({
    super.key,
    this.onAddListing,
    this.onAddEvent,
    this.onViewBookings,
    this.onViewTickets,
    this.onViewReviews,
    this.onViewReservations,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final actions = [
      _Action(
        icon: HugeIcons.strokeRoundedHome05,
        label: "Add Listing",
        color: AppColors.primary,
        onTap: onAddListing,
      ),
      _Action(
        icon: HugeIcons.strokeRoundedFireworks,
        label: "Add Event",
        color: const Color(0xFFF59E0B),
        onTap: onAddEvent,
      ),
      _Action(
        icon: HugeIcons.strokeRoundedCalendar03,
        label: "Bookings",
        color: const Color(0xFF0EA5E9),
        onTap: onViewBookings,
      ),
      _Action(
        icon: HugeIcons.strokeRoundedTicket01,
        label: "Tickets",
        color: const Color(0xFF8B5CF6),
        onTap: onViewTickets,
      ),
      _Action(
        icon: HugeIcons.strokeRoundedStar,
        label: "Reviews",
        color: const Color(0xFFEC4899),
        onTap: onViewReviews,
      ),
      _Action(
        icon: HugeIcons.strokeRoundedLuggage01,
        label: "Reservations",
        color: const Color(0xFF14B8A6),
        onTap: onViewReservations,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            "Quick Actions",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
              letterSpacing: -0.2,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.15,
          ),
          itemCount: actions.length,
          itemBuilder: (context, i) => _ActionTile(
            action: actions[i],
            isDark: isDark,
            scheme: scheme,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Action {
  final dynamic icon; // HugeIcons constant
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _Action({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });
}

class _ActionTile extends StatelessWidget {
  final _Action action;
  final bool isDark;
  final ColorScheme scheme;

  const _ActionTile(
      {required this.action, required this.isDark, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? scheme.surfaceContainerHighest
                : action.color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: action.color.withValues(alpha: isDark ? 0.18 : 0.14),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: HugeIcon(
                      icon: action.icon, color: action.color, size: 17),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                action.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.75),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
