import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

Color tripReservationTone(String key, ColorScheme scheme) {
  switch (key) {
    case "trip_reservations.status_upcoming":
    case "trip_reservations.paid_full":
    case "trip_reservations.invoice_paid":
    case "trip_reservations.ticket_active":
      return const Color(0xFF0F8F5F);
    case "trip_reservations.status_confirmed":
    case "trip_reservations.deposit_received":
    case "trip_reservations.invoice_partial":
    case "trip_reservations.ticket_pending":
      return const Color(0xFFC07A12);
    case "trip_reservations.status_completed":
    case "trip_reservations.closed":
    case "trip_reservations.ticket_issued":
      return const Color(0xFF1877B8);
    case "trip_reservations.ticket_archived":
      return scheme.onSurface.withValues(alpha: 0.44);
    default:
      return scheme.primary;
  }
}

String formatTripWindow(BuildContext context, DateTime start, DateTime end) {
  final localizations = MaterialLocalizations.of(context);
  final startLabel = start.year == end.year
      ? localizations.formatShortMonthDay(start)
      : localizations.formatMediumDate(start);
  final endLabel = localizations.formatMediumDate(end);
  return "$startLabel - $endLabel";
}

String formatFullDate(BuildContext context, DateTime date) {
  return MaterialLocalizations.of(context).formatMediumDate(date);
}

class TripReservationsSurfaceCard extends StatelessWidget {
  const TripReservationsSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.82)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.10)),
        boxShadow: isDark
            ? const []
            : [
                BoxShadow(
                  color: const Color(0xFF0E1B14).withValues(alpha: 0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      child: child,
    );
  }
}

class TripReservationsSectionHeader extends StatelessWidget {
  const TripReservationsSectionHeader({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final dynamic icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: HugeIcon(icon: icon, color: iconColor, size: 18),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface.withValues(alpha: 0.94),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface.withValues(alpha: 0.52),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TripReservationMetaPill extends StatelessWidget {
  const TripReservationMetaPill({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  final dynamic icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = color ?? scheme.onSurface.withValues(alpha: 0.56);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, color: tone, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: tone,
            ),
          ),
        ],
      ),
    );
  }
}

class TripReservationStateBadge extends StatelessWidget {
  const TripReservationStateBadge({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class TripReservationActionButton extends StatelessWidget {
  const TripReservationActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    this.isFilled = false,
  });

  final dynamic icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isFilled ? color : scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFilled ? color : scheme.outline.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: icon,
                color: isFilled ? Colors.white : color,
                size: 15,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isFilled ? Colors.white : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
