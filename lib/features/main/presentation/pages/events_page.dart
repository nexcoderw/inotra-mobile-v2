import "package:flutter/material.dart";
import "../../../../core/config/app_routes.dart";
import "../widgets/main_scaffold.dart";

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final events = List.generate(8, (i) => "EVENT-${i + 1}");

    return MainScaffold(
      title: "Events",
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final id = events[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.celebration_outlined),
              title: Text("Event $id", style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text("Tap to view details"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.eventDetails,
                arguments: id,
              ),
            ),
          );
        },
      ),
    );
  }
}