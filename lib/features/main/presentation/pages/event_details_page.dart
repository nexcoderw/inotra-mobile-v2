import "package:flutter/material.dart";
import "../widgets/main_scaffold.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class EventDetailsPage extends StatelessWidget {
  final String? eventId;
  const EventDetailsPage({super.key, this.eventId});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    return MainScaffold(
      title: t(lang, "events.details_title"),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "${t(lang, "events.details_title")}\\n\\nEvent ID: ${eventId ?? "N/A"}\\n\\n${t(lang, "common.coming_soon")}",
              style: const TextStyle(height: 1.4),
            ),
          ),
        ),
      ),
    );
  }
}
