import "package:flutter/material.dart";
import "../../pages/trip_package_details_page.dart";
import "../../../../../../i18n/lang.dart";
import "../../../../../../i18n/translations.dart";

class PackageOverviewTab extends StatelessWidget {
  final PackageDetailData pkg;
  const PackageOverviewTab({super.key, required this.pkg});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(lang, "listings.overview_title"),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Text(
            pkg.description,
            style: TextStyle(
              height: 1.5,
              color: scheme.onSurface.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceVariant.withOpacity(0.45),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month, color: scheme.primary),
                const SizedBox(width: 10),
                Text(
                  "${pkg.durationDays} ${t(lang, "packages.days")}",
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
