import "package:flutter/material.dart";
import "../widgets/main_scaffold.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class TripPackageDetailsPage extends StatelessWidget {
  final String? packageId;
  const TripPackageDetailsPage({super.key, this.packageId});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return MainScaffold(
      title: t(lang, "trips.details_title"),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t(lang, "trips.details_title"),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: scheme.onSurface.withOpacity(0.92),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t(lang, "common.coming_soon"),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withOpacity(0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
