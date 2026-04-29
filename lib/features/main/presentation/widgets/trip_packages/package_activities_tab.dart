import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../../../i18n/lang.dart";
import "../../../../../../i18n/translations.dart";
import "package_models.dart";

class PackageActivitiesTab extends StatelessWidget {
  final List<PackageDay> days;
  final List<PackageActivity> fallbackActivities;

  const PackageActivitiesTab({
    super.key,
    required this.days,
    required this.fallbackActivities,
  });

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    if (days.isEmpty && fallbackActivities.isEmpty) {
      return _EmptyState(
        icon: HugeIcons.strokeRoundedCalendar02,
        message: t(lang, "listings.no_data"),
        scheme: scheme,
      );
    }

    if (days.isEmpty) {
      return _LegacyActivitiesTimeline(
        activities: fallbackActivities,
        lang: lang,
        scheme: scheme,
      );
    }

    final sortedDays = [...days]
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        for (final day in sortedDays) ...[
          _DayCard(day: day, lang: lang, scheme: scheme),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  final PackageDay day;
  final String lang;
  final ColorScheme scheme;

  const _DayCard({required this.day, required this.lang, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
            border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      "${t(lang, "trips.day_label")} ${day.dayNumber}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                  if (day.title.trim().isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        day.title.trim(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface.withValues(alpha: 0.88),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (day.summary.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  day.summary.trim(),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface.withValues(alpha: 0.78),
                  ),
                ),
              ],
              if (day.overnightLocation.trim().isNotEmpty ||
                  day.mealsIncluded.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (day.overnightLocation.trim().isNotEmpty)
                      _MetaTag(
                        icon: HugeIcons.strokeRoundedBed,
                        label: "Overnight: ${day.overnightLocation.trim()}",
                        scheme: scheme,
                      ),
                    if (day.mealsIncluded.trim().isNotEmpty)
                      _MetaTag(
                        icon: HugeIcons.strokeRoundedRestaurant01,
                        label: day.mealsIncluded.trim(),
                        scheme: scheme,
                      ),
                  ],
                ),
              ],
              if (day.stops.isNotEmpty) ...[
                const SizedBox(height: 14),
                for (int i = 0; i < day.stops.length; i++) ...[
                  _StopCard(stop: day.stops[i], scheme: scheme),
                  if (i < day.stops.length - 1) const SizedBox(height: 10),
                ],
              ],
              if (day.notes.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _NotesBlock(value: day.notes.trim(), scheme: scheme),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StopCard extends StatelessWidget {
  final PackageStop stop;
  final ColorScheme scheme;

  const _StopCard({required this.stop, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final title = stop.title.trim().isNotEmpty
        ? stop.title.trim()
        : stop.placeName.trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surface.withValues(alpha: 0.7),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface.withValues(alpha: 0.9),
              ),
            ),
          if (stop.description.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              stop.description.trim(),
              style: TextStyle(
                fontSize: 12,
                height: 1.55,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface.withValues(alpha: 0.76),
              ),
            ),
          ],
          if (stop.transportMode.trim().isNotEmpty ||
              stop.durationLabel.trim().isNotEmpty ||
              stop.distanceLabel.trim().isNotEmpty ||
              stop.arrivalTime.trim().isNotEmpty ||
              stop.departureTime.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (stop.transportMode.trim().isNotEmpty)
                  _MetaTag(
                    icon: HugeIcons.strokeRoundedCar01,
                    label: stop.transportMode.trim(),
                    scheme: scheme,
                  ),
                if (stop.durationLabel.trim().isNotEmpty)
                  _MetaTag(
                    icon: HugeIcons.strokeRoundedClock01,
                    label: stop.durationLabel.trim(),
                    scheme: scheme,
                  ),
                if (stop.distanceLabel.trim().isNotEmpty)
                  _MetaTag(
                    icon: HugeIcons.strokeRoundedRoute03,
                    label: stop.distanceLabel.trim(),
                    scheme: scheme,
                  ),
                if (stop.arrivalTime.trim().isNotEmpty)
                  _MetaTag(
                    icon: HugeIcons.strokeRoundedTimeQuarterPass,
                    label: "Arrive ${stop.arrivalTime.trim()}",
                    scheme: scheme,
                  ),
                if (stop.departureTime.trim().isNotEmpty)
                  _MetaTag(
                    icon: HugeIcons.strokeRoundedTimeQuarterPass,
                    label: "Depart ${stop.departureTime.trim()}",
                    scheme: scheme,
                  ),
              ],
            ),
          ],
          if (stop.activities.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (int i = 0; i < stop.activities.length; i++) ...[
              _ActivityTile(activity: stop.activities[i], scheme: scheme),
              if (i < stop.activities.length - 1) const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final PackageActivity activity;
  final ColorScheme scheme;

  const _ActivityTile({required this.activity, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: scheme.primary.withValues(alpha: 0.06),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                size: 15,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  activity.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface.withValues(alpha: 0.9),
                  ),
                ),
              ),
              if (activity.isOptional)
                Text(
                  "Optional",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
            ],
          ),
          if (activity.description.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              activity.description.trim(),
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface.withValues(alpha: 0.74),
              ),
            ),
          ],
          if (activity.whatToExpect.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              activity.whatToExpect.trim(),
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface.withValues(alpha: 0.68),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaTag extends StatelessWidget {
  final dynamic icon;
  final String label;
  final ColorScheme scheme;

  const _MetaTag({
    required this.icon,
    required this.label,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: 13, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesBlock extends StatelessWidget {
  final String value;
  final ColorScheme scheme;

  const _NotesBlock({required this.value, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 12,
          height: 1.5,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface.withValues(alpha: 0.76),
        ),
      ),
    );
  }
}

class _LegacyActivitiesTimeline extends StatelessWidget {
  final List<PackageActivity> activities;
  final String lang;
  final ColorScheme scheme;

  const _LegacyActivitiesTimeline({
    required this.activities,
    required this.lang,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final Map<int, List<PackageActivity>> grouped = {};
    for (final activity in activities) {
      grouped.putIfAbsent(activity.day, () => []).add(activity);
    }
    final orderedDays = grouped.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        for (final day in orderedDays) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  "${t(lang, "trips.day_label")} $day",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: scheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Divider(color: scheme.onSurface.withValues(alpha: 0.12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final activity in grouped[day]!) ...[
            _ActivityTile(activity: activity, scheme: scheme),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final dynamic icon;
  final String message;
  final ColorScheme scheme;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: icon,
            size: 34,
            color: scheme.onSurface.withValues(alpha: 0.30),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.50),
            ),
          ),
        ],
      ),
    );
  }
}
