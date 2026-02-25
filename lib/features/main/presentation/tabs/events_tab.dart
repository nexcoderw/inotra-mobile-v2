import "package:flutter/material.dart";
import "../../../../core/config/app_routes.dart";

class EventsTab extends StatelessWidget {
  const EventsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final events = List.generate(8, (i) => "EVENT-${i + 1}");

    return SafeArea(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        itemCount: events.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const Text(
              "Events",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            );
          }
          final id = events[index - 1];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.celebration_outlined),
              title: Text("Event $id", style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text("Tap to view details"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, AppRoutes.eventDetails, arguments: id),
            ),
          );
        },
      ),
    );
  }
}