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
    return MainScaffold(
      title: t(lang, "trips.details_title"),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "${t(lang, "trips.details_title")}\\n\\nPackage ID: ${packageId ?? "N/A"}\\n\\n${t(lang, "common.coming_soon")}",
              style: const TextStyle(height: 1.4),
            ),
          ),
        ),
      ),
    );
  }
}
