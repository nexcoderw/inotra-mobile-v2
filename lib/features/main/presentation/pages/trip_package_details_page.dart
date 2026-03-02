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
    final idLabel = packageId != null
        ? t(lang, "trips.id_label").replaceFirst("{id}", packageId!)
        : t(lang, "trips.id_placeholder");

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
              t(lang, "trips.details_message"),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withOpacity(0.72),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.primary.withOpacity(0.18)),
              ),
              child: Text(
                idLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
