import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";
import "trip_reservations_models.dart";
import "trip_reservations_shared.dart";

class TripReservationsHeader extends StatelessWidget {
  const TripReservationsHeader({
    super.key,
    required this.displayName,
    required this.email,
    required this.nextTrip,
  });

  final String displayName;
  final String email;
  final TripReservationPreview nextTrip;

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nextTripTone = tripReservationTone(nextTrip.statusKey, scheme);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF102C21), const Color(0xFF0A1A14)]
              : [const Color(0xFF113828), const Color(0xFF081610)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C1F16).withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showInlinePanel = constraints.maxWidth >= 840;

          return showInlinePanel
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildLead(context, lang)),
                    const SizedBox(width: 18),
                    SizedBox(
                      width: 292,
                      child: _buildNextTripPanel(context, lang, nextTripTone),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLead(context, lang),
                    const SizedBox(height: 16),
                    _buildNextTripPanel(context, lang, nextTripTone),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildLead(BuildContext context, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t(lang, "trip_reservations.header_eyebrow"),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: Colors.white.withValues(alpha: 0.56),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          t(lang, "nav.trip_reservations"),
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1,
            letterSpacing: -0.9,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          t(
            lang,
            "trip_reservations.header_subtitle",
          ).replaceAll("{name}", displayName),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.45,
            color: Colors.white.withValues(alpha: 0.70),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedUser,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.56),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNextTripPanel(BuildContext context, String lang, Color tone) {
    return TripReservationsSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(lang, "trip_reservations.next_trip"),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: tone,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            nextTrip.packageName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatTripWindow(context, nextTrip.startDate, nextTrip.endDate),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.58),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TripReservationStateBadge(
                label: t(lang, nextTrip.statusKey),
                color: tone,
              ),
              TripReservationMetaPill(
                icon: HugeIcons.strokeRoundedLocation01,
                label: nextTrip.destination,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.52),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
