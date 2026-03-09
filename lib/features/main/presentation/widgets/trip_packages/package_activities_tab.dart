import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../../../i18n/lang.dart";
import "../../../../../../i18n/translations.dart";
import "package_models.dart";

class PackageActivitiesTab extends StatelessWidget {
  final List<PackageActivity> activities;

  const PackageActivitiesTab({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    if (activities.isEmpty) {
      return _EmptyState(
        icon: HugeIcons.strokeRoundedCalendar02,
        message: t(lang, "listings.no_data"),
        scheme: scheme,
      );
    }

    final Map<int, List<PackageActivity>> grouped = {};
    for (final a in activities) {
      grouped.putIfAbsent(a.day, () => []).add(a);
    }
    final days = grouped.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        for (final day in days) ...[
          _DayHeader(day: day, lang: lang, scheme: scheme),
          const SizedBox(height: 8),
          for (int i = 0; i < grouped[day]!.length; i++)
            _TimelineActivityTile(
              activity: grouped[day]![i],
              isLast: i == grouped[day]!.length - 1 && day == days.last,
              scheme: scheme,
            ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  final int day;
  final String lang;
  final ColorScheme scheme;

  const _DayHeader({
    required this.day,
    required this.lang,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          child: Divider(
            color: scheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}

class _TimelineActivityTile extends StatelessWidget {
  final PackageActivity activity;
  final bool isLast;
  final ColorScheme scheme;

  const _TimelineActivityTile({
    required this.activity,
    required this.isLast,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 14),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.35),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            scheme.primary.withValues(alpha: 0.45),
                            scheme.primary.withValues(alpha: 0.10),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: scheme.surfaceContainerHighest
                          .withValues(alpha: 0.22),
                      border: Border.all(
                        color: scheme.onSurface.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                          size: 15,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            activity.title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface.withValues(alpha: 0.90),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
