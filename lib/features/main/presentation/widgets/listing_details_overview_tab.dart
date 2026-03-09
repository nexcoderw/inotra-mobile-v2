import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "listing_details_shared.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class ListingOverviewTab extends StatelessWidget {
  final PlaceDetails place;
  const ListingOverviewTab({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About / Description
          _GlassSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  icon: HugeIcons.strokeRoundedInformationCircle,
                  label: t(lang, "listings.overview_title"),
                  scheme: scheme,
                ),
                const SizedBox(height: 10),
                Text(
                  place.description.isNotEmpty ? place.description : "—",
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.65,
                    color: scheme.onSurface.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          if (place.services.isNotEmpty) ...[
            const SizedBox(height: 12),
            _GlassSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    icon: HugeIcons.strokeRoundedSparkles,
                    label: t(lang, "listings.services"),
                    scheme: scheme,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: place.services
                        .map((s) => _ServiceChip(label: s, scheme: scheme))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Hours
          _GlassSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  icon: HugeIcons.strokeRoundedClock01,
                  label: t(lang, "listings.hours"),
                  scheme: scheme,
                ),
                const SizedBox(height: 12),
                _HoursGrid(hours: place.hours, scheme: scheme),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- Glass card ----------------------------- */

class _GlassSection extends StatelessWidget {
  final Widget child;
  const _GlassSection({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 8),
                color: Colors.black.withValues(alpha: 0.08),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/* ----------------------------- Section header ----------------------------- */

class _SectionHeader extends StatelessWidget {
  final dynamic icon;
  final String label;
  final ColorScheme scheme;
  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: HugeIcon(icon: icon, size: 14, color: scheme.primary),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: scheme.onSurface.withValues(alpha: 0.92),
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }
}

/* ----------------------------- Service chip ----------------------------- */

class _ServiceChip extends StatelessWidget {
  final String label;
  final ColorScheme scheme;
  const _ServiceChip({required this.label, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedCheckmarkCircle01,
            size: 12,
            color: scheme.primary,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- Hours grid ----------------------------- */

class _HoursGrid extends StatelessWidget {
  final Map<String, OpeningHours> hours;
  final ColorScheme scheme;
  const _HoursGrid({required this.hours, required this.scheme});

  @override
  Widget build(BuildContext context) {
    const order = [
      "monday",
      "tuesday",
      "wednesday",
      "thursday",
      "friday",
      "saturday",
      "sunday",
    ];
    final weekday = DateTime.now().weekday; // 1=Mon … 7=Sun
    final todayKey = order[weekday - 1];

    return Column(
      children: order.map((day) {
        final isToday = day == todayKey;
        final val = hours[day];
        final label = day[0].toUpperCase() + day.substring(1);
        final isOpen = val != null && val.open.isNotEmpty && val.close.isNotEmpty;
        final timeText = isOpen ? "${val.open} – ${val.close}" : "—";

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isToday
                  ? scheme.primary.withValues(alpha: 0.10)
                  : scheme.surfaceContainerHighest.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isToday
                    ? scheme.primary.withValues(alpha: 0.25)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isToday ? FontWeight.w800 : FontWeight.w600,
                      color: isToday
                          ? scheme.primary
                          : scheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isOpen
                          ? (isToday
                              ? scheme.primary
                              : scheme.onSurface.withValues(alpha: 0.82))
                          : scheme.onSurface.withValues(alpha: 0.38),
                    ),
                  ),
                ),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      "Today",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
