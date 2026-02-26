import "package:flutter/material.dart";
import "../widgets/main_scaffold.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class ListingDetailsPage extends StatelessWidget {
  final String? placeId;
  const ListingDetailsPage({super.key, this.placeId});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    return MainScaffold(
      title: t(lang, "listings.details_title"),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "${t(lang, "listings.details_title")}\\n\\nPlace ID: ${placeId ?? "N/A"}\\n\\n${t(lang, "common.coming_soon")}",
              style: const TextStyle(height: 1.4),
            ),
          ),
        ),
      ),
    );
  }
}
