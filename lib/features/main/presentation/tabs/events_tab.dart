import "package:flutter/material.dart";
import "../../../../core/config/app_routes.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class EventsTab extends StatelessWidget {
  const EventsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final events = List.generate(8, (i) => "EVENT-${i + 1}");
    final lang = currentLangSync();

    return SafeArea(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        itemCount: events.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Text(
              t(lang, "nav.events"),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            );
          }
          final id = events[index - 1];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.celebration_outlined),
              title: Text("${t(lang, "nav.events")} $id",
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(t(lang, "common.tap_details")),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, AppRoutes.eventDetails, arguments: id),
            ),
          );
        },
      ),
    );
  }
}
