import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

Color myListingBookingTone(String key, ColorScheme scheme) {
  switch (key) {
    case "my_listings.bookings.status_confirmed":
      return const Color(0xFF0F8F5F);
    case "my_listings.bookings.status_checked_in":
      return const Color(0xFF1877B8);
    case "my_listings.bookings.status_completed":
      return scheme.onSurface.withValues(alpha: 0.56);
    case "my_listings.bookings.status_cancelled":
      return const Color(0xFFD64545);
    default:
      return const Color(0xFFC07A12);
  }
}

String formatListingDate(BuildContext context, DateTime? date) {
  if (date == null) return "";
  return MaterialLocalizations.of(context).formatMediumDate(date);
}

String formatListingMonthDay(BuildContext context, DateTime? date) {
  if (date == null) return "";
  return MaterialLocalizations.of(context).formatShortMonthDay(date);
}

String formatListingStayWindow(
  BuildContext context,
  DateTime? checkIn,
  DateTime? checkOut,
) {
  if (checkIn == null && checkOut == null) return "";
  if (checkIn == null) return formatListingDate(context, checkOut);
  if (checkOut == null) return formatListingDate(context, checkIn);

  final start = formatListingMonthDay(context, checkIn);
  final end = formatListingMonthDay(context, checkOut);
  return "$start - $end";
}

class MyListingBookingSurfaceCard extends StatelessWidget {
  const MyListingBookingSurfaceCard({
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

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surfaceContainerHigh.withValues(alpha: 0.84)
            : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: borderColor ?? scheme.outline.withValues(alpha: 0.10),
        ),
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

class MyListingBookingSectionHeader extends StatelessWidget {
  const MyListingBookingSectionHeader({
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

class MyListingBookingMetaPill extends StatelessWidget {
  const MyListingBookingMetaPill({
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

class MyListingBookingStateBadge extends StatelessWidget {
  const MyListingBookingStateBadge({
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

class MyListingBookingActionButton extends StatelessWidget {
  const MyListingBookingActionButton({
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
