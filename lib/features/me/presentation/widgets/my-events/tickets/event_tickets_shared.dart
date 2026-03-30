import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

Color eventTicketTone(String key, ColorScheme scheme) {
  switch (key) {
    case "events.status_future":
    case "events.status_tomorrow":
    case "my_events.tickets.ticket_ready":
      return const Color(0xFF0F8F5F);
    case "events.status_happening":
    case "my_events.tickets.ticket_checked_in":
      return const Color(0xFF1877B8);
    case "events.status_ended":
    case "my_events.tickets.ticket_used":
      return scheme.onSurface.withValues(alpha: 0.46);
    default:
      return const Color(0xFFC07A12);
  }
}

String formatEventWindow(BuildContext context, DateTime start, DateTime end) {
  final localizations = MaterialLocalizations.of(context);
  final use24Hour = MediaQuery.alwaysUse24HourFormatOf(context);
  final startDate = localizations.formatMediumDate(start);
  final endDate = localizations.formatMediumDate(end);
  final startTime = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(start),
    alwaysUse24HourFormat: use24Hour,
  );
  final endTime = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(end),
    alwaysUse24HourFormat: use24Hour,
  );

  if (_isSameDay(start, end)) {
    return "$startDate · $startTime - $endTime";
  }

  return "$startDate $startTime - $endDate $endTime";
}

String formatIssuedDate(BuildContext context, DateTime date) {
  return MaterialLocalizations.of(context).formatMediumDate(date);
}

String formatEventMonthDay(BuildContext context, DateTime date) {
  return MaterialLocalizations.of(context).formatShortMonthDay(date);
}

class EventTicketsSurfaceCard extends StatelessWidget {
  const EventTicketsSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outline = borderColor ?? scheme.outline.withValues(alpha: 0.10);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surfaceContainerHigh.withValues(alpha: 0.84)
            : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: outline),
        boxShadow: isDark
            ? const []
            : [
                BoxShadow(
                  color: const Color(0xFF102119).withValues(alpha: 0.05),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
              ],
      ),
      child: child,
    );
  }
}

class EventTicketsSectionHeader extends StatelessWidget {
  const EventTicketsSectionHeader({
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
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
                  letterSpacing: -0.2,
                  color: scheme.onSurface.withValues(alpha: 0.94),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface.withValues(alpha: 0.54),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EventTicketsMetaPill extends StatelessWidget {
  const EventTicketsMetaPill({
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

class EventTicketsStateBadge extends StatelessWidget {
  const EventTicketsStateBadge({
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

class EventTicketsActionButton extends StatelessWidget {
  const EventTicketsActionButton({
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

    return SizedBox(
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isFilled ? color : scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFilled
                    ? color
                    : scheme.outline.withValues(alpha: 0.10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HugeIcon(
                  icon: icon,
                  color: isFilled ? Colors.white : color,
                  size: 16,
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
      ),
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
