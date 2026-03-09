import "package:flutter/material.dart";
import "../../pages/trip_package_details_page.dart";
import "../../../../../../i18n/lang.dart";
import "../../../../../../i18n/translations.dart";
import "package:hugeicons/hugeicons.dart";

class PackageActivitiesTab extends StatelessWidget {
  final List<PackageActivity> activities;
  const PackageActivitiesTab({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    if (activities.isEmpty) {
      return Center(
        child: Text(
          t(lang, "common.coming_soon"),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }

    final grouped = <int, List<PackageActivity>>{};
    for (final a in activities) {
      grouped.putIfAbsent(a.day, () => []).add(a);
    }
    final days = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final list = grouped[day]!;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedCalendar02,
                      size: 16,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${t(lang, "packages.days")} $day",
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...list.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              a.name,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}
